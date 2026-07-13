# Documentation des Tests - Planificator

Cette documentation détaille la suite de tests automatisés de la plateforme Planificator. Ces tests garantissent que les fonctionnalités critiques (comptabilité, planification, sécurité) fonctionnent correctement à chaque modification du code.

## Comment lancer les tests ?

Pour exécuter l'ensemble de la suite de tests, utilisez la commande suivante à la racine du projet :

```bash
flutter test
```

---

## Structure de la Suite de Tests

La suite est divisée en plusieurs modules spécialisés :

### 1. Logique Calendaire (`test/utils/date_utils_test.dart`)

C'est le module le plus important pour la partie "Planning".
- **Jours Fériés** : Vérifie que les jours fériés spécifiques à Madagascar (26 Juin, Noël, etc.) sont bien identifiés.
- **Décalage Weekend** : Garantit qu'une intervention tombant un dimanche est automatiquement décalée au lundi.
- **Génération de Planning** : Vérifie que le bon nombre de dates est généré selon la redondance (ex: 4 dates pour un trimestre).

### 2. Calculs Financiers (`test/utils/number_formatter_test.dart`)

Sécurise la saisie et l'affichage des montants en Ariary.
- **Parsing Robuste** : Vérifie que "1 500 000 Ar" est bien converti en entier `1500000`.
- **Sécurité** : Garantit que les montants négatifs sont convertis en positifs pour éviter les erreurs de caisse.
- **Formatage** : Assure l'affichage correct des séparateurs de milliers.

### 3. Authentification & Sécurité (`test/repositories/auth_repository_test.dart`)

Protège l'accès à la plateforme.
- **BCrypt** : Vérifie la logique de hachage et de comparaison des mots de passe.
- **Session** : Assure que la déconnexion nettoie correctement les données de l'utilisateur actuel.
- **Gestion d'Erreurs** : Vérifie les messages d'erreur en cas d'identifiants incorrects.

### 4. Gestion du Cache (`test/services/query_cache_service_test.dart`)

Garantit la performance de l'application sans sacrifier la fraîcheur des données.
- **Expiration (TTL)** : Vérifie que les données disparaissent du cache après le délai imparti.
- **Invalidation Intelligente** : Assure que modifier un client vide uniquement les données liées au client dans le cache.

### 5. Modèles de Données (`test/models/models_test.dart`)

Vérifie le "tuyau" entre la base de données MySQL et l'interface Flutter.
- **Robustesse** : Teste la résistance aux données corrompues ou nulles venant de la base de données.
- **Mapping** : Garantit que les nouveaux champs (`dureeType`, `dureeContrat`) sont correctement lus.

### 6. Logique Contrat (`test/repositories/contrat_repository_test.dart`)

- **Calcul de Durée** : Vérifie le calcul automatique des mois entre deux dates de contrat.
- **Type de Contrat** : Assure la distinction entre contrats Déterminés et Indéterminés.

---

## Stratégie de Mocking

Pour tester les composants sans avoir besoin d'une vraie base de données MySQL (indispensable pour l'intégration continue), nous utilisons des **Mocks manuels** pour le `DatabaseService`.

Cela permet de simuler des scénarios comme :

- Une perte de connexion réseau.
- Un utilisateur inexistant.
- Une base de données vide.

## Recommandations pour l'avenir

- **Tests UI (Widget Tests)** : Ajouter des tests pour vérifier que les boutons critiques (ex: "Valider le paiement") ouvrent les bons dialogues.
- **Tests d'Intégration** : Lancer des tests sur une base de données de test réelle pour vérifier les Triggers SQL.

---
**Dernière mise à jour** : 25 Juin 2026
