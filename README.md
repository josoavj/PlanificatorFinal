<p align="center">
  <img src="https://github.com/josoavj/PlanificatorFinal/blob/main/assets/logo/Logo-Planificator.ico" alt="LevelMind Logo" width="150"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%3E%3D3.1.0-blue?style=flat-square" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.1.0-blue?style=flat-square" alt="Dart Version">
  <img src="https://img.shields.io/badge/MySQL-8.0-orange?style=flat-square" alt="MySQL Version">
  <img src="https://img.shields.io/badge/Version-2.1.1-green?style=flat-square" alt="Current Version">
  <img src="https://img.shields.io/badge/Status-Stable-brightgreen?style=flat-square" alt="Status">
  <img src="https://img.shields.io/github/last-commit/josoavj/PlanificatorFinal?style=flat-square" alt="Last Commit">
</p>

<h1 align="center">📊 Planificator</h1>

<p align="center">
  <strong>Système complet de gestion des contrats, plannings et factures</strong>
</p>

<p align="center">
  Organisez efficacement vos interventions, suivez vos clients et gérez votre facturation en un seul endroit.
</p>

---

## 📋 Table des Matières

- [📖 À Propos](#-à-propos)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🚀 Fonctionnalités Avancées](#-fonctionnalités-avancées)
- [🏗️ Architecture](#-architecture)
- [💾 Base de Données](#-base-de-données)
- [🔧 Utilitaires](#-utilitaires)
- [📱 Écrans Principaux](#-écrans-principaux)
- [🐛 Bugs Fixes Récents](#-bugs-fixes-récents)
- [🚀 Démarrage Rapide](#-démarrage-rapide)
- [📦 Dépendances](#-dépendances)
- [📊 État du Projet](#-état-du-projet)
- [👨‍💻 Auteur](#-auteur)
- [📄 Licence](#-licence)
- [🎯 Roadmap Futures](#-roadmap-futures)
- [💡 Contribution](#-contribution)
- [🐛 Signaler un Bug](#-signaler-un-bug)

---

## 📖 À Propos

**Planificator** est une application Flutter moderne et intuitive conçue pour révolutionner la gestion des contrats et de la facturation. Actuellement en **version 2.1.1 (Stable)**, elle offre une solution complète pour :

- 📋 Gérer efficacement vos clients et contrats
- 📅 Planifier vos interventions avec un calendrier interactif
- 💰 Suivre vos factures et effectuer des modifications de prix en cascade
- 📊 Consulter un historique complet de vos actions
- 🔍 Rechercher et filtrer rapidement vos données

### Objectifs Principaux

- 🎯 Centraliser la gestion des contrats et factures
- 📱 Offrir une expérience mobile fluide et intuitive
- 🔐 Garantir la fiabilité et la précision des données
- ⚡ Optimiser les opérations quotidiennes
- 📈 Supporter la croissance avec une architecture robuste

---

## ✨ Fonctionnalités

### Actuellement Disponibles ✅

#### 🔐 Authentification & Sécurité

- Système de **connexion sécurisée**
  - Hash des mots de passe avec bcrypt
  - Validation des identifiants
  - Sessions utilisateur persistantes
- **Système d'enregistrement** (inscription)
  - Création de nouveaux comptes
  - Validation des données
- Protection des données sensibles

#### 📋 Gestion des Clients

- Création, édition et suppression de clients
- Support des catégories (Particulier, Organisation, Société)
- Gestion complète : NIF, STAT, Adresse, Téléphone, Email
- Classification par axe géographique (Nord, Sud, Est, Ouest, Centre)
- Comptage précis des traitements par client
- Recherche et filtrage des clients

#### 📄 Gestion des Contrats

- Création de contrats avec sélection multiple de traitements
- Support des contrats déterminés (date fin) et indéterminés
- Affichage complet : numéro, référence, dates, durée
- Gestion des traitements associés avec détails
- Rechargement automatique après création
- Vue complète des contrats actifs et archivés

#### 💰 Gestion des Factures

- Recherche moderne : par client, traitement, date
- Groupement intelligent par client-traitement
- Affichage du montant total, payé et non payé
- Tri des factures par date décroissante (récentes en premier)
- **Modification de prix en cascade** :
  - Change le prix d'une facture
  - Applique automatiquement à toutes les factures suivantes du même traitement
  - Crée une piste d'audit dans `Historique_prix`
- Validation des montants (positifs uniquement)
- Gestion automatique des espaces dans les entrées
- États des factures (payée, partiellement payée, impayée)

#### 📅 Gestion du Planning

- Calendrier interactif avec `table_calendar`
- Affichage des traitements prévus et en cours
- Filtrage par état (À venir, En cours, Effectué)
- Génération automatique des dates de planning
- Bouton de rafraîchissement flottant
- Vue détaillée des plannings avec statuts

#### 🏠 Tableau de Bord (Home)

- Vue "En cours" : traitements du mois actuel
- Vue "À venir" : traitements futurs (sans redondance 1 mois)
- Affichage : dates, noms, états et axes
- **Bouton de rafraîchissement** pour mise à jour en temps réel
- Charge tous les statuts (pas seulement "À venir")

#### 📊 Historique & Audit

- Suivi complet de toutes les actions
- Affichage des modifications de prix avec ancien/nouveau montant
- Piste d'audit pour conformité
- Historique des traitements et modifications

#### 📤 Export de Données

- **Export en Excel**
  - Export des factures par client-traitement
  - Formatting automatique avec en-têtes
  - Support des montants et dates formatés
- **Export de rapports**
  - Données complètes des factures
  - Historique des modifications
  - Statistiques de gestion

#### 🔧 Paramètres & Configuration

- Gestion des préférences utilisateur
- Configuration de la base de données
- Paramètres d'affichage
- Gestion des notifications

#### ℹ️ À Propos

- Informations de l'application
- Numéro de version actuel
- Droits d'auteur et crédits
- Liens utiles

#### 📬 Remarques & Signalements

- Ajout de remarques sur les traitements
- Signalement de problèmes ou d'anomalies
- Suivi des commentaires utilisateur
- Piste d'audit des signalements

#### 🔔 Notifications

- **Notifications locales** intégrées
- Alertes planifiées pour les traitements
- Rappels des factures impayées
- Gestion des événements avec timezone

---

## 🏗️ Architecture

### Vue d'Ensemble

```
┌─────────────────────────────────────────────────────┐
│          Planificator - Gestion Contrats            │
├─────────────────────────────────────────────────────┤
│ Couche Présentation (Écrans & Widgets)              │
│  ├─ HomeScreen                                      │
│  ├─ ContratScreen (avec création multi-étapes)      │
│  ├─ FactureScreen (avec recherche & modification)   │
│  ├─ PlanningScreen (avec calendrier)                │
│  └─ HistoriqueScreen                                │
├─────────────────────────────────────────────────────┤
│ Couche Métier (Providers & Repositories)            │
│  ├─ FactureRepository                               │
│  ├─ ContratRepository                               │
│  ├─ PlanningDetailsRepository                       │
│  ├─ ClientRepository                                │
│  └─ SignalementRepository                           │
├─────────────────────────────────────────────────────┤
│ Couche Données (Services & DB)                      │
│  ├─ DatabaseService (MySQL connection)              │
│  ├─ NumberFormatter (utilitaires)                   │
│  └─ Database MySQL (schema optimisé)                │
└─────────────────────────────────────────────────────┘
```

### Stack Technologique

- **Framework** : Flutter 3.x
- **Langage** : Dart 3.x
- **Gestion d'état** : Provider (MultiProvider pattern)
- **Base de données** : MySQL avec SQL joins optimisés
- **Design** : Material Design 3
- **Logging** : Logger avec emojis pour meilleure lisibilité
- **Localisation** : Intl (fr_FR)
- **Calendrier** : table_calendar pour interactions avancées

### Structure des Dossiers

```
lib/
├── main.dart                           # Point d'entrée et Provider setup
├── config/
│   └── database_config.dart            # Configuration MySQL
├── core/
│   ├── constants.dart                  # Constantes de l'app
│   └── theme.dart                      # Thème Material Design 3
├── models/                             # Modèles de données
│   ├── client.dart
│   ├── contrat.dart
│   ├── facture.dart
│   ├── planning_event.dart
│   └── ...
├── repositories/                       # Couche d'accès aux données (10+ repos)
│   ├── facture_repository.dart         # Opérations sur factures + prix
│   ├── contrat_repository.dart         # Opérations sur contrats
│   ├── client_repository.dart          # Gestion des clients
│   ├── planning_details_repository.dart # Planning détaillé
│   └── ...
├── screens/
│   ├── home/
│   │   └── home_screen.dart
│   ├── contrat/
│   │   └── contrat_screen.dart
│   ├── facture/
│   │   └── facture_screen.dart
│   ├── planning/
│   │   └── planning_screen.dart
│   └── ...
├── services/
│   └── database_service.dart           # Service de connexion MySQL
├── utils/
│   └── number_formatter.dart           # Utilitaires de formatting des montants
└── widgets/                            # Composants réutilisables
```

---

## 💾 Base de Données

### Relations Principales

```
Facture (facture_id, montant, etat, date_traitement)
    ↓ planning_detail_id
PlanningDetails (statut, date_planification)
    ↓ planning_id
Planning (traitement_id, redondance)
    ↓ traitement_id
Traitement (contrat_id, id_type_traitement)
    ↓ contrat_id, id_type_traitement
Contrat + TypeTraitement
    ↓ client_id
Client (nom, prenom, axe, adresse)

Historique_prix : Piste d'audit des modifications (old_amount, new_amount, change_date)
Remarque : Commentaires et confirmations sur traitements
```

### Optimisations SQL

- **Treatment Counting** : `COUNT(DISTINCT t.traitement_id)` pour éviter les doublons
- **Price Cascade** : Mise à jour des factures suivantes du même traitement
- **DateTime Flexible** : Support de différents formats de base de données
- **Indexed Joins** : Joins optimisés pour les performances

---

## 🔧 Utilitaires

### NumberFormatter

Gère le parsing et le formatting des montants avec précision :

```dart
// Parsing montants avec espaces
final amount = NumberFormatter.parseMontant("50 000");      // → 50000
final amount2 = NumberFormatter.parseMontant("-50 000");    // → 50000 (positif)

// Formatting avec séparateurs
final formatted = NumberFormatter.formatMontant(50000);     // → "50 000"

// Validation
final isValid = NumberFormatter.isValidMontant("50 000");   // → true
final isValid2 = NumberFormatter.isValidMontant("abc");     // → false
```

**Fonctionnalités Clés** :

- 🔢 Accepte les espaces : "50 000" → 50000
- ✅ Montants positifs uniquement (pas de négatifs)
- 🎯 Validation robuste avec regex
- 📊 Formatting avec séparateurs d'espaces

---

## 📱 Écrans Principaux

### 🔐 Authentification

- **Écran de Connexion**
  - Formulaire de connexion sécurisée
  - Validation des identifiants
  - Gestion des erreurs de connexion
  - Lien vers inscription

- **Écran d'Enregistrement**
  - Création de nouveaux comptes
  - Validation des mots de passe
  - Confirmation des données
  - Retour à la connexion

### 🏠 Accueil (Home)

- Deux tables côte à côte : "En cours" et "À venir"
- ⚡ Bouton de rafraîchissement flottant
- 📊 Affichage dynamique avec filtrage par statut
- 🔄 Charge automatiquement tous les statuts
- **Champs affichés** : Date, Nom traitement, État, Axe

### 📋 Gestion des Contrats

- 📑 Liste des contrats avec filtrage par client
- 🔍 Détails complets d'un contrat :
  - Numéro contrat (#ID)
  - Durée totale et durée restante
  - Date début/fin (fin masquée si indéterminée)
  - Traitements associés
- ➕ **Formulaire de création multi-étapes** :
  - Sélection du client
  - Sélection multiple des traitements
  - Configuration des dates
  - Revue et confirmation
- 📊 Résumé : nombre de clients, contrats et traitements

### 💰 Factures

- 🔍 **Onglet de Recherche Moderne**
  - Filtrage par client
  - Filtrage par traitement
  - Recherche par date
- 📊 **Groupement Intelligent**
  - Cartes groupées par client-traitement
  - Affichage du montant total, payé et non payé
  - État visuel des paiements
- ✏️ **Modification de Prix**
  - Dialog avec ancien prix (lecture seule) et nouveau prix
  - Validation : montants positifs uniquement
  - Application en cascade : change le prix et les suivantes du même traitement
- 📋 **Détails des Factures**
  - Liste triée par date décroissante (récentes en premier)
  - Affichage du montant et de l'état

### 📅 Planning

- 🗓️ Calendrier interactif avec `table_calendar`
- 📍 Génération automatique des dates de planning
- 🔄 Filtrage par statut (À venir, En cours, Effectué)
- 🔄 Bouton de rafraîchissement flottant
- 📊 Vue détaillée des événements planifiés

### 📊 Historique

- 📖 Affichage complet de tous les historiques
- 🔄 Tri par date décroissante (récentes en premier)
- 📝 Détails des modifications :
  - Type de modification
  - Ancien et nouveau montants
  - Date de changement
  - Utilisateur responsable
- 🔍 Recherche et filtrage par client/traitement

### 📬 Remarques & Signalements

- ➕ Ajout de remarques sur les traitements
- 🚩 Signalement de problèmes
- 💬 Gestion des commentaires
- 🔔 Suivi des signalements

### 📤 Export de Données

- 📊 **Export en Excel**
  - Export des factures complètes
  - Formatting professionnel
  - Support de multiples formats
- 📋 **Rapports**
  - Statistiques de gestion
  - Historique des modifications
  - État des factures par client

### 🔧 Paramètres

- ⚙️ Configuration générale
- 🗄️ Gestion de la base de données
- 🎨 Préférences d'affichage
- 📱 Paramètres des notifications
- 🔔 Configuration des alertes

### ℹ️ À Propos

- 📋 Informations de l'application
- 🔢 Numéro de version
- 👨‍💻 Informations de l'auteur
- 📚 Liens utiles
- ⚖️ Licences et crédits

---

## 🐛 Bugs Fixes Récents

### Version 2.1.1 - Windows Compatibility & Stability (20 janvier 2026)

| Bug | Cause | Solution | Statut |
|-----|-------|----------|--------|
| **Client page infinite loading sur Windows** | MySQL strict mode + GROUP BY complexe avec COUNT/DISTINCT | Simplifié avec `SELECT DISTINCT` + `WHERE` clause au lieu de `HAVING` + subquery pour treatment_count | ✅ Résolu |
| **Contract count showing 0 on first load** | `_contratCount` variable updated in FutureBuilder without `setState()` call | Added `setState()` callback in FutureBuilder `onData` to trigger UI rebuild | ✅ Résolu |
| **Treatment count lost after query simplification** | Suppression du `GROUP BY` pattern a cassé le comptage | Restored using subquery approach: `SELECT COUNT(DISTINCT t.traitement_id) WHERE co.client_id = c.client_id` | ✅ Résolu |
| Comptage faux des traitements (20 au lieu de 2) | `COUNT(p.planning_id)` avec Planning JOIN créait des doublons | Utilisé `COUNT(DISTINCT t.traitement_id)` sans Planning JOIN | ✅ Hérité v2.0.0 |
| Nouveaux contrats invisibles après création | `loadContrats()` non appelé après insertion | Ajout de `await loadContrats()` après création | ✅ Hérité v2.0.0 |
| Statuts incomplets dans le planning | Filtre SQL `AND pd.statut = 'À venir'` cachait les autres | Suppression du filtre dans SQL, filtrage en Flutter | ✅ Hérité v2.0.0 |

### SQL Optimization Pattern (Windows Compatible)


**Pattern (Windows Safe)** :
```sql
SELECT DISTINCT c.client_id, 
  COALESCE((
    SELECT COUNT(DISTINCT t.traitement_id)
    FROM Traitement t
    INNER JOIN Contrat co2 ON t.contrat_id = co2.contrat_id
    WHERE co2.client_id = c.client_id
  ), 0) as treatment_count
FROM Client c
LEFT JOIN Contrat co ON c.client_id = co.client_id
WHERE co.contrat_id IS NOT NULL
```

**Avantages** ✨:

- `SELECT DISTINCT` universellement supporté (tous les versions MySQL)
- `WHERE` clause au lieu de `HAVING` (plus robuste, moins d'erreurs)
- Subquery pour COUNT (évite les problèmes GROUP BY + strict mode)
- Compatible avec MySQL 5.7, 8.0, MariaDB 10.x+

### Enhancements v2.1.1 ✨

**About Screen Improvements** :

- ✅ Build number display: `20260120-001`
- ✅ Last update date: `20 janvier 2026`
- ✅ Support email: `support@planificator.app` (clickable mailto)
- ✅ Changelog link: Direct access to GitHub releases
- ✅ Info box with reusable `_buildInfoRow()` component

**Code Quality** :

- ✅ Improved logging with platform-specific formatting
- ✅ Enhanced error handling in repositories
- ✅ Windows-specific SQL patterns tested and validated
- ✅ UI state management with proper `setState()` callbacks

---

## 🚀 Démarrage Rapide

### Prérequis

- **Flutter SDK**: ≥3.1.0 ([Installation](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: ≥3.1.0 (inclus avec Flutter)
- **MySQL Server**: ≥8.0 pour la base de données
- **Git**: Pour cloner le dépôt
- **IDE**: Android Studio, VS Code ou IntelliJ IDEA

### Installation

#### 1️⃣ Cloner le dépôt

```bash
git clone https://github.com/josoavj/PlanificatorFinal.git
cd planificator
```

#### 2️⃣ Installer les dépendances

```bash
flutter pub get
```

#### 3️⃣ Configuration de la Base de Données

Importer le schéma dans MySQL :
```bash
# Importer le schéma principal
mysql -u root -p < scripts/Planificator.sql

# Importer les migrations
mysql -u root -p < scripts/Migration.sql
```

#### 4️⃣ Vérifier l'installation

```bash
flutter doctor
flutter analyze
```

#### 5️⃣ Lancer l'application

```bash
# Sur Linux (desktop)
flutter run -d linux

# Sur Windows
flutter run -d windows

# Sur iOS (macOS uniquement)
flutter run -d ios
```

### Comptes de Test

Utilisez ces identifiants si disponibles dans votre base de données :

| Type | Description |
|------|-------------|
| Client Test | Créez un client pour tester |
| Contrat Test | Créez un contrat avec 2-3 traitements |
| Factures Auto | Générées automatiquement pour chaque traitement |

---

## 📦 Dépendances

### Dépendances Principales

```yaml
# Framework & SDK
flutter:
  sdk: flutter
  version: >=3.1.0

# State management
provider: ^6.1.5+1

# Database
mysql1: ^0.20.0
path_provider: ^2.1.0

# UI & Design
cupertino_icons: ^1.0.0
table_calendar: ^3.2.0

# Utilities
intl: ^0.20.2              # Internationalisation (fr_FR)
logger: ^2.6.2             # Logging avec emojis
shared_preferences: ^2.2.0 # Stockage local
http: ^1.6.0              # Requêtes HTTP
collection: ^1.19.1       # Utilitaires collection

# Sécurité & Cryptographie
crypto: ^3.0.7            # Utilitaires cryptographiques
bcrypt: ^1.1.3            # Hash des mots de passe

# Export & Fichiers
excel: ^2.1.0             # Création de fichiers Excel
path: ^1.8.0              # Gestion des chemins
syncfusion_flutter_xlsio: ^29.2.11  # Création avancée Excel
url_launcher: ^6.2.0      # Ouverture d'URLs

# Notifications & Calendrier
flutter_local_notifications: ^17.1.0  # Notifications locales
timezone: ^0.9.2                      # Gestion des fuseaux horaires
workmanager: ^0.5.1                   # Tâches planifiées en arrière-plan
```

### Versions Compatibles

```yaml
environment:
  sdk: ^3.10.4

Flutter: ≥3.1.0
Dart: ≥3.1.0
MySQL: ≥8.0
```

### Dev Dependencies

```yaml
flutter_lints: ^2.0.0
```

---

## � Fonctionnalités Avancées

### 💾 Gestion Avancée de la Base de Données

- **MySQL Connection Pooling**
  - Connexions persistantes optimisées
  - Gestion automatique des erreurs de connexion
  - Reconnexion automatique en cas de déconnexion

- **Requêtes Optimisées**
  - SQL joins optimisés pour les performances
  - Indexation efficace des clés primaires et étrangères
  - Caching intelligent des données
  - Pagination pour les grandes listes

### 📊 Utilitaires Avancés

- **NumberFormatter avec Validation**
  - Parsing intelligent des montants (accepte les espaces)
  - Formatting avec séparateurs
  - Validation robuste avec regex
  - Montants positifs uniquement

- **Localisation Complète**
  - Support multilingue (français par défaut)
  - Dates formatées selon la locale
  - Nombres et montants localisés
  - Support des fuseau horaires

### 🔐 Sécurité Renforcée

- **Authentification**
  - Hash bcrypt pour les mots de passe
  - Sessions utilisateur persistantes
  - Protection contre les attaques par injection SQL
  
- **Audit & Conformité**
  - Piste d'audit complète (`Historique_prix`)
  - Traçabilité de toutes les modifications
  - Timestamps de chaque action
  - Identification de l'utilisateur

### 📱 Notifications Intelligentes

- **Notifications Locales**
  - Alertes planifiées pour les traitements
  - Rappels des factures impayées
  - Support des timezones
  - Gestion en arrière-plan avec workmanager

### 📊 Rapports & Analytics

- **Génération de Rapports**
  - Export Excel professionnel
  - Statistiques de gestion
  - Analyse des factures par client
  - Historique des modifications

---

## 📊 État du Projet

| Composant | État | Completude |
|-----------|------|-----------|
| Authentification | ✅ Stable | 100% |
| Gestion Clients | ✅ Stable | 100% |
| Gestion Contrats | ✅ Stable | 100% |
| Gestion Factures | ✅ Stable | 100% |
| Planning | ✅ Stable | 100% |
| Historique | ✅ Stable | 100% |
| Remarques & Signalements | ✅ Stable | 100% |
| Export de Données | ✅ Stable | 100% |
| Paramètres | ✅ Stable | 100% |
| Notifications | ✅ Stable | 100% |
| UI/UX | ✅ Stable | 95% |
| Base de Données | ✅ Optimisée | 100% |
| Sécurité | ✅ Renforcée | 100% |
| Tests | 🚧 À faire | 20% |
| Documentation | ✅ À jour | 95% |

---

## 👨‍💻 Auteur

**Josoa** - Développeur principal

- 📧 Email: josoavonjiniaina13@gmail.com 
- 🐙 GitHub: [@josoavj](https://github.com/josoavj)

**Josoa** - Développeur Back-end

- 📧 Email: contact@planificator.app
- 🐙 GitHub: [@josoavj](https://github.com/josoavj)

---

## 📄 Licence

Ce projet est sous licence **MIT**.

## 🙏 Remerciements

- [Flutter Team](https://flutter.dev) pour le framework remarquable
- [MySQL Community](https://www.mysql.com) pour la base de données
- Tous les testeurs et utilisateurs

---

## 📚 Ressources Additionnelles

- 📖 [Architecture Overview](./docs/ARCHITECTURE.md)
- 🗄️ [Database Schema](./scripts/Planificator.sql)
- 🐛 [Guide de Signalement de Bugs](./docs/BUG_REPORT.md)
- 📋 [Changelog Complet](./docs/CHANGELOG.md)

---

<div align="center">

**⭐ Si ce projet vous a été utile, n'hésitez pas à nous laisser une étoile!**

<a href="https://github.com/josoavj/PlanificatorFinal">
  <img src="https://img.shields.io/github/stars/josoavj/PlanificatorFinal?style=social" alt="Stars">
</a>

Made with ❤️ by Josoa

**Dernière mise à jour** : 20 janvier 2026

---

## 🎯 Roadmap Futures

- 🧪 **Tests Unitaires & Intégration** : Suite de tests complète
- 📈 **Dashboard Analytique** : Graphiques et statistiques avancées
- 🔔 **Push Notifications** : Notifications cloud améliorées
- 🌙 **Mode Sombre** : Support complet du thème sombre
- 🗺️ **Géolocalisation** : Intégration GPS pour les interventions
- 🤖 **Machine Learning** : Prédictions et recommandations

---

## 💡 Contribution

Les contributions sont bienvenues! Pour contribuer :

1. Fork le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

Veuillez vous assurer que votre code suit les guidelines du projet et que tous les tests passent.

---

## 🐛 Signaler un Bug

Si vous trouvez un bug, veuillez ouvrir une [issue GitHub](https://github.com/josoavj/PlanificatorFinal/issues) avec :

- Description détaillée du bug
- Étapes pour reproduire le problème
- Version de l'application
- Logs/stack traces si disponible
- Suggestions de fix si vous en avez

</div>
