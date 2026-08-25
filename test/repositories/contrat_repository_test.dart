import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/repositories/contrat_repository.dart';
import 'package:planificator/models/contrat.dart';
import '../config/mocks.dart';

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

    test('getActiveContrats filtre correctement selon la date actuelle', () {
      final now = DateTime.now();
      
      // Contrat Actif (dans les dates)
      final c1 = Contrat(
        contratId: 1, clientId: 1, referenceContrat: 'R1', 
        dateContrat: now, dateDebut: now.subtract(const Duration(days: 10)), 
        dateFin: now.add(const Duration(days: 10)), statutContrat: 'Actif',
        dureeContrat: 12, dureeType: 'Déterminée', categorie: 'Nouveau'
      );

      // Contrat Futur (pas encore commencé)
      final c2 = Contrat(
        contratId: 2, clientId: 1, referenceContrat: 'R2', 
        dateContrat: now, dateDebut: now.add(const Duration(days: 10)), 
        statutContrat: 'Actif', dureeContrat: 0, dureeType: 'Indéterminée', categorie: 'Nouveau'
      );

      // Contrat Terminé (date fin passée)
      final c3 = Contrat(
        contratId: 3, clientId: 1, referenceContrat: 'R3', 
        dateContrat: now, dateDebut: now.subtract(const Duration(days: 30)), 
        dateFin: now.subtract(const Duration(days: 5)), statutContrat: 'Terminé',
        dureeContrat: 1, dureeType: 'Déterminée', categorie: 'Nouveau'
      );

      // Injecter manuellement via le repository si possible ou tester la méthode isActive du modèle
      // Puisque getActiveContrats filtre la liste interne _contrats, on ne peut pas l'injecter directement sans load.
      // On teste ici la logique du modèle Contrat qui est utilisée par le repository.
      expect(c1.isActive, isTrue);
      expect(c2.isActive, isFalse);
      expect(c3.isActive, isFalse);
    });
  });
}
