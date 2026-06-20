# Documentation de Sécurité - Planificator

Ce document détaille les mesures de sécurité implémentées dans la plateforme Planificator pour protéger les données des clients et l'intégrité du système.

## 🔒 1. Protection des Identifiants (Credentials)

La plateforme ne stocke jamais les identifiants de la base de données en texte clair.

- **Stockage Chiffré** : Utilisation du package `flutter_secure_storage`.
  - **Android** : Chiffrement via **AES** avec une clé protégée par le **Android Keystore** (Hardware-backed si disponible).
  - **iOS** : Stockage sécurisé dans le **Keychain**.
  - **Windows** : Utilisation de **DPAPI** (Data Protection API).
- **Séparation des données** : 
  - Les données non sensibles (hôte, port) sont dans `SharedPreferences`.
  - Les données sensibles (utilisateur, mot de passe) sont exclusivement dans le stockage chiffré.

## 🛡️ 2. Sécurité de la Base de Données

- **Injections SQL** : Protection systématique contre les injections SQL.
  - Utilisation exclusive de **requêtes paramétrées** (placeholders `?`).
  - Aucun script SQL n'est concaténé avec des entrées utilisateur.
- **Principe du Moindre Privilège** : Il est recommandé de créer un utilisateur MySQL spécifique pour la plateforme avec uniquement les droits `SELECT`, `INSERT`, `UPDATE`, `DELETE` sur la base `Planificator`.

## 📝 3. Protection des Journaux (Log Sanitization)

Pour éviter la fuite de secrets dans les fichiers de logs générés par `LoggingService` :

- **Masquage Automatique** : Un filtre de sécurité analyse tous les paramètres des requêtes avant écriture dans les logs de la plateforme.
- **Données masquées** :
  - Mots de passe en clair.
  - Hashs BCrypt (reconnaissance de signature `$2b$`).
  - Chaînes de caractères suspectes de plus de 20 caractères dans les champs sensibles.

## 👤 4. Authentification Utilisateur

- **Hachage des Mots de Passe** : Utilisation de **BCrypt** avec un sel (salt) généré aléatoirement pour chaque utilisateur.
- **Résistance aux attaques** : BCrypt est conçu pour être lent, ce qui protège contre les attaques par force brute (brute-force) et les tables de correspondance (rainbow tables).
- **Validation** : Les mots de passe ne sont jamais stockés, seul leur hash est comparé lors de la connexion.

## 🚀 5. Recommandations pour la Production

Bien que la plateforme soit renforcée, les mesures suivantes sont impératives pour un déploiement réel :

1. **SSL/TLS (HTTPS)** : Assurez-vous que la connexion MySQL utilise le chiffrement SSL pour éviter l'interception des données sur le réseau (Man-in-the-Middle).
2. **Pare-feu (Firewall)** : Ne laissez pas le port 3306 de votre serveur MySQL ouvert à tout Internet. Restreignez l'accès aux adresses IP autorisées.
3. **Mises à jour** : Maintenez régulièrement les dépendances de la plateforme via `flutter pub upgrade` pour corriger les éventuelles failles découvertes dans les bibliothèques tierces.

---
**Dernière révision de sécurité** : 1er Février 2026
