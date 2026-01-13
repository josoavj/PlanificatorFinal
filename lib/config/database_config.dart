import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';

/// Configuration singleton pour la base de données
/// Stocke les credentials de connexion MySQL
class DatabaseConfig {
  static final DatabaseConfig _instance = DatabaseConfig._internal();
  final logger = createLoggerWithFileOutput(name: 'database_config');

  late SharedPreferences _prefs;
  bool _initialized = false;

  String? _host;
  int? _port;
  String? _user;
  String? _password;
  String? _database;

  DatabaseConfig._internal();

  factory DatabaseConfig() {
    return _instance;
  }

  /// Initialiser la configuration depuis SharedPreferences
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      _host = _prefs.getString('db_host') ?? 'localhost';
      _port = _prefs.getInt('db_port') ?? 3306;
      _user = _prefs.getString('db_user');
      _password = _prefs.getString('db_password');
      _database = _prefs.getString('db_name') ?? 'Planificator';

      _initialized = true;
      logger.i('✅ Configuration base de données initialisée');
    } catch (e) {
      logger.e('❌ Erreur lors de l\'initialisation: $e');
      throw Exception('Impossible d\'initialiser la configuration');
    }
  }

  /// Vérifie si la configuration est complète
  bool get isConfigured {
    return _host != null && _port != null && _user != null && _password != null;
  }

  /// Sauvegarde la configuration
  Future<void> saveConfig({
    required String host,
    required int port,
    required String user,
    required String password,
    String? database,
  }) async {
    try {
      await _prefs.setString('db_host', host);
      await _prefs.setInt('db_port', port);
      await _prefs.setString('db_user', user);
      await _prefs.setString('db_password', password);
      if (database != null) {
        await _prefs.setString('db_name', database);
      }

      _host = host;
      _port = port;
      _user = user;
      _password = password;
      _database = database ?? 'Planificator';

      logger.i('✅ Configuration sauvegardée');
    } catch (e) {
      logger.e('❌ Erreur lors de la sauvegarde: $e');
      throw Exception('Impossible de sauvegarder la configuration');
    }
  }

  // Getters
  String? get host => _host;
  int? get port => _port;
  String? get user => _user;
  String? get password => _password;
  String? get database => _database ?? 'Planificator';
  bool get initialized => _initialized;

  /// Réinitialise la configuration (pour tests)
  Future<void> reset() async {
    try {
      await _prefs.remove('db_host');
      await _prefs.remove('db_port');
      await _prefs.remove('db_user');
      await _prefs.remove('db_password');
      await _prefs.remove('db_name');

      _host = null;
      _port = null;
      _user = null;
      _password = null;
      _database = null;

      logger.i('✅ Configuration réinitialisée');
    } catch (e) {
      logger.e('❌ Erreur lors de la réinitialisation: $e');
    }
  }

  /// Obtient les informations de connexion sous forme de map
  Map<String, dynamic> getConnectionInfo() {
    return {
      'host': _host,
      'port': _port,
      'user': _user,
      'password': _password,
      'db': _database,
    };
  }
}
