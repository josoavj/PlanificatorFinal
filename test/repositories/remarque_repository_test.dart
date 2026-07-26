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

      // Correction : Spécifier explicitement le type T de la transaction
      when(mockDatabase.transaction<bool>(any)).thenAnswer((_) async => true);

      // Mock de récupération client_id
      when(mockDatabase.queryOne(any, params: anyNamed('params')))
          .thenAnswer((_) async => {'client_id': 1});

      await repository.createRemarque(
        planningDetailsId: pdId,
        factureId: fId,
        contenu: 'RAS',
        probleme: 'Aucun',
        action: 'Aucun',
        estPayee: true,
      );

      verify(mockDatabase.transaction(any)).called(1);
    });
  });
}
