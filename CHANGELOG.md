# Planificator - Changelog Global

Ce fichier centralise toutes les évolutions, corrections de bugs et optimisations de la plateforme Planificator.

**Version Actuelle**: 2.2.0  
**Statut**: PRODUCTION READY  
**Dernière mise à jour**: 2026-07-22

---

## [2.2.0] - Modernisation & Flexibilité (2026-07-22)

### Gestion des Contrats & Planning
- **Planning Hebdomadaire** : Nouvel algorithme supportant les fréquences tous les 7 jours, gérant les mois à 5 semaines.
- **Passages Multiples** : Support des rythmes 2 fois et 3 fois par semaine avec répartition équilibrée des dates.
- **Dates de Début Flexibles** : Possibilité de définir une date de premier passage spécifique pour chaque service au sein d'un même contrat.
- **Respect Calendrier Malgache** : Intégration du 29 Mars et du 1er Mai dans les jours non ouvrables (décalage automatique).

### Facturation & Comptabilité
- **Facturation Groupée** : Option permettant de générer une seule facture pour plusieurs services tombant le même jour (cumul automatique des montants).
- **Inversion de Relation DB** : Migration du schéma pour lier les passages à une facture (N-1), optimisant la traçabilité.
- **Formatage Financier** : Saisie assistée avec séparateurs de milliers en temps réel pour tous les champs de prix.

### Sécurité & Fiabilité
- **Verrouillage de Configuration** : L'accès aux paramètres de la base de données nécessite désormais la saisie du mot de passe administrateur.
- **Sauvegarde Atomique** : Refonte totale du processus d'enregistrement via une transaction SQL unique (Client + Contrat + Planning + Factures).
- **Formateurs Madagascar** : Implémentation de formateurs stricts pour le NIF (10 chiffres), le STAT (17 chiffres) et les téléphones (03X XX XXX XX).

### Expérience Utilisateur (UI/UX)
- **Design Desktop Premium** : Refonte des dialogues avec des coins arrondis (32px), des headers stylisés et des effets de transition fluides (FadeTransition).
- **Navigation Contextuelle** : Formulaires adaptatifs affichant les champs selon la catégorie client ou le mode de planification choisi.
- **Sélecteurs Visuels** : Remplacement des menus déroulants par des grilles de cartes interactives avec icônes.

---

## [2.1.1] - Fiabilité Financière & Industrialisation (2026-06-25)

### Intégrité des Données (SGBDR)
- **Atomic SQL Transactions** : Implémentation du support des transactions pour garantir que les opérations financières complexes soient atomiques.
- **Sécurisation des Prix** : La mise à jour massive des prix est désormais protégée par une transaction.
- **Régénération Sécurisée** : La création automatique de plannings et de factures est désormais atomique.

### Optimisations UI & Performance
- **Infinite Scrolling (Lazy Loading)** : L'historique des interventions utilise désormais une pagination.
- **Smart Cache System** : Implémentation d'un gestionnaire de cache SQL global.
- **Advanced Connection Pooling** : Pool de connexions MySQL réutilisables.

---

## Sécurité & Durcissement (2026-01-31)
- **Chiffrement des identifiants** : Utilisation de `flutter_secure_storage`.
- **Optimisation Windows** : Suppression des sous-requêtes corrélées.
