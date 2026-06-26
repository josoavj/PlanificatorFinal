import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/config/database_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseConfig - Unit Tests', () {
    late DatabaseConfig config;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      config = DatabaseConfig();
    });

    test('DatabaseConfig singleton - retourne la même instance', () {
      final config1 = DatabaseConfig();
      final config2 = DatabaseConfig();
      expect(identical(config1, config2), true);
    });

    test('Getter database par défaut', () {
      expect(config.database, 'Planificator');
    });

    test('getConnectionInfo() - Structure initiale', () {
      final info = config.getConnectionInfo();
      expect(info.containsKey('db'), true);
      // Avant initialisation, les champs peuvent être null sauf la valeur par défaut de db
    });
  });
}
