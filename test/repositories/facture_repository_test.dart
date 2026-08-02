import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planificator/repositories/facture_repository.dart';
import 'package:planificator/models/facture.dart';
import 'package:planificator/core/sql_queries.dart';
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

      when(mockDatabase.queryOne(any, params: anyNamed('params'), useCache: anyNamed('useCache')))
          .thenAnswer((_) async => {
            'date_traitement': dateRef.toIso8601String(),
            'traitement_id': 100,
          });

      when(mockDatabase.query(any, any, any))
          .thenAnswer((_) async => [
            {'facture_id': 1, 'montant': 50000, 'etat': 'Non payé'},
          ]);

      when(mockDatabase.transaction<void>(any)).thenAnswer((_) async {});

      final success = await repository.majMontantEtHistorique(factureId, oldPrix, newPrix, isAdmin: true);

      expect(success, isTrue);
      verify(mockDatabase.transaction<void>(any)).called(1);
    });
  });

  group('Facture - Logique des Totaux', () {
    test('Facture isPaid identifie correctement les états "Payé" et "Payée"', () {
      final f1 = Facture(
        factureId: 1, 
        planningDetailsId: 1, 
        montant: 100, 
        dateTraitement: DateTime.now(), 
        etat: 'Payé', 
        axe: 'Centre (C)'
      );
      final f2 = f1.copyWith(etat: 'Payée');
      final f3 = f1.copyWith(etat: 'Non payé');

      expect(f1.isPaid, isTrue);
      expect(f2.isPaid, isTrue);
      expect(f3.isPaid, isFalse);
    });

    test('getTotalPaid et getTotalUnpaid calculent correctement les sommes', () async {
      final mockData = [
        {'facture_id': 1, 'montant': 1000, 'etat': 'Payé', 'date_traitement': '2024-01-01', 'axe': 'C'},
        {'facture_id': 2, 'montant': 500, 'etat': 'Non payé', 'date_traitement': '2024-01-01', 'axe': 'C'},
        {'facture_id': 3, 'montant': 2000, 'etat': 'Payée', 'date_traitement': '2024-01-01', 'axe': 'C'},
      ];

      when(mockDatabase.query(any, any, any))
          .thenAnswer((_) async => mockData);

      await repository.loadAllFactures();

      expect(repository.getTotalPaid(), equals(3000));
      expect(repository.getTotalUnpaid(), equals(500));
    });
  });
}
