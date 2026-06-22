import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/models/user.dart';
import 'package:planificator/models/client.dart';
import 'package:planificator/models/contrat.dart';
import 'package:planificator/models/facture.dart';
import 'package:planificator/models/planning_details.dart';

void main() {
  group('User Model', () {
    test('User.fromJson parse correctement les données', () {
      final json = {
        'user_id': 1,
        'email': 'user@example.com',
        'nom': 'Dupont',
        'prenom': 'Jean',
        'is_admin': 1,
        'token': 'abc123',
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.userId, equals(1));
      expect(user.email, equals('user@example.com'));
      expect(user.nom, equals('Dupont'));
      expect(user.prenom, equals('Jean'));
      expect(user.isAdmin, isTrue);
      expect(user.fullName, equals('Dupont Jean'));
    });

    test('User.fromMap gère les données de la base (Account table)', () {
      final map = {
        'userId': 1, // alias id_compte as userId
        'email': 'user@example.com',
        'nom': 'Dupont',
        'prenom': 'Jean',
        'type_compte': 'Administrateur',
        'password': 'hashed_password',
        'date_creation': '2024-01-15 10:30:00',
      };

      final user = User.fromMap(map);

      expect(user.userId, equals(1));
      expect(user.isAdmin, isTrue);
      expect(user.token, equals('hashed_password'));
    });

    test('User.fullName combine nom et prénom', () {
      final user = User(
        userId: 1,
        email: 'test@example.com',
        nom: 'Martin',
        prenom: 'Pierre',
        isAdmin: false,
      );

      expect(user.fullName, equals('Martin Pierre'));
    });
  });

  group('Client Model', () {
    test('Client.fromMap parse correctement les données', () {
      final map = {
        'client_id': 1,
        'nom': 'ACME Corp',
        'prenom': 'N/A',
        'email': 'contact@acme.com',
        'telephone': '0312345678',
        'adresse': '123 Rue de Paris',
        'categorie': 'Société',
        'nif': 'NIF123456',
        'stat': 'STAT789',
        'axe': 'Centre (C)',
        'date_ajout': '2024-01-15T10:30:00.000Z',
        'treatment_count': 5,
      };

      final client = Client.fromMap(map);

      expect(client.clientId, equals(1));
      expect(client.nom, equals('ACME Corp'));
      expect(client.categorie, equals('Société'));
      expect(client.treatmentCount, equals(5));
    });

    test('Client.fullName affiche seulement le nom pour Société', () {
      final client = Client(
        clientId: 1,
        nom: 'ACME Corp',
        prenom: 'N/A',
        email: 'contact@acme.com',
        telephone: '',
        adresse: '',
        categorie: 'Société',
        nif: '',
        stat: '',
        axe: '',
        dateAjout: DateTime.now(),
      );

      expect(client.fullName, equals('ACME Corp'));
    });
  });

  group('Contrat Model', () {
    test('Contrat.fromMap gère les données de la base (ENUM duree)', () {
      final map = {
        'contrat_id': 1,
        'client_id': 1,
        'reference_contrat': 'REF001',
        'date_contrat': '2024-01-15',
        'date_debut': '2024-01-15',
        'date_fin': '2025-01-15',
        'statut_contrat': 'Actif',
        'duree_contrat': 12,
        'duree': 'Déterminée', // ENUM in DB
        'categorie': 'Nouveau',
      };

      final contrat = Contrat.fromMap(map);

      expect(contrat.contratId, equals(1));
      expect(contrat.duree, isNull); // parseDuree returns null for 'Déterminée'
    });

    test('Contrat gère les dates indéterminées', () {
      final map = {
        'contrat_id': 1,
        'client_id': 1,
        'reference_contrat': 'REF001',
        'date_contrat': '2024-01-15',
        'date_debut': '2024-01-15',
        'date_fin': 'Indéterminée',
        'statut_contrat': 'Actif',
        'duree_contrat': 0,
        'duree': 'Indéterminée',
        'categorie': 'Renouvellement',
      };

      final contrat = Contrat.fromMap(map);

      expect(contrat.dateFin, isNull);
      expect(contrat.duree, isNull);
    });
  });

  group('Facture Model', () {
    test('Facture.fromMap parse correctement les données', () {
      final map = {
        'facture_id': 10,
        'planning_detail_id': 5,
        'reference_facture': 'FAC-2024-001',
        'montant': 150000,
        'mode': 'Espèce',
        'date_traitement': '2024-02-15',
        'etat': 'Payé',
        'axe': 'Centre (C)',
      };

      final facture = Facture.fromMap(map);

      expect(facture.factureId, equals(10));
      expect(facture.montant, equals(150000));
      expect(facture.isPaid, isTrue);
      expect(facture.montantFormatted, contains('150 000'));
    });
  });

  group('PlanningDetails Model', () {
    test('PlanningDetails.fromJson parse correctement', () {
      final json = {
        'planning_detail_id': 1,
        'planning_id': 2,
        'date_planification': '2024-05-20',
        'statut': 'À venir',
      };

      final details = PlanningDetails.fromJson(json);

      expect(details.planningDetailId, equals(1));
      expect(details.datePlanification.month, equals(5));
      expect(details.statut, equals('À venir'));
    });
  });
}
