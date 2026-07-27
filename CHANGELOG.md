# Planificator - Changelog Global

Ce fichier centralise toutes les évolutions, corrections de bugs et optimisations de la plateforme Planificator.

**Version Actuelle**: 2.1.1  
**Statut**: PRODUCTION READY  
**Dernière mise à jour**: 2026-07-27

---

## [2.1.1] - Panoramic Intelligence & Robustness (2026-07-27)

### Consultation & Audit (Historique)
- **Architecture Master-Detail** : Refonte modulaire de l'Historique, désormais organisé par Client pour une navigation plus naturelle.
- **Journal de Bord 360°** : Nouveau dialogue de synthèse regroupant réalisation technique, mouvements calendaires (reports), volet financier et évolution des tarifs.
- **Traçabilité des Prix** : Visualisation chronologique de tous les changements de montants appliqués à une facture au fil du temps.

### Ergonomie Desktop (UI/UX)
- **Refonte Panoramique** : Expansion des dialogues Détails Client et Contrat à 950px avec un layout en deux colonnes pour éliminer le scroll.
- **Récapitulatif Financier** : Calcul et affichage en temps réel du montant total cumulé par service et par contrat.
- **Espacements Premium** : Harmonisation des marges inter-sections pour une meilleure respiration visuelle.

### Performance & Moteur de Données
- **Tri Intelligent Centralisé** : Harmonisation globale de la logique d'affichage (Passé DESC / Futur ASC) dans tous les repositories.
- **Mise à jour Massive** : Optimisation de la modification des prix en cascade via une requête SQL unique (`massUpdateFutureFacturePrices`).
- **DB Resiliency** : Implémentation d'un système de secours (Fallback) basculant automatiquement sur la connexion principale en cas d'échec d'Isolate.
- **Synchronisation Temps Réel** : Correction du problème de rafraîchissement des détails, garantissant une mise à jour immédiate après une action.

### Qualité Logicielle & Tests
- **Infaillible Test Suite** : Ajout de 14 tests critiques couvrant les transactions SQL, la logique de tri et le calcul des montants.
- **Infrastructure de Mock** : Création d'un mock Database robuste et partagé pour tester tous les scénarios d'erreurs (Socket closed, Null cast).
- **Testabilité 100%** : Refactorisation de tous les repositories pour supporter l'injection de dépendances.

### Précédemment (2026-06-25)
- **Atomic SQL Transactions** : Support des transactions pour garantir l'intégrité financière.
- **Infinite Scrolling** : Pagination de l'historique des interventions.
- **Smart Cache System** : Cache SQL global et Pool de connexions MySQL.

---

## [2.0.0] - Fondations & Sécurité (2026-01-31)
- **Chiffrement des identifiants** : Utilisation de `flutter_secure_storage`.
- **BCrypt Auth** : Authentification sécurisée.
- **Native Desktop** : Support Windows, Linux et macOS.
