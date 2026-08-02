import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/utils/excel_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExcelService - Path Logic', () {
    test('initDesktopStructure crée les dossiers nécessaires', () async {
      final paths = await FolderManager.initDesktopStructure();
      // Factures, Traitements, Exports
      expect(paths.length, equals(3));
      expect(paths[0].path, contains('Factures'));
      expect(paths[1].path, contains('Traitements'));
      expect(paths[2].path, contains('Exports'));
    });
  });

  group('ExcelService - Data Formatting', () {
    test('getSafeName nettoie correctement les noms de fichiers', () {
      expect(ExcelService.getSafeName('Jean-Pierre'), equals('Jean-Pierre'));
      expect(ExcelService.getSafeName('ACME Corp.'), equals('ACME_Corp'));
      expect(ExcelService.getSafeName('Client/Test!'), equals('ClientTest'));
      expect(ExcelService.getSafeName('  Espaces  '), equals('Espaces'));
    });
  });
}
