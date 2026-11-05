<p align="center">
  <img src="https://github.com/josoavj/PlanificatorFinal/blob/main/assets/icons/icon.png" alt="Planificator Logo" width="150"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=for-the-badge" alt="Desktop Platforms">
  <img src="https://img.shields.io/badge/Version-2.1.1-green?style=for-the-badge" alt="Version">
</p>

<h1 align="center">Planificator</h1>

<p align="center">
  <strong>Plateforme de gestion de planning et de services</strong>
</p>

<p align="center">
  Organisez efficacement vos interventions, suivez vos clients et gérez votre facturation avec une fiabilité de niveau production.
</p>

---

## Table des Matières

- [À Propos](#à-propos)
- [Panoramic Intelligence (v2.1.1)](#panoramic-intelligence-v211)
- [Points techniques clés](#points-techniques-clés)
- [Fonctionnalités](#fonctionnalités)
- [Architecture Logicielle](#architecture-logicielle)
- [Base de Données](#base-de-données)
- [Utilitaires](#utilitaires)
- [Démarrage Rapide](#démarrage-rapide)
- [État du Projet](#état-du-projet)
- [Sécurité](#sécurité)
- [Tests Automatisés](#tests-automatisés)
- [Exploitation et déploiement](./docs/OPERATIONS.md)
- [Site de présentation](./presentation/index.html)
- [Contribution](#contribution)
- [Auteur](#auteur)
- [Licence](#licence)

---

## À Propos

**Planificator** est une plateforme Flutter native pour Desktop (Windows, macOS, Linux) conçue pour la gestion intensive des contrats et de la facturation. En version **2.1.1**, elle introduit des capacités d'audit approfondies et une ergonomie panoramique optimisée pour les flux financiers.

---

## Panoramic Intelligence (v2.1.1)

La version **2.1.1** marque un tournant dans la maturité de la plateforme, avec un focus sur la traçabilité et la performance, ainsi qu'une expérience utilisateur modernisée :

- **Expérience Panoramique (Zéro Scroll)** : refonte des dialogues Clients et Contrats en mode 2 colonnes, offrant une visibilité immédiate sur 100 % des données sans défilement.
- **Journal de Bord 360°** : nouveau module de consultation d'historique retraçant toute la vie d'une intervention (planning initial, signalements, facturation et historique des tarifs).
- **Moteur de Tri Intelligent** : algorithme centralisé harmonisant l'affichage dans toute l'application.
- **Optimisation Massive des Prix** : mise à jour des tarifs en cascade ultra-rapide via SQL direct, éliminant les latences réseau.
- **Renforcement des privilèges administrateurs** : contrôle d'accès renforcé sur les données sensibles, notamment pour la suppression de données et de comptes utilisateurs.
- **Suite de Tests de Régression** : tests couvrant l'ensemble de la logique métier et des transactions financières.
- **Interface Utilisateur** : refonte des affichages pour un visuel plus clair et mieux structuré, mettant en avant les informations utiles.
- **Facturation Groupée** : possibilité de fusionner plusieurs services dans une facture unique lorsqu'ils tombent le même jour, ou à cause des contraintes du contrat.
- **Planning Avancé** : prise en charge des fréquences hebdomadaires (1x, 2x ou 3x par semaine) et bimestrielles, avec gestion automatique des mois à 5 semaines.
- **Respect du Calendrier Malgache** : prise en compte automatique des jours fériés (dont le 29 mars et le 1er mai) avec décalage au prochain jour ouvrable.
- **Sécurisation Critique** : accès aux réglages de la base de données protégé par une vérification du mot de passe administrateur.
- **Formateurs Intelligents** : saisie assistée et formatage automatique du NIF, du STAT, des numéros de téléphone (Madagascar) et des montants financiers.

---

## Points techniques clés

- **Smart Cache System** : cache SQL global éliminant les latences réseau.
- **SQL par domaine** : requêtes regroupées par domaine dans `lib/core/database/sql/`.
- **Advanced Pooling** : pool de connexions MySQL réutilisables, supprimant les délais d'authentification.
- **Log Sanitization** : masquage automatique des données sensibles (mots de passe, hashs).
- **Hybrid Isolates** : utilisation des Isolates Dart pour les calculs et requêtes lourds.

---

## Fonctionnalités

### Sécurité et Authentification

- Connexion sécurisée avec hash **BCrypt**.
- Chiffrement des identifiants de base de données via **Secure Storage**.
- Protection contre les injections SQL via requêtes paramétrées.
- Validation d'identité pour les actions critiques (configuration de la base).
- Limitation des tentatives de connexion et récupération de compte.

### Gestion des Clients et Contrats

- Cycle de vie complet : création, édition, catégories et axes géographiques.
- Formulaire adaptatif selon le type de client (Particulier, Organisation, Société).
- Contrats déterminés et indéterminés avec calcul automatique de la durée.
- Dates de début personnalisables par service au sein d'un même contrat.

### Facturation Avancée

- Modification de prix en cascade protégée par transaction.
- Regroupement intelligent des factures par date de passage.
- Suivi des états de paiement (Payé, À venir, Non payé).
- Historique complet des modifications de tarifs.

### Planning et Signalements

- Calendrier interactif et prévisions dynamiques.
- Système de signalement pour décaler ou avancer des interventions.
- Algorithme de répartition équilibrée pour les passages multiples par semaine.

### Administration et Exploitation

- Catalogue de traitements dynamique (catégories, activation et masquage des types).
- Gestion des comptes utilisateurs et des rôles.
- Sauvegarde et restauration de la base de données.
- Migrations de schéma appliquées automatiquement.
- Notifications d'interventions et exports Excel.

---

## Architecture Logicielle

Architecture en couches **organisée par fonctionnalité** (feature-first). Les dépendances vont dans un seul sens, de l'interface vers les données.

```
┌──────────────────────────────────────────────────────┐
│ Présentation    Écrans et widgets                    │
├──────────────────────────────────────────────────────┤
│ État            Providers (ChangeNotifier)           │
├──────────────────────────────────────────────────────┤
│ Domaine         Règles métier pures (Dart)           │
├──────────────────────────────────────────────────────┤
│ Données         Repositories et modèles              │
├──────────────────────────────────────────────────────┤
│ Infrastructure  MySQL, cache, logs, sécurité         │
└──────────────────────────────────────────────────────┘
```

| Couche | Responsabilité |
| ------ | -------------- |
| **Présentation** | Affiche l'état et déclenche des actions. Aucun SQL ni calcul métier. |
| **État** | Lien entre l'écran et les données (MVVM avec `ChangeNotifier` et Provider). |
| **Domaine** | Règles métier en Dart pur : génération des dates de passage, jours fériés malgaches, répartition hebdomadaire, regroupement des factures, cascade de prix. Testable sans base de données. |
| **Données** | Les repositories sont l'unique accès aux données d'une entité et cachent leur provenance (MySQL, cache). Les modèles représentent les objets métier. |
| **Infrastructure** | Pool MySQL, isolates, migrations, cache de requêtes, journalisation, sauvegardes, limitation des tentatives de connexion. |

### Patterns utilisés

- **Repository** : isole l'accès aux données.
- **MVVM + Provider** : sépare la vue de son état.
- **Injection de dépendances** : repositories remplaçables par des faux dans les tests.
- **Observer** : mise à jour de l'interface via `notifyListeners()`.
- **Transaction** : opérations multi-tables atomiques (cascade de prix, facturation groupée).

### Principes

- Dépendances **unidirectionnelles** : jamais d'une couche basse vers une couche haute.
- Fonctionnalités **indépendantes** : le code partagé va dans `core/` ou `shared/`.
- Domaine **isolé** : aucune dépendance à Flutter, MySQL ou Provider.

Le détail des dossiers est décrit dans [docs/architecture.html](./docs/architecture.html).

---

## Base de Données

### Relations Principales

- **Client** ↔ **Contrat** ↔ **Traitement** ↔ **Planning** ↔ **PlanningDetails**.
- **PlanningDetails** ↔ **Facture** (relation N-1 pour le support groupé).
- Table **Historique** technique pour le suivi des interventions.
- Table **Remarque** pour les retours terrain.

---

## Utilitaires

- **NifStatFormatter** : gestion des standards fiscaux malgaches.
- **PhoneFormatter** : formatage des contacts (03X XX XXX XX).
- **NumberFormatter** : saisie et affichage des prix avec séparateurs de milliers.
- **ExcelService** : génération de rapports professionnels.
- **LoggingService** : système de log rotatif persistant.

---

## Démarrage Rapide

### Installation

1. Cloner le dépôt.
2. `flutter pub get`.
3. Configurer votre serveur MySQL (version ≥ 8.0).
4. Importer `scripts/Planificator.sql`.
5. Lancer : `flutter run`.

Le détail des migrations, sauvegardes, scripts de maintenance et workflows CI/CD est
documenté dans [docs/OPERATIONS.md](./docs/OPERATIONS.md).

La présentation publique, les guides d'installation et les documents légaux sont
disponibles dans [presentation/](./presentation/) et [docs/](./docs/).

---

## État du Projet

| Composant | État | Complétude |
| --------- | ---- | ---------- |
| Architecture | Industrialisée | 100 % |
| Intégrité DB | Transactionnelle | 100 % |
| Sécurité | Renforcée / Verrouillée | 100 % |
| UI/UX | Moderne / Animée | 100 % |

---

## Sécurité

La sécurité est une priorité majeure. Consultez le fichier [SECURITY.md](./SECURITY.md) pour les détails techniques.

## Tests Automatisés

La plateforme dispose d'une suite de tests couvrant la logique métier, financière et calendaire.
Pour plus d'informations sur la couverture des tests, consultez le fichier [TESTS.md](./TESTS.md).

```bash
flutter test
```

## Contribution

Si vous souhaitez contribuer au projet, lisez le guide détaillé [CONTRIBUTING.md](./CONTRIBUTING.md) pour connaître les standards de code et de sécurité.

## Auteur

**Josoa** - Développeur principal
- GitHub : [@josoavj](https://github.com/josoavj)

**Maminirina** - Testeur et architecture Back-end
- GitHub : [@AinaMaminirina18](https://github.com/AinaMaminirina18)

## Licence

Ce projet est sous licence **MIT**.

**Dernière mise à jour** : 4 novembre 2026

<p align="center">
  <img src="https://github.com/josoavj/PlanificatorFinal/blob/main/assets/pictures/banner-readme.svg" alt="Social Banner"/>
</p>
