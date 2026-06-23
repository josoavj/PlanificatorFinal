# Planificator - Changelog Global

Ce fichier centralise toutes les évolutions, corrections de bugs et optimisations de la plateforme Planificator.

**Version Actuelle**: 2.1.1  
**Statut**: PRODUCTION READY  
**Dernière mise à jour**: 2026-06-25

---

## [2.1.1] - Fiabilité Financière & Robustesse (2026-06-25)

### 💎 Intégrité des Données (SGBDR)
- **Atomic SQL Transactions** : Implémentation du support des transactions (`START TRANSACTION`, `COMMIT`, `ROLLBACK`) pour garantir que les opérations financières complexes soient atomiques.
- **Sécurisation des Prix** : La mise à jour massive des prix sur les interventions futures est désormais protégée par une transaction. En cas de coupure réseau, aucune donnée n'est corrompue.
- **Régénération Sécurisée** : La création automatique de plannings et de factures est désormais atomique (évite les plannings orphelins sans factures).

### 🚀 Optimisations UI & Performance
- **Infinite Scrolling (Lazy Loading)** : L'historique des interventions utilise désormais une pagination (paquets de 50) pour un affichage instantané, peu importe le nombre d'entrées en base.
- **Axe/Région Automatisé** : Détection intelligente de l'axe géographique du client lors de la création de factures, garantissant des statistiques régionales exactes.
- **Robust Model Parsing** : Ajout de protections `try-catch` et de valeurs de secours dans les modèles (Facture, User) pour éviter les crashs en cas de données corrompues en production.

### 🛠️ Maintenance & Qualité Code
- **Analyse Statique Rigoureuse** : Correction de plus de 120 avertissements `flutter analyze` (redondances, dépréciations, conventions de nommage).
- **Refactoring des Tests** : Mise à jour de la suite de tests unitaires pour correspondre au schéma réel de la base de données de production.
- **Mocking Système** : Ajout de mocks manuels pour les tests unitaires afin de faciliter l'intégration continue sans dépendances de build lourdes.

---

## [2.1.1] - Industrialisation & Performance (2026-02-01)

### 🚀 Optimisations Majeures
- **Smart Cache System** : Implémentation d'un gestionnaire de cache SQL global.
- **SQL Centralization** : Déplacement de 100% des scripts SQL vers `lib/core/sql_queries.dart`.
- **Advanced Connection Pooling** : Pool de connexions MySQL réutilisables (5-10 connexions).
- **Gestion Hybride des Isolates** : Optimisation de `compute()` selon la charge.

### 🛡️ Sécurité & Stabilité
- **Log Sanitization** : Masquage automatique des données sensibles dans les logs.
- **Requêtes Paramétrées** : Protection totale contre les injections SQL.
- **Zéro Erreur d'Analyse** : Premier nettoyage complet des lints.

---

## Sécurité & Durcissement (2026-01-31)
- **Chiffrement des identifiants** : Utilisation de `flutter_secure_storage` (DPAPI/Keystore).
- **Optimisation Windows** : Suppression des sous-requêtes corrélées impactant les performances.

---

## Refactoring & Corrections (2026-01-17)
- **Standardisation des Modèles** : Formatage uniforme "Nom Prénom".
- **Optimisation des Jointures** : Passage en `INNER JOIN` pour les listes critiques.
- **Sécurité Async** : Ajout de guards `mounted` dans tous les dialogues.
