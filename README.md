<p align="center">
  <img src="https://github.com/josoavj/PlanificatorFinal/blob/main/assets/logo/Logo-Planificator.ico" alt="LevelMind Logo" width="150"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=for-the-badge" alt="Desktop Platforms">
</p>

<h1 align="center">📊 Planificator Desktop</h1>

<p align="center">
  <strong>Plateforme Industrielle de Gestion pour Environnements Desktop</strong>
</p>

<p align="center">
  Organisez efficacement vos interventions, suivez vos clients et gérez votre facturation avec une performance de niveau production.
</p>

---

## 📋 Table des Matières

- [📖 À Propos](#-à-propos)
- [🚀 Architecture Industrielle (v2.1.1)](#-architecture-industrielle-v211)
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

**Planificator** est une plateforme Flutter native pour Desktop (Windows, macOS, Linux) conçue pour la gestion intensive des contrats et de la facturation. En version **2.1.1**, elle a été entièrement industrialisée pour offrir une fluidité instantanée et une sécurité renforcée.

---

## 🚀 Architecture Industrielle (v2.1.1)

La version actuelle intègre des optimisations majeures pour la performance et la maintenance de la plateforme :

- **⚡ Smart Cache System** : Cache SQL global éliminant les latences réseau sur les requêtes répétées (affichage instantané).
- **🗄️ SQL Centralization** : 100% des scripts SQL centralisés dans `lib/core/sql_queries.dart` pour une maintenance simplifiée.
- **🔌 Advanced Pooling** : Pool de connexions MySQL réutilisables (5-10 flux), supprimant les délais d'authentification à chaque action.
- **🛡️ Log Sanitization** : Masquage automatique des données sensibles (mots de passe, hashs) dans les journaux de la plateforme.
- **🧵 Hybrid Isolates** : Utilisation intelligente des Isolates Dart pour les calculs lourds sans surcharger les petites requêtes.

---

## ✨ Fonctionnalités

### 🔐 Sécurité & Authentification
- Connexion sécurisée avec hash **BCrypt**.
- Chiffrement des identifiants base de données via **Secure Storage** (Keystore/Keychain).
- Protection contre les injections SQL via requêtes paramétrées systématiques.

### 📋 Gestion des Clients & Contrats
- Cycle de vie complet : Création, édition, catégories et axes géographiques.
- Contrats déterminés et indéterminés avec calcul automatique de durée.
- Gestion multi-traitements par contrat.

### 💰 Facturation Avancée
- Modification de prix **en cascade** sur les interventions futures.
- Suivi des états de paiement (Payé, À venir, En retard).
- Historique complet des modifications de tarifs.

### 📅 Planning & Signalements
- Calendrier interactif et prévisions mensuelles.
- Système de signalement pour décaler ou avancer des interventions.
- Logique complexe de **redondance** (décalage intelligent des dates futures).

---

## 🏗️ Architecture Logicielle

```
lib/
├── core/           # SQL centralisé, thèmes et constantes
├── models/         # Modèles de données (Client, Facture, Contrat...)
├── repositories/   # Logique métier et accès données (Pattern Repo)
├── services/       # Moteur de base de données, Cache, Logging
├── screens/        # Interface utilisateur (UI)
└── utils/          # Helpers (Dates, Formattage, Excel)
```

---

## 💾 Base de Données

### Relations Principales
- **Client** ↔ **Contrat** ↔ **Traitement** ↔ **Planning** ↔ **Facture**.
- Table **Historique** pour l'audit de toutes les actions.
- Table **Remarque** pour les retours d'interventions.

---

## 🔧 Utilitaires

- **ExcelService** : Génération professionnelle de rapports de facturation et de planning.
- **LoggingService** : Système de log rotatif avec persistance sur fichier.
- **NotificationService** : Rappels locaux pour les interventions du lendemain.

---

## 🚀 Démarrage Rapide

### Installation
1. Cloner le dépôt.
2. `flutter pub get`.
3. Configurer votre serveur MySQL (Version ≥ 8.0).
4. Importer `scripts/Planificator.sql`.
5. Lancer la plateforme : `flutter run`.

### Configuration Initiale
Au premier lancement, la plateforme vous demandera les identifiants de votre base de données. Ces identifiants seront stockés de manière chiffrée sur votre appareil.

---

## 📊 État du Projet

| Composant | État | Completude |
|-----------|------|-----------|
| Architecture | ✅ Industrialisée | 100% |
| Performance | ✅ Optimisée | 100% |
| Sécurité | ✅ Renforcée | 100% |
| UI/UX | ✅ Stable | 95% |
| Base de Données | ✅ Indexée | 100% |

---

## 🔒 Sécurité

La sécurité est une priorité majeure de la plateforme. Pour plus de détails sur les mesures implémentées (chiffrement, protection contre les injections, etc.), veuillez consulter le fichier [SECURITY.md](./SECURITY.md).

## 👨‍💻 Auteur

**Josoa** - Développeur principal
- 📧 Email: contact@planificator.app
- 🐙 GitHub: [@josoavj](https://github.com/josoavj)

## 📄 Licence
Ce projet est sous licence **MIT**.

**Dernière mise à jour** : 1er Février 2026
