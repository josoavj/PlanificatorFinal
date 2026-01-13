import 'dart:async';
import 'package:mysql1/mysql1.dart';
import './logging_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static final logger = createLoggerWithFileOutput(name: 'database_service');

  late MySqlConnection _connection;
  bool _isConnected = false;

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
    _user = 'sudoted';
    _password = '100805Josh';
    _database = 'Planificator';
  }

  factory DatabaseService() {
    return _instance;
  }

  bool get isConnected => _isConnected;

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

  /// Établit la connexion à la base de données
  Future<bool> connect() async {
    if (_isConnected) {
      logger.i('Déjà connecté à la base de données');
      return true;
    }

    try {
      logger.i('Connexion à MySQL://$_host:$_port/$_database');

      _connection = await MySqlConnection.connect(
        ConnectionSettings(
          host: _host,
          port: _port,
          user: _user,
          password: _password,
          db: _database,
        ),
      );

      _isConnected = true;
      logger.i('✅ Connexion établie avec succès');
      return true;
    } catch (e) {
      logger.e('❌ Erreur de connexion: $e');
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

  /// Exécute une requête SELECT et retourne les résultats
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? params,
  ]) async {
    if (!_isConnected) {
      throw Exception('Pas de connexion à la base de données');
    }

    try {
      logger.d('Query: $sql');
      if (params != null) {
        logger.d('Params: $params');
      }

      Results results = await _connection
          .query(sql, params)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e('⏱️ Timeout de requête après 30 secondes');
              throw TimeoutException('La requête a dépassé le délai imparti');
            },
          );

      List<Map<String, dynamic>> rows = [];
      for (var row in results) {
        Map<String, dynamic> map = {};
        for (var i = 0; i < row.length; i++) {
          // Récupérer le nom de la colonne et la valeur
          final fieldName = results.fields[i].name ?? 'field_$i';
          map[fieldName] = row[i];
        }
        rows.add(map);
      }

      logger.i('Query réussie: ${rows.length} lignes retournées');
      return rows;
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
      if (params != null) {
        logger.d('Params: $params');
      }

      await _connection.query(sql, params);
      logger.i('Execution réussie');
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
      if (params != null) {
        logger.d('Params: $params');
      }

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
