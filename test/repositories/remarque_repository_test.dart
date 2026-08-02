import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planificator/repositories/remarque_repository.dart';
import '../config/mocks.dart';

void main() {
  late RemarqueRepository repository;
  late MockDatabaseService mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseService();
    repository = RemarqueRepository(databaseService: mockDatabase);
  });

  group('RemarqueRepository - Sécurité Transactionnelle', () {
    test('createRemarque doit utiliser une transaction SQL unique', () async {
      final pdId = 10;
      final fId = 20;

      // Mock de la transaction (doit retourner true car le repo attend un bool)
      when(mockDatabase.transaction<bool>(any)).thenAnswer((_) async => true);

      when(mockDatabase.queryOne(any, params: anyNamed('params'), useCache: anyNamed('useCache')))
          .thenAnswer((_) async => {'client_id': 1});

      await repository.createRemarque(
        planningDetailsId: pdId,
        factureId: fId,
        contenu: 'RAS',
        probleme: 'Aucun',
        action: 'Aucun',
        estPayee: true,
      );

      verify(mockDatabase.transaction<bool>(any)).called(1);
    });

    test('updateRemarqueFull doit synchroniser Remarque et Facture', () async {
      when(mockDatabase.execute(any, any)).thenAnswer((_) async {});

      final success = await repository.updateRemarqueFull(
        remarqueId: 1,
        factureId: 2,
        contenu: 'Modifié',
        estPayee: true,
      );

      expect(success, isTrue);
      // On s'attend à au moins 2 appels à execute
      verify(mockDatabase.execute(any, any)).called(greaterThanOrEqualTo(2));
    });
  });
}
