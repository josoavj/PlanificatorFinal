import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planificator/repositories/client_repository.dart';
import 'package:planificator/core/sql_queries.dart';
import '../config/mocks.dart';

void main() {
  late ClientRepository repository;
  late MockDatabaseService mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseService();
    repository = ClientRepository(databaseService: mockDatabase);
  });

  group('ClientRepository - Recherche et Filtres', () {
    test('searchClients doit appeler la requête SQL avec les jokers %', () async {
      const query = 'Shadow';
      
      when(mockDatabase.query(any, any, any))
          .thenAnswer((_) async => []);

      await repository.searchClients(query);

      verify(mockDatabase.query(SqlQueries.searchClients, argThat(contains('%Shadow%')), any)).called(1);
    });

    test('loadClientsPage doit peupler la liste des clients', () async {
      final mockData = [
        {'client_id': 1, 'nom': 'Client A', 'prenom': 'P1', 'email': 'a@a.com', 'telephone': '', 'adresse': '', 'categorie': 'Particulier', 'nif': '', 'stat': '', 'axe': 'Centre (C)', 'date_ajout': '2024-01-01'},
      ];

      when(mockDatabase.query(any, any, any))
          .thenAnswer((_) async => mockData);

      await repository.loadClientsPage(0);

      expect(repository.clients.length, 1);
      expect(repository.clients.first.nom, 'Client A');
    });
  });

  group('ClientRepository - Sécurité', () {
    test('deleteClient doit utiliser une transaction et échouer si non admin', () async {
      final success = await repository.deleteClient(1, isAdmin: false);
      expect(success, isFalse);
      expect(repository.errorMessage, contains('administrateur'));
      verifyNever(mockDatabase.transaction(any));
    });

    test('deleteClient doit appeler la transaction si admin', () async {
      // Pour deleteClient, T est dynamic (void), donc on mock sans spécifier T ou avec any
      when(mockDatabase.transaction(any)).thenAnswer((_) async => null);

      final success = await repository.deleteClient(1, isAdmin: true);
      expect(success, isTrue);
      verify(mockDatabase.transaction(any)).called(1);
    });
  });
}
