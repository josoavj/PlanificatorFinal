# Planificator - Changelog Global

Ce fichier centralise toutes les évolutions, corrections de bugs et optimisations de la plateforme Planificator.

**Version Actuelle**: 2.1.1  
**Statut**: PRODUCTION READY  
**Dernière mise à jour**: 2026-02-01

---

## [2.1.1] - Industrialisation & Performance (2026-02-01)

### 🚀 Optimisations Majeures
- **Smart Cache System** : Implémentation d'un gestionnaire de cache SQL global. Les requêtes de lecture répétées (SELECT) sont désormais instantanées (0ms de latence).
- **SQL Centralization** : Déplacement de 100% des scripts SQL vers `lib/core/sql_queries.dart`. Maintenance unifiée et protection du schéma.
- **Advanced Connection Pooling** : Mise en place d'un pool de connexions MySQL réutilisables (5-10 connexions), éliminant les délais d'authentification à chaque requête.
- **Gestion Hybride des Isolates** : Optimisation de `compute()`. L'Isolate n'est utilisé que pour les traitements lourds, évitant la surcharge sur les petites requêtes.

### 🛡️ Sécurité & Stabilité
- **Log Sanitization** : Masquage automatique des données sensibles (mots de passe, hashs bcrypt) dans les logs de la plateforme.
- **Requêtes Paramétrées** : Généralisation des paramètres `?` pour une protection totale contre les injections SQL.
- **Zéro Erreur d'Analyse** : Nettoyage complet des avertissements `flutter analyze`.

---

## Sécurité & Durcissement (2026-01-31)
- **Chiffrement des identifiants** : Utilisation de `flutter_secure_storage` (DPAPI/Keystore) pour les credentials de la base de données.
- **Optimisation Windows** : Suppression des sous-requêtes corrélées impactant les performances sur les builds Release Windows.
- **Nettoyage Code** : Suppression de tous les emojis dans les commentaires techniques pour une meilleure lisibilité par les outils d'audit.

---

## Refactoring & Corrections (2026-01-17)
- **Standardisation des Modèles** : Formatage uniforme "Nom Prénom" pour les clients et factures.
- **Optimisation des Jointures** : Passage en `INNER JOIN` pour les listes clients afin de n'afficher que les comptes actifs.
- **Sécurité Async** : Ajout de guards `mounted` dans tous les dialogues (Remarque, Signalement) pour éviter les crashs lors de fermetures rapides.
- **Tri Alphabétique** : Implémentation du tri local pour les factures et clients.

---

## Corrections Critiques - Session Initiale (2024-12-20)
- **Fix Boucle Infinie** : Correction de l'algorithme de génération des dates de planning (`lib/utils/date_utils.dart`).
- **Fix Typage Dates** : Correction des erreurs de parsing DateTime sur les contrats.
- **Tests Unitaires** : Ajout de 17 tests couvrant les cas limites des calculs de dates.
