import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/models/user.dart';
import 'package:planificator/models/client.dart';
import 'package:planificator/models/contrat.dart';

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

    test('User.copyWith crée une copie modifiée', () {
      final user1 = User(
        userId: 1,
        email: 'test@example.com',
        nom: 'Dupont',
        prenom: 'Jean',
        isAdmin: false,
      );

      final user2 = user1.copyWith(isAdmin: true);

      expect(user2.isAdmin, isTrue);
      expect(user2.email, equals(user1.email));
      expect(user1.isAdmin, isFalse); // Original non modifié
    });

    test('User.fromMap gère les variantes de nom de colonne', () {
      final map = {
        'userId': 1,
        'email': 'user@example.com',
        'nom': 'Dupont',
        'prenom': 'Jean',
        'isAdmin': true,
      };

      final user = User.fromMap(map);

      expect(user.userId, equals(1));
      expect(user.isAdmin, isTrue);
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

    test('Client.fullName affiche nom et prénom pour Particulier', () {
      final client = Client(
        clientId: 1,
        nom: 'Dupont',
        prenom: 'Jean',
        email: 'jean@example.com',
        telephone: '',
        adresse: '',
        categorie: 'Particulier',
        nif: '',
        stat: '',
        axe: '',
        dateAjout: DateTime.now(),
      );

      expect(client.fullName, equals('Dupont Jean'));
    });

    test('Client.prenomLabel retourne "Responsable" pour Société', () {
      final client = Client(
        clientId: 1,
        nom: 'ACME',
        prenom: '',
        email: '',
        telephone: '',
        adresse: '',
        categorie: 'Société',
        nif: '',
        stat: '',
        axe: '',
        dateAjout: DateTime.now(),
      );

      expect(client.prenomLabel, equals('Responsable'));
    });

    test('Client.prenomLabel retourne "Prénom" pour Particulier', () {
      final client = Client(
        clientId: 1,
        nom: 'Dupont',
        prenom: 'Jean',
        email: '',
        telephone: '',
        adresse: '',
        categorie: 'Particulier',
        nif: '',
        stat: '',
        axe: '',
        dateAjout: DateTime.now(),
      );

      expect(client.prenomLabel, equals('Prénom'));
    });
  });

  group('Contrat Model', () {
    test('Contrat.fromMap parse correctement les dates', () {
      final map = {
        'contrat_id': 1,
        'client_id': 1,
        'reference_contrat': 'REF001',
        'date_contrat': '2024-01-15',
        'date_debut': '2024-01-15',
        'date_fin': '2025-01-15',
        'statut_contrat': 'Actif',
        'duree_contrat': 12,
        'duree': 11,
        'categorie': 'Annuel',
      };

      final contrat = Contrat.fromMap(map);

      expect(contrat.contratId, equals(1));
      expect(contrat.referenceContrat, equals('REF001'));
      expect(contrat.statutContrat, equals('Actif'));
      expect(contrat.dateDebut.year, equals(2024));
    });

    test('Contrat gère les dates indéterminées (null)', () {
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
        'categorie': 'Indéterminé',
      };

      final contrat = Contrat.fromMap(map);

      expect(contrat.dateFin, isNull);
      expect(contrat.duree, isNull);
    });
  });
}
