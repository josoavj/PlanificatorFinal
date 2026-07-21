# Documentation des Tests - Planificator

Cette documentation détaille la suite de tests automatisés de la plateforme Planificator. Ces tests garantissent que les fonctionnalités critiques fonctionnent correctement à chaque modification du code.

## Comment lancer les tests ?

Pour exécuter l'ensemble de la suite de tests, utilisez la commande suivante à la racine du projet :

```bash
flutter test
```

---

## Structure de la Suite de Tests

La suite est divisée en plusieurs modules spécialisés :

### 1. Logique Calendaire (test/utils/date_utils_test.dart)

C'est le module le plus important pour la partie "Planning".
- **Jours Fériés Madagascar** : Vérifie l'identification correcte des jours fériés (26 Juin, 29 Mars, 1er Mai, Noël, etc.).
- **Décalage Weekend** : Garantit qu'une intervention tombant un dimanche ou un jour férié est automatiquement décalée au prochain jour ouvré.
- **Génération de Planning** : Vérifie la précision des dates pour les fréquences mensuelles et hebdomadaires.

### 2. Calculs Financiers (test/utils/number_formatter_test.dart)

Sécurise la saisie et l'affichage des montants en Ariary.
- **Saisie Interactive** : Vérifie que le formateur de texte ajoute correctement les espaces pendant que l'utilisateur tape.
- **Parsing Robuste** : Vérifie que "1 500 000 Ar" est bien converti en entier.
- **Formatage** : Assure l'affichage correct des séparateurs de milliers.

### 3. Formateurs Madagascar (test/utils/nif_stat_formatter_test.dart)

Vérifie l'intégrité des données fiscales et de contact.
- **NIF & STAT** : Teste le respect des longueurs (10 et 17 chiffres) et l'ajout des espaces aux positions standards.
- **Téléphone** : Vérifie le formatage `03X XX XXX XX`.

### 4. Authentification et Sécurité (test/repositories/auth_repository_test.dart)

Protège l'accès à la plateforme.
- **BCrypt** : Vérifie la logique de hachage et de comparaison des mots de passe.
- **Session** : Assure que la déconnexion nettoie correctement les données.
- **Verrouillage Admin** : Teste la méthode de vérification du mot de passe pour les actions critiques.

### 5. Gestion du Cache (test/services/query_cache_service_test.dart)

Garantit la performance de l'application sans sacrifier la fraîcheur des données.
- **Expiration** : Vérifie que les données disparaissent du cache après le délai imparti.
- **Invalidation** : Assure que modifier une donnée vide correctement les parties concernées du cache.

### 6. Logique Contrat et Transaction (test/repositories/contrat_repository_test.dart)

- **Sauvegarde Atomique** : Vérifie que le repository lance bien une transaction pour la création de contrats complexes.
- **Calcul de Durée** : Vérifie le calcul automatique des mois entre deux dates.

---

## Stratégie de Mocking

Pour tester les composants sans avoir besoin d'une vraie base de données MySQL, nous utilisons des **Mocks manuels** pour le `DatabaseService`. Cela permet de simuler des scénarios comme une perte de connexion ou des timeouts.

---
**Dernière mise à jour** : 22 Juillet 2026
