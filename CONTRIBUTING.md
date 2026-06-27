# 🤝 Guide de Contribution - Planificator

Merci de l'intérêt que vous portez à la plateforme Planificator ! Ce document définit les standards techniques et le flux de travail pour assurer la stabilité de l'application en production.

---

## 🚀 1. Configuration de l'environnement

1.  **Flutter SDK** : Assurez-vous d'utiliser la version mentionnée dans le `pubspec.yaml`.
2.  **Base de données** : Installez MySQL (≥ 8.0). Importez le schéma initial depuis `scripts/Planificator.sql`.
3.  **Analyse Statique** : Avant toute soumission, votre code doit passer l'analyse sans erreur :
    ```bash
    flutter analyze
    ```

---

## 🏗️ 2. Architecture & Standards de Code

### Modèle Repository
Toute la logique de données doit passer par les classes dans `lib/repositories/`. Ne faites jamais de requêtes SQL directement dans les Widgets (Screens).

### Intégrité SGBDR (Transactions)
Pour toute opération impliquant plusieurs requêtes liées (ex: mise à jour d'un contrat + suppression de plannings), vous **devez** utiliser une transaction :
```dart
await _db.transaction((conn) async {
  await conn.query(...);
  await conn.query(...);
});
```

### SQL Centralisé
N'écrivez pas de chaînes SQL brutes dans les repositories. Ajoutez vos requêtes dans `lib/core/sql_queries.dart`.

---

## 🧪 3. Standards de Test

La plateforme repose sur une suite de tests unitaires (70+). Toute nouvelle fonctionnalité **doit** s'accompagner de son fichier de test dans le dossier `test/`.

- **Exécution** : `flutter test`
- **Mocks** : Utilisez les mocks manuels définis dans `test/repositories/auth_repository_test.dart` pour simuler la base de données.

---

## 🌿 4. Workflow Git

1.  **Branches** : Travaillez toujours sur une branche de fonctionnalité (ex: `feature/ma-fonctionnalite`) basée sur la branche de version actuelle (ex: `2.1.1`).
2.  **Commits** : Utilisez des messages clairs et préfixés :
    - `feat:` pour une nouvelle fonctionnalité.
    - `fix:` pour une correction de bug.
    - `docs:` pour la documentation.
    - `refactor:` pour une modification de code sans changement de comportement.
    - `test:` pour l'ajout ou la modification de tests.

---

## 📝 5. Documentation

À chaque modification importante :
- Mettez à jour le **`README.md`** si nécessaire.
- Ajoutez une entrée précise dans le **`CHANGELOG.md`** sous la version actuelle.
- Vérifiez que les notes de **`SECURITY.md`** sont toujours exactes si vous touchez à l'authentification ou à la DB.

---

## ✅ 6. Liste de contrôle avant soumission

- [ ] `flutter analyze` ne remonte aucune erreur.
- [ ] `flutter test` passe à 100%.
- [ ] Les nouvelles requêtes SQL sont dans `SqlQueries.dart`.
- [ ] Les opérations multi-tables sont protégées par une transaction.
- [ ] Les données sensibles dans les paramètres sont masquées pour les logs.

---
**Dernière mise à jour** : 25 Juin 2026
