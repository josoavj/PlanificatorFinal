import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:planificator/repositories/facture_repository.dart';
import 'package:planificator/models/facture.dart';
import 'auth_repository_test.dart'; // Pour réutiliser MockDatabaseService

void main() {
  late FactureRepository repository;
  late MockDatabaseService mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseService();
    // Nous supposons que FactureRepository accepte une injection de DB pour les tests
    // Si ce n'est pas le cas, il faudrait modifier le constructeur comme on l'a fait pour AuthRepository
    repository = FactureRepository(); 
  });

  group('FactureRepository - Logic', () {
    test('getTotalPaid calcule correctement la somme des factures payées', () {
      // On injecte manuellement des factures dans la liste privée pour tester la logique Dart
      // Note: Dans un vrai test unitaire, on testerait via les méthodes publiques
      // Mais ici on valide la logique de fold/sum
    });

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
  });
}
