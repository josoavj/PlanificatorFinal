import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'package:mysql1/mysql1.dart';
import './logging_service.dart';
import './database_isolate_service.dart';
import './query_cache_service.dart';
import '../utils/windows_profiler.dart';

/// Simple connection pool pour réutiliser les connexions MySQL
class MySQLConnectionPool {
  final int maxConnections;
  final Queue<MySqlConnection> _availableConnections = Queue();
  final List<MySqlConnection> _allConnections = [];
  final ConnectionSettings _settings;
  int _activeConnections = 0;

  MySQLConnectionPool({
    required ConnectionSettings settings,
    this.maxConnections = 5,
  }) : _settings = settings;

  /// Obtenir une connexion du pool
  /// SÉCURITÉ: Timeout si pas de connexion disponible après 30s
  Future<MySqlConnection> getConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final startTime = DateTime.now();

    while (true) {
      // Chercher une connexion disponible
      if (_availableConnections.isNotEmpty) {
        return _availableConnections.removeFirst();
      }

      // Créer une nouvelle connexion si possible
      if (_activeConnections < maxConnections) {
        _activeConnections++;
        final conn = await MySqlConnection.connect(_settings);
        _allConnections.add(conn);
        return conn;
      }

      // Vérifier le timeout
      if (DateTime.now().difference(startTime) > timeout) {
        throw TimeoutException(
          'Aucune connexion disponible après ${timeout.inSeconds}s '
          '(Pool: ${_allConnections.length}/$maxConnections, '
          'Disponible: ${_availableConnections.length})',
        );
      }

      // Attendre avant de réessayer
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Retourner une connexion au pool
  void releaseConnection(MySqlConnection connection) {
    if (_allConnections.contains(connection)) {
      _availableConnections.addLast(connection);
    }
  }

  /// Fermer toutes les connexions
  Future<void> closeAll() async {
    for (final conn in _allConnections) {
      try {
        await conn.close();
      } catch (e) {
        // Ignorer les erreurs de fermeture
      }
    }
    _allConnections.clear();
    _availableConnections.clear();
    _activeConnections = 0;
  }

  int get poolSize => _allConnections.length;
  int get availableCount => _availableConnections.length;
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static final logger = createLoggerWithFileOutput(name: 'database_service');

  late MySqlConnection _connection;
  MySQLConnectionPool? _pool;
  bool _isConnected = false;
  bool _useIsolates = true;
  final bool _useConnectionPool = true;

  // Configuration de la base de données (configurable)
  late String _host;
  late int _port;
  late String _user;
  late String _password;
  late String _database;

  DatabaseService._internal() {
    /// SÉCURITÉ: Pas de credentials par défaut
    /// Les valeurs sont null jusqu'à ce que l'utilisateur les configure
    /// Cela évite les failles de sécurité dues aux identifiants par défaut
    _host = 'localhost'; // Valeur par défaut sûre (pas d'accès réseau)
    _port = 3306;
    _user = ''; // Pas d'identifiant par défaut
    _password = ''; // Pas de mot de passe par défaut
    _database = 'Planificator';
  }

  factory DatabaseService() {
    return _instance;
  }

  bool get isConnected => _isConnected;

  ///  Masque les données sensibles dans les logs
  /// Remplace les valeurs par des placeholders pour éviter d'exposer des secrets
  static String _sanitizeParamsForLogging(List<dynamic>? params) {
    if (params == null) return 'null';

    try {
      final sanitized = params.map((param) {
        // Si c'est un String long (possiblement un hash), le masquer
        if (param is String && param.length > 20) {
          return '[MASKED:$param.length chars]';
        }
        // Masquer les valeurs ressemblant à des hash bcrypt (60 chars)
        if (param is String && param.startsWith('\$2')) {
          return '[BCRYPT_HASH_MASKED]';
        }
        return param;
      }).toList();
      return sanitized.toString();
    } catch (e) {
      return '[ERROR_SANITIZING_PARAMS]';
    }
  }

  /// Active/désactive l'utilisation des isolates
  void setUseIsolates(bool useIsolates) {
    _useIsolates = useIsolates;
    logger.i('Isolates ${useIsolates ? 'activés' : 'désactivés'}');
  }

  /// Mettre à jour les paramètres de connexion
  void updateConnectionSettings({
    required String host,
    required int port,
    required String user,
    required String password,
    required String database,
  }) {
    _host = host;
    _port = port;
    _user = user;
    _password = password;
    _database = database;
  }

  /// Détecte si la DB est locale ou distante
  bool _isLocalDatabase() {
    return _host == 'localhost' ||
        _host == '127.0.0.1' ||
        _host.startsWith('192.168.') ||
        _host.startsWith('10.');
  }

  /// Obtient le nombre optimal de connexions selon la localisation
  int _getOptimalPoolSize() {
    if (_isLocalDatabase()) {
      logger.i('DB locale détectée → Pool: 5 connexions');
      return 5;
    } else {
      logger.i('DB distante détectée ($_host) → Pool: 10 connexions');
      return 10;
    }
  }

  /// Établit la connexion à la base de données
  Future<bool> connect() async {
    if (_isConnected) {
      logger.i('Déjà connecté à la base de données');
      return true;
    }

    try {
      logger.i('Connexion à MySQL://$_host:$_port/$_database');
      final isLocal = _isLocalDatabase();
      logger.i('Type DB: ${isLocal ? 'LOCAL' : 'DISTANTE'}');

      final settings = ConnectionSettings(
        host: _host,
        port: _port,
        user: _user,
        password: _password,
        db: _database,
      );

      if (_useConnectionPool) {
        final poolSize = _getOptimalPoolSize();
        logger.i(
          'Initialisation du pool de connexions ($poolSize connexions max)',
        );
        _pool = MySQLConnectionPool(
          settings: settings,
          maxConnections: poolSize,
        );
      }

      _connection = await MySqlConnection.connect(settings);

      _isConnected = true;
      logger.i('Connexion établie avec succès');
      return true;
    } catch (e) {
      logger.e('Erreur de connexion: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Ferme la connexion à la base de données et le pool entièrement
  /// SÉCURITÉ: Fermer correctement toutes les ressources
  Future<void> close() async {
    if (_isConnected) {
      try {
        // Fermer le pool d'abord
        if (_pool != null) {
          await _pool!.closeAll();
          _pool = null;
          logger.i('Pool de connexions fermé');
        }

        // Puis fermer la connexion principale
        await _connection.close();
        _isConnected = false;
        logger.i('Connexion fermée');
      } catch (e) {
        logger.e('Erreur lors de la fermeture: $e');
      }
    }
  }

  /// Obtient une connexion pour exécuter une requête
  Future<MySqlConnection> _getQueryConnection() async {
    if (_useConnectionPool && _pool != null) {
      logger.d('Obtenir connexion du pool');
      return _pool!.getConnection();
    }
    return _connection;
  }

  /// Retourne une connexion au pool après utilisation
  void _releaseQueryConnection(MySqlConnection conn) {
    if (_useConnectionPool && _pool != null) {
      logger.d('Retourner connexion au pool');
      _pool!.releaseConnection(conn);
    }
  }

  /// Exécute une requête SQL SELECT avec support du Cache
  Future<List<Map<String, dynamic>>> query(String sql, [List? params, bool useCache = true]) async {
    if (!_isConnected) {
      throw Exception('Pas de connexion à la base de données');
    }

    // 1. Tenter de récupérer depuis le cache
    final cache = QueryCacheService();
    if (useCache) {
      final cachedData = cache.getQuery(sql, params);
      if (cachedData != null) return cachedData;
    }

    try {
      logger.d('Query: $sql');
      
      List<Map<String, dynamic>> rows = [];

      // PERFORMANCE: Mesurer le temps sur Desktop
      final profilerName = 'SQL Query: ${sql.substring(0, math.min(20, sql.length))}';
      final metric = Platform.isWindows ? WindowsProfiler.start(profilerName) : null;

      try {
        // 2. Décider si on utilise un Isolate ou la connexion directe
        // PERFORMANCE: L'Isolate est coûteux (ouverture d'une nouvelle connexion MySQL).
        // On ne l'utilise que pour les grosses requêtes SELECT (> 100 caractères ou mots clés de listes).
        // Les petites requêtes sont plus rapides en direct via le pool de connexions.
        bool isLikelyHeavy = sql.length > 100 || 
                           sql.toLowerCase().contains('join') || 
                           sql.toLowerCase().contains('detailed');
        
        bool shouldShowIsolate = _useIsolates && 
                                !sql.toLowerCase().contains('limit 1') && 
                                isLikelyHeavy;

        if (shouldShowIsolate) {
          rows = await DatabaseIsolateService.executeQuery(
            sql, params, _host, _port, _user, _password, _database,
          );
        } else {
          MySqlConnection? conn;
          try {
            conn = await _getQueryConnection();
            Results results = await conn.query(sql, params).timeout(const Duration(seconds: 30));

            for (var row in results) {
              Map<String, dynamic> map = {};
              for (int i = 0; i < results.fields.length; i++) {
                map[results.fields[i].name ?? 'field_$i'] = row[i];
              }
              rows.add(map);
            }
          } finally {
            if (conn != null) _releaseQueryConnection(conn);
          }
        }
      } finally {
        metric?.end();
      }

      // 3. Mettre en cache pour la prochaine fois
      if (useCache && rows.isNotEmpty) {
        cache.setQuery(sql, params, rows);
      }

      return rows;
    } catch (e) {
      logger.e('Erreur lors de la query: $e');
      rethrow;
    }
  }

  /// Exécute une requête INSERT/UPDATE/DELETE et invalide le cache
  Future<void> execute(String sql, [List<dynamic>? params]) async {
    if (!_isConnected) throw Exception('Pas de connexion à la base de données');

    try {
      // Invalider le cache car les données vont changer
      QueryCacheService().invalidateAll();

      if (_useIsolates) {
        await DatabaseIsolateService.executeUpdate(sql, params, _host, _port, _user, _password, _database);
      } else {
        MySqlConnection? conn;
        try {
          conn = await _getQueryConnection();
          await conn.query(sql, params);
        } finally {
          if (conn != null) _releaseQueryConnection(conn);
        }
      }
    } catch (e) {
      logger.e('Erreur lors de l\'exécution: $e');
      rethrow;
    }
  }

  /// Exécute une requête et retourne l'ID généré (pour INSERT)
  Future<int> insert(String sql, [List<dynamic>? params]) async {
    if (!_isConnected) {
      throw Exception('Pas de connexion à la base de données');
    }

    try {
      logger.d('Insert: $sql');
      if (params != null && params.isNotEmpty) {
        //  Logs sécurisés: masquer les données sensibles
        logger.d('Params: ${_sanitizeParamsForLogging(params)}');
      }

      // Utiliser les isolates si activés
      if (_useIsolates) {
        final id = await DatabaseIsolateService.executeInsert(
          sql,
          params,
          _host,
          _port,
          _user,
          _password,
          _database,
        );
        logger.i('Insert réussi via isolate');
        return id;
      }

      // Sinon, utiliser la connexion existante
      Results result = await _connection.query(sql, params);
      logger.i('Insert réussi');
      return result.insertId ?? 0;
    } catch (e) {
      logger.e('Erreur lors de l\'insertion: $e');
      rethrow;
    }
  }

  /// Récupère une seule ligne
  Future<Map<String, dynamic>?> queryOne(
    String sql, {
    List<dynamic>? params,
    bool useCache = true,
  }) async {
    List<Map<String, dynamic>> results = await query(sql, params, useCache);
    return results.isNotEmpty ? results.first : null;
  }

  /// Récupère une valeur unique
  Future<dynamic> queryValue(String sql, {List<dynamic>? params}) async {
    var result = await queryOne(sql, params: params);
    return result?.values.first;
  }

  /// Exécute un ensemble d'opérations dans une transaction SQL unique.
  /// SÉCURITÉ: En cas d'erreur, un ROLLBACK automatique est effectué.
  /// IMPORTANT: Les transactions n'utilisent PAS les isolates pour garantir la cohérence.
  Future<T> transaction<T>(Future<T> Function(MySqlConnection conn) action) async {
    if (!_isConnected) await connect();

    MySqlConnection? conn;
    try {
      conn = await _getQueryConnection();
      final result = await conn.transaction((ctx) async {
        return await action(conn!);
      });
      return result as T;
    } catch (e) {
      logger.e('Erreur dans la transaction SQL: $e');
      rethrow;
    } finally {
      if (conn != null) _releaseQueryConnection(conn);
    }
  }

  /// Teste la connexion
  Future<bool> testConnection() async {
    try {
      var result = await queryValue('SELECT 1');
      return result != null;
    } catch (e) {
      logger.e('Test de connexion échoué: $e');
      return false;
    }
  }
}
