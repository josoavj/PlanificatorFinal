import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/logging_service.dart';

/// Configuration singleton pour la base de données
/// Stocke les credentials de connexion MySQL
///
/// SÉCURITÉ:
/// - Non-sensibles (host, port, database) → SharedPreferences
/// - Sensibles (user, password) → flutter_secure_storage (chiffré DPAPI/Keychain/Keystore)
class DatabaseConfig {
  static final DatabaseConfig _instance = DatabaseConfig._internal();
  final logger = createLoggerWithFileOutput(name: 'database_config');

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );
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

  /// Initialiser la configuration depuis SharedPreferences et flutter_secure_storage
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      _host = _prefs.getString('db_host') ?? 'localhost';
      _port = _prefs.getInt('db_port') ?? 3306;
      _database = _prefs.getString('db_name') ?? 'Planificator';

      // Récupérer les credentials du stockage sécurisé
      _user = await _secureStorage.read(key: 'db_user');
      _password = await _secureStorage.read(key: 'db_password');

      _initialized = true;
      logger.i(
        'Configuration database initialized (credentials from secure storage)',
      );
    } catch (e) {
      logger.e('Error during initialization: $e');
      throw Exception('Unable to initialize configuration');
    }
  }

  /// Vérifie si la configuration est complète
  bool get isConfigured {
    return _host != null && _port != null && _user != null && _password != null;
  }

  /// Sauvegarde la configuration
  ///
  ///   SÉCURITÉ:
  /// - Les NON-SENSIBLES (host, port, database) → SharedPreferences
  /// - Les CREDENTIALS SENSIBLES (user, password) → FlutterSecureStorage (chiffré)
  Future<void> saveConfig({
    required String host,
    required int port,
    required String user,
    required String password,
    String? database,
  }) async {
    try {
      // 1. Store non-sensitive data
      await _prefs.setString('db_host', host);
      await _prefs.setInt('db_port', port);
      if (database != null) {
        await _prefs.setString('db_name', database);
      }

      // 2. Store credentials (should use flutter_secure_storage in production)
      await _secureStorage.write(key: 'db_user', value: user);
      await _secureStorage.write(key: 'db_password', value: password);

      _host = host;
      _port = port;
      _user = user;
      _password = password;
      _database = database ?? 'Planificator';

      logger.i('Configuration saved (credentials encrypted in secure storage)');
    } catch (e) {
      logger.e('Error saving config: $e');
      throw Exception('Unable to save configuration');
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
      // 1. Remove non-sensitive data
      await _prefs.remove('db_host');
      await _prefs.remove('db_port');
      await _prefs.remove('db_name');

      // 2. Remove credentials from secure storage
      await _secureStorage.delete(key: 'db_user');
      await _secureStorage.delete(key: 'db_password');

      _host = null;
      _port = null;
      _user = null;
      _password = null;
      _database = null;

      logger.i('Configuration reset');
    } catch (e) {
      logger.e('Error during reset: $e');
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
