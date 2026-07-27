<p align="center">
  <img src="https://github.com/josoavj/PlanificatorFinal/blob/main/assets/logo/Logo-Planificator.ico" alt="Planificator Logo" width="150"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=for-the-badge" alt="Desktop Platforms">
  <img src="https://img.shields.io/badge/Version-2.1.1-green?style=for-the-badge" alt="Version">
</p>

<h1 align="center">Planificator</h1>

<p align="center">
  <strong>Plateforme de Gestion de planning et services</strong>
</p>

<p align="center">
  Organisez efficacement vos interventions, suivez vos clients et gérez votre facturation avec une fiabilité de niveau production.
</p>

---

## Table des Matières

- [À Propos](#à-propos)
- [Panoramic Intelligence (v2.1.1)](#panoramic-intelligence-v211)
- [Modernisation et Flexibilité (v2.2.0)](#modernisation-et-flexibilité-v220)
- [Architecture Industrielle](#architecture-industrielle)
- [Fonctionnalités](#fonctionnalités)
- [Architecture Logicielle](#architecture-logicielle)
- [Base de Données](#base-de-données)
- [Utilitaires](#utilitaires)
- [Démarrage Rapide](#démarrage-rapide)
- [État du Projet](#état-du-projet)
- [Sécurité](#sécurité)
- [Tests Automatisés](#tests-automatisés)
- [Contribution](#contribution)
- [Auteur](#auteur)
- [Licence](#licence)

---

## À Propos

**Planificator** est une plateforme Flutter native pour Desktop (Windows, macOS, Linux) conçue pour la gestion intensive des contrats et de la facturation. En version **2.1.1**, elle introduit des capacités d'audit approfondies et une ergonomie panoramique optimisée pour les flux financiers.

---

## Panoramic Intelligence (v2.1.1)

La version **2.1.1** marque un tournant dans la maturité de la plateforme avec un focus sur la traçabilité et la performance :

- **Expérience Panoramique (Zéro Scroll)** : Refonte des dialogues Clients et Contrats en mode 2 colonnes (950px), offrant une visibilité immédiate sur 100% des données sans défilement.
- **Journal de Bord 360°** : Nouveau module de consultation d'historique retraçant toute la vie d'une intervention (Planning initial, Signalements, Facturation et Historique des tarifs).
- **Moteur de Tri Intelligent** : Algorithme centralisé harmonisant l'affichage dans toute l'app (Passé : plus récent en haut | Futur : plus proche en haut).
- **Optimisation Massive des Prix** : Mise à jour des tarifs en cascade ultra-rapide via SQL direct, éliminant les latences réseau.
- **Bouclier de Tests Infaillible** : Suite de tests de régression couvrant l'intégralité de la logique métier et des transactions financières.

---

## Modernisation et Flexibilité (v2.2.0)

La version actuelle apporte des améliorations majeures pour l'expérience utilisateur et la gestion métier :

- **Facturation Groupée** : Possibilité de fusionner plusieurs services (ex: Dératisation + Désinfection) dans une facture unique lorsqu'ils tombent le même jour.
- **Planning Avancé** : Support des fréquences hebdomadaires (1x, 2x ou 3x par semaine) et bimestrielles, gérant automatiquement les mois à 5 semaines.
- **Respect du Calendrier Malgache** : Prise en compte automatique des jours fériés (incluant le 29 Mars et le 1er Mai) avec décalage au prochain jour ouvrable.
- **Sécurisation Critique** : Accès aux réglages de la base de données protégé par une vérification du mot de passe administrateur.
- **Formateurs Intelligents** : Saisie assistée et formatage automatique pour le NIF, le STAT, les numéros de téléphone (Madagascar) et les montants financiers.

---

## Architecture Industrielle

- **Smart Cache System** : Cache SQL global éliminant les latences réseau.
- **SQL Centralization** : Scripts SQL centralisés dans `lib/core/sql_queries.dart`.
- **Advanced Pooling** : Pool de connexions MySQL réutilisables, supprimant les délais d'authentification.
- **Log Sanitization** : Masquage automatique des données sensibles (mots de passe, hashs).
- **Hybrid Isolates** : Utilisation intelligente des Isolates Dart pour les calculs lourds.

---

## Fonctionnalités

### Sécurité et Authentification
- Connexion sécurisée avec hash **BCrypt**.
- Chiffrement des identifiants base de données via **Secure Storage**.
- Protection contre les injections SQL via requêtes paramétrées.
- Validation d'identité pour les actions critiques (Config DB).

### Gestion des Clients et Contrats
- Cycle de vie complet : Création, édition, catégories et axes géographiques.
- Formulaire adaptatif selon le type de client (Particulier, Organisation, Société).
- Contrats déterminés et indéterminés avec calcul automatique de durée.
- Dates de début personnalisables par service au sein d'un même contrat.

### Facturation Avancée
- Modification de prix en cascade protégée par transaction.
- Regroupement intelligent des factures par date de passage.
- Suivi des états de paiement (Payé, À venir, Non payé).
- Historique complet des modifications de tarifs.

### Planning et Signalements
- Calendrier interactif et prévisions dynamiques.
- Système de signalement pour décaler ou avancer des interventions.
- Algorithme de répartition équilibré pour les passages multiples par semaine.

---

## Architecture Logicielle

```
lib/
├── core/           # SQL centralisé, thèmes et constantes
├── models/         # Modèles de données robustes
├── repositories/   # Logique métier et transactions SQL
├── services/       # Moteur de base de données, Pool et Cache
├── screens/        # Interface utilisateur (UI)
└── utils/          # Helpers (Dates, Formattage, NIF/STAT, Phone)
```

---

## Base de Données

### Relations Principales
- **Client** ↔ **Contrat** ↔ **Traitement** ↔ **Planning** ↔ **PlanningDetails**.
- **PlanningDetails** ↔ **Facture** (Relation N-1 pour le support groupé).
- Table **Historique** technique pour le suivi des interventions.
- Table **Remarque** pour les retours terrain.

---

## Utilitaires

- **NifStatFormatter** : Gestion des standards fiscaux malgaches.
- **PhoneFormatter** : Formatage des contacts (03X XX XXX XX).
- **NumberFormatter** : Saisie et affichage des prix avec séparateurs de milliers.
- **ExcelService** : Génération de rapports professionnels.
- **LoggingService** : Système de log rotatif persistant.

---

## Démarrage Rapide

### Installation
1. Cloner le dépôt.
2. `flutter pub get`.
3. Configurer votre serveur MySQL (Version ≥ 8.0).
4. Importer `scripts/Planificator.sql`.
5. Lancer : `flutter run`.

---

## État du Projet

| Composant | État | Completude |
|-----------|------|-----------|
| Architecture | Industrialisée | 100% |
| Intégrité DB | Transactionnelle | 100% |
| Sécurité | Renforcée / Verrouillée | 100% |
| UI/UX | Moderne / Animée | 100% |

---

## Sécurité

La sécurité est une priorité majeure. Consultez le fichier [SECURITY.md](./SECURITY.md) pour les détails techniques.

## Tests Automatisés

La plateforme dispose d'une suite de tests complète couvrant la logique métier, financière et calendaire.
Pour plus d'informations sur la couverture des tests, consultez le fichier [TESTS.md](./TESTS.md).

```bash
flutter test
```

## Contribution

Si vous souhaitez contribuer au projet, veuillez lire le guide détaillé [CONTRIBUTING.md](./CONTRIBUTING.md) pour connaître les standards de code et de sécurité.

## Auteur

**Josoa** - Développeur principal
- 📧 Email: contact@planificator.app
- 🐙 GitHub: [@josoavj](https://github.com/josoavj)

## Licence
Ce projet est sous licence **MIT**.

**Dernière mise à jour** : 22 Juillet 2026
