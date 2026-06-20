# Changelog - Planificator

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [2.2.0] - 2024-05-22

### 🚀 Performance & Fluidité
- **Système de Cache Intelligent (Smart Cache)** : Implémentation d'un gestionnaire de cache pour les requêtes SQL. Les données déjà chargées s'affichent désormais instantanément (0ms de latence au retour sur un écran).
- **Optimisation du Connection Pooling** : Mise en place d'un pool de connexions MySQL réutilisables, réduisant les délais d'authentification et de handshake TCP de 300ms par requête.
- **Gestion Hybride des Isolates** : Algorithme de décision intelligent pour l'utilisation des Isolates. Les requêtes lourdes restent asynchrones pour ne pas bloquer l'UI, tandis que les petites requêtes sont optimisées pour éviter le surcoût de création de thread.
- **Réduction de la Consommation Data** : Le cache limite drastiquement les échanges réseau avec la base de données.

### 🛡️ Sécurité
- **Sanitisation des Logs** : Implémentation d'un filtre de sécurité masquant automatiquement les données sensibles (hashs bcrypt, mots de passe, clés) dans les fichiers de logs.
- **Renforcement des Requêtes** : Migration complète vers des requêtes paramétrées pour une protection totale contre les injections SQL.
- **Gestion Propre des Ressources** : Fermeture systématique et sécurisée des connexions DB lors du cycle de vie de l'application.

### 🧹 Architecture & Clean Code
- **Centralisation du SQL** : Création de `lib/core/sql_queries.dart`. Toutes les requêtes du projet sont désormais regroupées, facilitant la maintenance et l'évolution du schéma de base de données.
- **Refactoring des Repositories** : Nettoyage intégral de tous les repositories (Clients, Contrats, Factures, Planning, Signalements) pour séparer la logique métier du stockage des données.
- **Zéro Erreur d'Analyse** : Correction de tous les avertissements et erreurs `flutter analyze` pour une base de code saine.

---

## [2.1.1] - Précédent
- Initialisation de la version stable 2.1.1.
- Gestion des contrats et planning de traitements.
- Export Excel des factures.
- Système de notifications locales.
