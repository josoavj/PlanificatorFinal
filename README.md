<p align="center">
  <img src="https://github.com/josoavj/PlanificatorFinal/blob/main/assets/logo/Logo-Planificator.ico" alt="Planificator Logo" width="150"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=for-the-badge" alt="Desktop Platforms">
  <img src="https://img.shields.io/badge/Version-2.1.1-green?style=for-the-badge" alt="Version">
</p>

<h1 align="center">📊 Planificator Desktop</h1>

<p align="center">
  <strong>Plateforme Industrielle de Gestion pour Environnements Desktop</strong>
</p>

<p align="center">
  Organisez efficacement vos interventions, suivez vos clients et gérez votre facturation avec une fiabilité de niveau production.
</p>

---

## 📋 Table des Matières

- [📖 À Propos](#-à-propos)
- [💎 Fiabilité Financière (v2.1.1)](#-fiabilité-financière-v211)
- [🚀 Architecture Industrielle](#-architecture-industrielle)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🏗️ Architecture Logicielle](#-architecture-logicielle)
- [💾 Base de Données](#-base-de-données)
- [🔧 Utilitaires](#-utilitaires)
- [🚀 Démarrage Rapide](#-démarrage-rapide)
- [📊 État du Projet](#-état-du-projet)
- [🔒 Sécurité](#-sécurité)
- [👨‍💻 Auteur](#-auteur)
- [📄 Licence](#-licence)

---

## 📖 À Propos

**Planificator** est une plateforme Flutter native pour Desktop (Windows, macOS, Linux) conçue pour la gestion intensive des contrats et de la facturation. En version **2.1.1**, elle met l'accent sur l'intégrité absolue des données financières et la fluidité de navigation.

---

## 💎 Fiabilité Financière (v2.1.1)

La version actuelle introduit des garanties SGBDR essentielles pour la gestion comptable :

- **🛡️ Atomic Transactions** : Utilisation systématique de `START TRANSACTION / COMMIT` pour les opérations multi-tables. Soit tout est enregistré, soit rien ne l'est, évitant toute corruption de données.
- **📈 Scalable Historique** : Système de **Lazy Loading** (pagination) permettant de consulter des millions d'interventions sans ralentissement de l'interface.
- **🎯 Axe/Région Automatisé** : Attribution intelligente de la zone géographique aux factures basée sur la fiche client, fiabilisant les rapports statistiques.
- **🏗️ Robust Parsing** : Protection contre les données corrompues via un système de parsing résilient, garantissant la stabilité de l'application en environnement réel.

---

## 🚀 Architecture Industrielle

- **⚡ Smart Cache System** : Cache SQL global éliminant les latences réseau.
- **🗄️ SQL Centralization** : Scripts SQL centralisés dans `lib/core/sql_queries.dart`.
- **🔌 Advanced Pooling** : Pool de connexions MySQL réutilisables, supprimant les délais d'authentification.
- **🛡️ Log Sanitization** : Masquage automatique des données sensibles (mots de passe, hashs).
- **🧵 Hybrid Isolates** : Utilisation intelligente des Isolates Dart pour les calculs lourds.

---

## ✨ Fonctionnalités

### 🔐 Sécurité & Authentification
- Connexion sécurisée avec hash **BCrypt**.
- Chiffrement des identifiants base de données via **Secure Storage**.
- Protection contre les injections SQL via requêtes paramétrées.

### 📋 Gestion des Clients & Contrats
- Cycle de vie complet : Création, édition, catégories et axes géographiques.
- Contrats déterminés et indéterminés avec calcul automatique de durée.
- Gestion multi-traitements par contrat.

### 💰 Facturation Avancée
- Modification de prix **en cascade** protégée par transaction.
- Suivi des états de paiement (Payé, À venir, Non payé).
- Historique complet des modifications de tarifs.

### 📅 Planning & Signalements
- Calendrier interactif et prévisions mensuelles.
- Système de signalement pour décaler ou avancer des interventions.

---

## 🏗️ Architecture Logicielle

```
lib/
├── core/           # SQL centralisé, thèmes et constantes
├── models/         # Modèles de données robustes
├── repositories/   # Logique métier et transactions SQL
├── services/       # Moteur de base de données, Pool et Cache
├── screens/        # Interface utilisateur (UI)
└── utils/          # Helpers (Dates, Formattage, Excel)
```

---

## 💾 Base de Données

### Relations Principales
- **Client** ↔ **Contrat** ↔ **Traitement** ↔ **Planning** ↔ **Facture**.
- Table **Historique** technique pour le suivi des interventions.
- Table **Remarque** pour les retours terrain.

---

## 🔧 Utilitaires

- **ExcelService** : Génération de rapports professionnels.
- **LoggingService** : Système de log rotatif persistant.
- **NotificationService** : Rappels locaux pour les interventions.

---

## 🚀 Démarrage Rapide

### Installation
1. Cloner le dépôt.
2. `flutter pub get`.
3. Configurer votre serveur MySQL (Version ≥ 8.0).
4. Importer `scripts/Planificator.sql`.
5. Lancer : `flutter run`.

---

## 📊 État du Projet

| Composant | État | Completude |
|-----------|------|-----------|
| Architecture | ✅ Industrialisée | 100% |
| Intégrité DB | ✅ Transactionnelle | 100% |
| Sécurité | ✅ Renforcée | 100% |
| UI/UX | ✅ Stable / Pagé | 100% |

---

## 🔒 Sécurité

La sécurité est une priorité majeure. Consultez le fichier [SECURITY.md](./SECURITY.md) pour les détails techniques.

## 👨‍💻 Auteur

**Josoa** - Développeur principal
- 📧 Email: contact@planificator.app
- 🐙 GitHub: [@josoavj](https://github.com/josoavj)

## 📄 Licence
Ce projet est sous licence **MIT**.

**Dernière mise à jour** : 25 Juin 2026
