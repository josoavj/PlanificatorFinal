import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/utils/excel_utils.dart';

void main() {
  group('ExcelService - Path Logic', () {
    test('initDesktopStructure crée les dossiers nécessaires', () {
      final paths = FolderManager.initDesktopStructure();
      expect(paths.length, equals(2));
      expect(paths[0].path, contains('Factures'));
      expect(paths[1].path, contains('Traitements'));
    });
  });
}

  group('ExcelService - Data Formatting', () {
    // Test de la logique interne (méthodes privées non testables directement sans modification)
    // On peut tester le comportement via les méthodes publiques si on mock l'écriture fichier
  });
}
