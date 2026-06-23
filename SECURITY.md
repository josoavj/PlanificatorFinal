# Documentation de Sécurité - Planificator

Ce document détaille les mesures de sécurité implementées dans la plateforme Planificator pour protéger les données des clients et l'intégrité du système.

## 🔒 1. Protection des Identifiants (Credentials)

La plateforme ne stocke jamais les identifiants de la base de données en texte clair.

- **Stockage Chiffré** : Utilisation du package `flutter_secure_storage`.
  - **Android** : Chiffrement via **AES** avec une clé protégée par le **Android Keystore**.
  - **iOS** : Stockage sécurisé dans le **Keychain**.
  - **Windows** : Utilisation de **DPAPI** (Data Protection API).
- **Séparation des données** : 
  - Les données non sensibles (hôte, port) sont dans `SharedPreferences`.
  - Les données sensibles (utilisateur, mot de passe) sont exclusivement dans le stockage chiffré.

## 🛡️ 2. Sécurité & Intégrité de la Base de Données

- **Injections SQL** : Protection systématique via **requêtes paramétrées** (placeholders `?`). Aucun script SQL n'est concaténé avec des entrées utilisateur.
- **Transactions Atomiques** : Utilisation systématique de `START TRANSACTION`, `COMMIT` et `ROLLBACK` pour toutes les opérations critiques (comptabilité, plannings). Cela garantit qu'une coupure réseau ne laisse jamais la base de données dans un état incohérent ou partiel.
- **Triggers de Protection** : La base de données utilise des triggers (`Planificator.sql`) pour forcer les règles de sécurité au niveau du moteur SGBDR (ex: unicité de l'admin, format d'email).

## 📝 3. Protection des Journaux (Log Sanitization)

Pour éviter la fuite de secrets dans les fichiers de logs :

- **Masquage Automatique** : Un filtre de sécurité analyse tous les paramètres des requêtes avant écriture.
- **Données masquées** :
  - Mots de passe en clair.
  - Hashs BCrypt (reconnaissance de signature `$2b$`).
  - Identifiants de connexion MySQL.

## 👤 4. Authentification Utilisateur

- **Hachage des Mots de Passe** : Utilisation de **BCrypt** avec un sel (salt) généré aléatoirement pour chaque utilisateur.
- **Résistance aux attaques** : BCrypt est conçu pour être lent, ce qui protège contre les attaques par force brute (brute-force).

## 🚀 5. Recommandations pour la Production

Bien que la plateforme soit renforcée, les mesures suivantes sont impératives pour un déploiement réel :

1. **SSL/TLS (HTTPS)** : Activez impérativement le chiffrement SSL sur votre serveur MySQL pour éviter l'interception des données en transit.
2. **Pare-feu (Firewall)** : Ne laissez pas le port 3306 ouvert à tout Internet. Restreignez l'accès aux adresses IP autorisées.
3. **Mises à jour** : Maintenez régulièrement les dépendances de la plateforme via `flutter pub upgrade`.

---
**Dernière révision de sécurité** : 25 Juin 2026
