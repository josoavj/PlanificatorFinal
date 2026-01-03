<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%3E%3D3.1.0-blue?style=flat-square" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-%3E%3D3.1.0-blue?style=flat-square" alt="Dart Version">
  <img src="https://img.shields.io/badge/MySQL-8.0-orange?style=flat-square" alt="MySQL Version">
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=flat-square" alt="Current Version">
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
- [🏗️ Architecture](#-architecture)
- [💾 Base de Données](#-base-de-données)
- [🔧 Utilitaires](#-utilitaires)
- [📱 Écrans Principaux](#-écrans-principaux)
- [🐛 Bugs Fixes Récents](#-bugs-fixes-récents)
- [🚀 Démarrage Rapide](#-démarrage-rapide)
- [📦 Dépendances](#-dépendances)
- [👨‍💻 Auteur](#-auteur)
- [📄 Licence](#-licence)

---

## 📖 À Propos

**Planificator** est une application Flutter moderne et intuitive conçue pour révolutionner la gestion des contrats et de la facturation. Actuellement en **version 1.0.0 (Stable)**, elle offre une solution complète pour :

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

- **📋 Gestion des Clients**
  - Création, édition et suppression de clients
  - Support des catégories (Particulier, Organisation, Société)
  - Gestion complète : NIF, STAT, Adresse, Téléphone, Email
  - Classification par axe géographique (Nord, Sud, Est, Ouest, Centre)
  - Comptage précis des traitements par client

- **📄 Gestion des Contrats**
  - Création de contrats avec sélection multiple de traitements
  - Support des contrats déterminés (date fin) et indéterminés
  - Affichage complet : numéro, référence, dates, durée
  - Gestion des traitements associés avec détails
  - Rechargement automatique après création

- **💰 Gestion des Factures (Nouvel Écran)**
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

- **📅 Gestion du Planning**
  - Calendrier interactif avec `table_calendar`
  - Affichage des traitements prévus et en cours
  - Filtrage par état (À venir, En cours, Effectué)
  - Génération automatique des dates de planning
  - Bouton de rafraîchissement flottant

- **🏠 Tableau de Bord (Home)**
  - Vue "En cours" : traitements du mois actuel
  - Vue "À venir" : traitements futurs (sans redondance 1 mois)
  - Affichage : dates, noms, états et axes
  - **Bouton de rafraîchissement** pour mise à jour en temps réel
  - Charge tous les statuts (pas seulement "À venir")

- **📊 Historique**
  - Suivi complet de toutes les actions
  - Affichage des modifications de prix avec ancien/nouveau montant
  - Piste d'audit pour conformité

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

### 💰 Factures (Nouvel Écran)
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

---

## 🐛 Bugs Fixes Récents

| Bug | Cause | Solution |
|-----|-------|----------|
| Comptage faux des traitements (20 au lieu de 2) | `COUNT(p.planning_id)` avec Planning JOIN créait des doublons | Utilisé `COUNT(DISTINCT t.traitement_id)` sans Planning JOIN |
| Nouveaux contrats invisibles après création | `loadContrats()` non appelé après insertion | Ajout de `await loadContrats()` après création |
| Statuts incomplets dans le planning | Filtre SQL `AND pd.statut = 'À venir'` cachait les autres | Suppression du filtre dans SQL, filtrage en Flutter |
| Erreur colonne `ancien_montant` inconnue | Noms de colonnes français au lieu des vrais noms | Utilisation de `old_amount`, `new_amount`, `change_date` |
| Montants négatifs dans factures | Regex `r'[^\d-]'` acceptait `-` n'importe où | Regex `r'[^\d]'` + validation `if (newPrix <= 0)` |
| Factures non triées par date | Aucun tri appliqué dans la vue détail | Sort par `dateTraitement DESC` |

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

# Sur Android ou Windows
flutter run

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
# State management
provider: ^6.0.0

# Database
mysql1: ^0.20.0

# UI & Design
flutter:
  sdk: flutter
cupertino_icons: ^1.0.0

# Utilities
intl: ^0.18.0              # Internationalisation (fr_FR)
logger: ^1.3.0             # Logging avec emojis
table_calendar: ^3.0.0     # Calendrier interactif
shared_preferences: ^2.1.0 # Stockage local
```

### Dev Dependencies

```yaml
flutter_lints: ^2.0.0
```

---

## 📊 État du Projet

| Composant | État | Completude |
|-----------|------|-----------|
| Gestion Clients | ✅ Stable | 100% |
| Gestion Contrats | ✅ Stable | 100% |
| Gestion Factures | ✅ Stable | 100% |
| Planning | ✅ Stable | 100% |
| Historique | ✅ Stable | 100% |
| UI/UX | ✅ Stable | 95% |
| Base de Données | ✅ Optimisée | 100% |
| Tests | 🚧 À faire | 20% |
| Documentation | ✅ À jour | 90% |

---

## 🔄 Stratégie de Commit

Tous les changements ont été committés de manière logique et séquentielle :

1. ✅ Ajout du bouton de rafraîchissement (FAB) sur HomeScreen
2. ✅ Chargement de tous les statuts du planning
3. ✅ Rechargement des contrats après création
4. ✅ Création de l'utilitaire NumberFormatter
5. ✅ Nouvel écran Facture avec recherche et groupement
6. ✅ Implémentation de la modification de prix en cascade
7. ✅ Correction du comptage des traitements (COUNT DISTINCT)
8. ✅ Ajout du parsing DateTime flexible
9. ✅ Mises à jour mineures et optimisations

---

## 👨‍💻 Auteur

**Josoa** - Développeur principal

- 📧 Email: contact@planificator.app
- 🐙 GitHub: [@josoavj](https://github.com/josoavj)

---

## 📄 Licence

Ce projet est sous licence **MIT**.

```
MIT License

Copyright (c) 2026 Planificator Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

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

**Dernière mise à jour** : 3 janvier 2026

</div>
