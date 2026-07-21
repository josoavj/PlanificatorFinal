# Guide de Contribution - Planificator

Merci de l'intérêt que vous portez à la plateforme Planificator ! Ce document définit les standards techniques et le flux de travail pour assurer la stabilité de l'application en production.

---

## 1. Configuration de l'environnement

1.  **Flutter SDK** : Assurez-vous d'utiliser la version mentionnée dans le `pubspec.yaml`.
2.  **Base de données** : Installez MySQL (≥ 8.0). Importez le schéma initial depuis `scripts/Planificator.sql`.
3.  **Analyse Statique** : Avant toute soumission, votre code doit passer l'analyse sans erreur :
    ```bash
    flutter analyze
    ```

---

## 2. Architecture et Standards de Code

### Modèle Repository

Toute la logique de données doit passer par les classes dans `lib/repositories/`. Ne faites jamais de requêtes SQL directement dans les Widgets.

### Intégrité SGBDR (Transactions)

Pour toute opération impliquant plusieurs requêtes liées (ex: création de contrat), vous **devez** utiliser la méthode `transaction` du `DatabaseService` pour assurer l'atomicité des données.

### Formatage Madagascar

Pour toute saisie de données spécifiques à Madagascar, utilisez obligatoirement les formateurs centralisés :
- `NifStatFormatter` pour les identifiants fiscaux.
- `PhoneFormatter` pour les numéros de téléphone.
- `NumberFormatter` pour les montants financiers.

---

## 3. Standards de Test

Toute nouvelle fonctionnalité **doit** s'accompagner de son fichier de test dans le dossier `test/`.

- **Exécution** : `flutter test`
- **Mocks** : Utilisez les mocks manuels définis pour simuler la base de données.

---

## 4. Workflow Git

1.  **Branches** : Travaillez sur une branche de fonctionnalité (ex: `feature/nom`) basée sur la version actuelle (ex: `2.2.0`).
2.  **Commits** : Utilisez des messages clairs en français, préfixés par le type d'intervention (`feat:`, `fix:`, `style:`, `refactor:`, `docs:`, `test:`).

---

## 5. Documentation

À chaque modification importante :

- Mettez à jour le **README.md**.
- Ajoutez une entrée précise dans le **CHANGELOG.md**.
- Vérifiez la conformité des notes de **SECURITY.md**.

---

## 6. Liste de contrôle avant soumission

- [ ] `flutter analyze` ne remonte aucune erreur.
- [ ] `flutter test` passe à 100%.
- [ ] Les opérations multi-tables sont protégées par une transaction SQL.
- [ ] Les données sensibles sont masquées dans les paramètres de log.

---
**Dernière mise à jour** : 22 Juillet 2026
