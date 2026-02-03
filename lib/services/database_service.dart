import 'dart:async';
import 'dart:collection';
import 'package:mysql1/mysql1.dart';
import './logging_service.dart';
import './database_isolate_service.dart';

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
  Future<MySqlConnection> getConnection() async {
    if (_availableConnections.isNotEmpty) {
      return _availableConnections.removeFirst();
    }

    if (_activeConnections < maxConnections) {
      _activeConnections++;
      final conn = await MySqlConnection.connect(_settings);
      _allConnections.add(conn);
      return conn;
    }

    // Attendre qu'une connexion soit disponible
    return Future.delayed(Duration(milliseconds: 100), () => getConnection());
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
    // Valeurs par défaut
    _host = 'localhost';
    _port = 3306;
    _user = 'root';
    _password = 'root';
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
          return '[MASKED:${param.length}chars]';
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

  /// Ferme la connexion à la base de données
  Future<void> close() async {
    if (_isConnected) {
      try {
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

  /// Exécute une requête SQL SELECT
  Future<List<Map<String, dynamic>>> query(String sql, [List? params]) async {
    if (!_isConnected) {
      throw Exception('Pas de connexion à la base de données');
    }

    try {
      logger.d('Query: $sql');
      if (params != null && params.isNotEmpty) {
        logger.d('Params: ${_sanitizeParamsForLogging(params)}');
      }

      // Utiliser les isolates si activés (recommandé pour Windows)
      if (_useIsolates) {
        final rows = await DatabaseIsolateService.executeQuery(
          sql,
          params,
          _host,
          _port,
          _user,
          _password,
          _database,
        );
        logger.i('Query réussie via isolate: ${rows.length} lignes retournées');
        return rows;
      }

      // Utiliser le pool de connexions si disponible
      MySqlConnection? conn;
      try {
        conn = await _getQueryConnection();

        // Adapter timeout selon type de DB
        final timeoutDuration = _isLocalDatabase()
            ? const Duration(seconds: 30)
            : const Duration(seconds: 60);

        Results results = await conn
            .query(sql, params)
            .timeout(
              timeoutDuration,
              onTimeout: () {
                logger.e(
                  'Timeout de requête après ${timeoutDuration.inSeconds}s',
                );
                throw TimeoutException('La requête a dépassé le délai imparti');
              },
            );

        List<Map<String, dynamic>> rows = [];
        for (var row in results) {
          Map<String, dynamic> map = {};
          for (int i = 0; i < results.fields.length; i++) {
            final fieldName = results.fields[i].name ?? 'field_$i';
            map[fieldName] = row[i];
          }
          rows.add(map);
        }

        logger.i('Query réussie: ${rows.length} lignes retournées');
        return rows;
      } finally {
        if (conn != null) {
          _releaseQueryConnection(conn);
        }
      }
    } catch (e) {
      logger.e('Erreur lors de la query: $e');
      rethrow;
    }
  }

  /// Exécute une requête INSERT/UPDATE/DELETE
  Future<void> execute(String sql, [List<dynamic>? params]) async {
    if (!_isConnected) {
      throw Exception('Pas de connexion à la base de données');
    }

    try {
      logger.d('Execute: $sql');
      if (params != null && params.isNotEmpty) {
        logger.d('Params: ${_sanitizeParamsForLogging(params)}');
      }

      // Utiliser les isolates si activés
      if (_useIsolates) {
        await DatabaseIsolateService.executeUpdate(
          sql,
          params,
          _host,
          _port,
          _user,
          _password,
          _database,
        );
        logger.i('Execution réussie via isolate');
        return;
      }

      // Utiliser le pool de connexions si disponible
      MySqlConnection? conn;
      try {
        conn = await _getQueryConnection();
        await conn.query(sql, params);
        logger.i('Execution réussie');
      } finally {
        if (conn != null) {
          _releaseQueryConnection(conn);
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
    String sql, [
    List<dynamic>? params,
  ]) async {
    List<Map<String, dynamic>> results = await query(sql, params);
    return results.isNotEmpty ? results.first : null;
  }

  /// Récupère une valeur unique
  Future<dynamic> queryValue(String sql, [List<dynamic>? params]) async {
    var result = await queryOne(sql, params);
    return result?.values.first;
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
