import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planificator/repositories/facture_repository.dart';
import '../config/mocks.dart';

void main() {
  late FactureRepository repository;
  late MockDatabaseService mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseService();
    repository = FactureRepository(databaseService: mockDatabase);
  });

  group('FactureRepository - Mise à jour massive (Cascade)', () {
    test('majMontantEtHistorique doit exécuter la transaction SQL de masse', () async {
      final factureId = 1;
      const oldPrix = 50000;
      const newPrix = 60000;
      final dateRef = DateTime(2024, 1, 1);

      when(mockDatabase.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {
            'date_traitement': dateRef.toIso8601String(),
            'traitement_id': 100,
          });

      when(mockDatabase.query(any, any))
          .thenAnswer((_) async => [
            {'facture_id': 1, 'montant': 50000, 'etat': 'Non payé'},
          ]);

      // Correction : La transaction dans majMontantEtHistorique ne retourne rien (Future<void>)
      when(mockDatabase.transaction<void>(any)).thenAnswer((_) async {});

      final success = await repository.majMontantEtHistorique(factureId, oldPrix, newPrix, isAdmin: true);

      expect(success, isTrue);
      verify(mockDatabase.transaction(any)).called(1);
    });

    test('updateFacturePrice doit échouer si non admin', () async {
      final success = await repository.updateFacturePrice(1, 100, isAdmin: false);
      expect(success, isFalse);
      expect(repository.errorMessage, contains('administrateur'));
    });
  });
}
