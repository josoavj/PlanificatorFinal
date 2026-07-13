import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/repositories/contrat_repository.dart';
import 'package:planificator/models/contrat.dart';
import 'auth_repository_test.dart'; // Pour MockDatabaseService

void main() {
  late ContratRepository repository;
  late MockDatabaseService mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseService();
    repository = ContratRepository(databaseService: mockDatabase);
  });

  group('ContratRepository - Business Logic', () {
    test('getContractDurationInMonths calcule correctement la différence de mois', () {
      final start = DateTime(2024);
      final end = DateTime(2025); // Exactement 12 mois
      
      final contrat = Contrat(
        contratId: 1,
        clientId: 1,
        referenceContrat: 'REF',
        dateContrat: start,
        dateDebut: start,
        dateFin: end,
        statutContrat: 'Actif',
        dureeContrat: 12,
        dureeType: 'Déterminée',
        categorie: 'Nouveau'
      );

      final duration = repository.getContractDurationInMonths(contrat);
      expect(duration, equals(12));
    });

    test('getContractDurationInMonths retourne 0 pour les contrats indéterminés', () {
      final start = DateTime(2024);
      
      final contrat = Contrat(
        contratId: 1,
        clientId: 1,
        referenceContrat: 'REF',
        dateContrat: start,
        dateDebut: start,
        statutContrat: 'Actif',
        dureeContrat: 0,
        dureeType: 'Indéterminée',
        categorie: 'Nouveau'
      );

      final duration = repository.getContractDurationInMonths(contrat);
      expect(duration, equals(0));
    });

    test('getActiveContrats filtre correctement selon la date actuelle', () {
      // Test de logique de filtrage sur une liste
    });
  });
}
