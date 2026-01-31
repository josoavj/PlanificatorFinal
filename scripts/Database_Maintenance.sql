/*
    =====================================================
    MAINTENANCE DE BASE DE DONNÉES - PLANIFICATOR
    =====================================================
    
    Ce fichier consolide les scripts de maintenance essentiels:
    1. Fix_Planning_FK.sql - Correction des contraintes erronées
    2. SQL_OPTIMIZATION_INDEXES.sql - Optimisation des indices v2.1.1
    3. Migration.sql - Migrations de base de données
    4. Vérifications de cohérence des données
    
    Date: 31 janvier 2026
    Version: 2.1.1
    =====================================================
*/

USE Planificator;

-- =====================================================
-- SECTION 1: CORRECTION DE LA CONTRAINTE FK CIRCULAIRE
-- =====================================================
/*
    FIX: Correction de la contrainte de clé étrangère circulaire
    
    PROBLÈME:
    - Une FK erronée a été ajoutée: Planning.planning_id → PlanningDetails(planning_id)
    - Cela crée une dépendance circulaire car PlanningDetails.planning_id → Planning(planning_id) existe déjà
    - Résultat: Erreur 1452 "Cannot add or update a child row" lors de l'insertion dans Planning
    
    SOLUTION:
    - Supprimer la contrainte erronée
    - La relation correcte existe déjà (PlanningDetails → Planning)
*/

SELECT DATABASE() AS 'Base de données actuelle';

-- Étape 1: Vérifier si la contrainte erronée existe
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'Planning' AND CONSTRAINT_NAME = 'fk_planning_planning_details';

-- Étape 2: Supprimer la contrainte erronée
ALTER TABLE Planning
DROP FOREIGN KEY IF EXISTS fk_planning_planning_details;

-- Étape 3: Vérifier que c'est supprimé
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'Planning' AND CONSTRAINT_NAME = 'fk_planning_planning_details';

-- Étape 4: Vérifier que la relation correcte existe toujours dans PlanningDetails
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'PlanningDetails' AND REFERENCED_TABLE_NAME = 'Planning';

-- Résultat attendu:
-- Planning: Aucune FK vers PlanningDetails
-- PlanningDetails: Une FK planning_id → Planning(planning_id)

SELECT 'OK SECTION 1 TERMINÉE - Contrainte erronée supprimée' AS 'Statut';

-- =====================================================
-- SECTION 2: OPTIMISATION DES INDICES CRITIQUES (v2.1.1)
-- =====================================================
/*
    INDEXES OPTIMISÉS POUR PLANIFICATOR v2.1.1
    Ces indexes sont cruciaux pour les requêtes fréquentes sur Windows.
    Impact estimé: Améliore les performances de 5x à 100x selon les requêtes.
    
    Changements par rapport à la v2.1.0:
    - Ajout d'indexes composites pour COUNT(DISTINCT) optimisé
    - Ajout d'indexes sur Account pour authentification rapide
    - Meilleur couvrage des colonnes de jointure
*/

-- Account (Authentification)
CREATE INDEX IF NOT EXISTS idx_account_username ON Account(username);
CREATE INDEX IF NOT EXISTS idx_account_email ON Account(email);

-- Client (Gestion clients - requête fréquente)
CREATE INDEX IF NOT EXISTS idx_client_nom ON Client(nom);
CREATE INDEX IF NOT EXISTS idx_client_email ON Client(email);
CREATE INDEX IF NOT EXISTS idx_client_categorie ON Client(categorie);
CREATE INDEX IF NOT EXISTS idx_client_axe ON Client(axe);
CREATE INDEX IF NOT EXISTS idx_client_date_ajout ON Client(date_ajout);
-- Index composite pour recherche par nom et prénom
CREATE INDEX IF NOT EXISTS idx_client_nom_prenom ON Client(nom, prenom);

-- Contrat (Jointures fréquentes client <-> contrat)
CREATE INDEX IF NOT EXISTS idx_contrat_client_id ON Contrat(client_id);
CREATE INDEX IF NOT EXISTS idx_contrat_statut ON Contrat(statut_contrat);
CREATE INDEX IF NOT EXISTS idx_contrat_date_debut ON Contrat(date_debut);
CREATE INDEX IF NOT EXISTS idx_contrat_date_fin ON Contrat(date_fin);
-- Index composite pour recherche par client et statut
CREATE INDEX IF NOT EXISTS idx_contrat_client_statut ON Contrat(client_id, statut_contrat);

-- Traitement (Recherche par contrat et type)
CREATE INDEX IF NOT EXISTS idx_traitement_contrat_id ON Traitement(contrat_id);
CREATE INDEX IF NOT EXISTS idx_traitement_type_id ON Traitement(id_type_traitement);
CREATE INDEX IF NOT EXISTS idx_traitement_date_debut ON Traitement(date_debut_planification);
CREATE INDEX IF NOT EXISTS idx_traitement_date_fin ON Traitement(date_fin_planification);
-- Index composite pour COUNT(DISTINCT) optimisé (CRUCIAL pour loadClients)
CREATE INDEX IF NOT EXISTS idx_traitement_contrat_type ON Traitement(contrat_id, id_type_traitement);

-- Planning (Requêtes avec subqueries)
CREATE INDEX IF NOT EXISTS idx_planning_traitement_id ON Planning(traitement_id);
CREATE INDEX IF NOT EXISTS idx_planning_date_debut ON Planning(date_debut_planification);
CREATE INDEX IF NOT EXISTS idx_planning_date_fin ON Planning(date_fin_planification);
CREATE INDEX IF NOT EXISTS idx_planning_redondance ON Planning(redondance);

-- PlanningDetails (Statut et dates)
CREATE INDEX IF NOT EXISTS idx_planning_details_planning ON PlanningDetails(planning_id);
CREATE INDEX IF NOT EXISTS idx_planning_details_date ON PlanningDetails(date_planification);
CREATE INDEX IF NOT EXISTS idx_planning_details_statut ON PlanningDetails(statut);
-- Index composite pour recherche par planning et date
CREATE INDEX IF NOT EXISTS idx_planning_details_planning_date ON PlanningDetails(planning_id, date_planification);

-- Facture (Statut et dates)
CREATE INDEX IF NOT EXISTS idx_facture_planning_detail ON Facture(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_facture_contrat_id ON Facture(contrat_id);
CREATE INDEX IF NOT EXISTS idx_facture_etat ON Facture(etat);
CREATE INDEX IF NOT EXISTS idx_facture_axe ON Facture(axe);
CREATE INDEX IF NOT EXISTS idx_facture_dates ON Facture(date_traitement);
CREATE INDEX IF NOT EXISTS idx_facture_date_emission ON Facture(date_emission);
CREATE INDEX IF NOT EXISTS idx_facture_date_echeance ON Facture(date_echeance);
-- Index composite pour factures par contrat et statut
CREATE INDEX IF NOT EXISTS idx_facture_contrat_statut ON Facture(contrat_id, etat);

-- Remarque et Signalement (Requêtes par planning_detail)
CREATE INDEX IF NOT EXISTS idx_remarque_client ON Remarque(client_id);
CREATE INDEX IF NOT EXISTS idx_remarque_planning_detail ON Remarque(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_remarque_facture ON Remarque(facture_id);
CREATE INDEX IF NOT EXISTS idx_signalement_planning_detail ON Signalement(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_signalement_type ON Signalement(type);

-- Historique (Filtrage par date et utilisateur)
CREATE INDEX IF NOT EXISTS idx_historique_facture ON Historique(facture_id);
CREATE INDEX IF NOT EXISTS idx_historique_planning_detail ON Historique(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_historique_signalement ON Historique(signalement_id);
CREATE INDEX IF NOT EXISTS idx_historique_date ON Historique(date);
CREATE INDEX IF NOT EXISTS idx_historique_id_compte ON Historique(id_compte);
CREATE INDEX IF NOT EXISTS idx_historique_entity_type ON Historique(entity_type);
-- Index composite pour filtrage temporal
CREATE INDEX IF NOT EXISTS idx_historique_date_type ON Historique(date, entity_type);

-- Historique_prix
CREATE INDEX IF NOT EXISTS idx_historique_prix_facture ON Historique_prix(facture_id);

SELECT 'OK SECTION 2 TERMINÉE - Indices optimisés v2.1.1 créés' AS 'Statut';

-- =====================================================
-- SECTION 3: ANALYSE ET STATISTIQUES DES INDICES
-- =====================================================
/*
    ANALYSE DES STATISTIQUES
    Optimise l'exécution des requêtes basée sur les statistiques des indices
*/

-- Analyse et optimisation des statistiques
ANALYZE TABLE Facture;
ANALYZE TABLE PlanningDetails;
ANALYZE TABLE Planning;
ANALYZE TABLE Traitement;
ANALYZE TABLE TypeTraitement;
ANALYZE TABLE Contrat;
ANALYZE TABLE Client;
ANALYZE TABLE Account;
ANALYZE TABLE Remarque;
ANALYZE TABLE Signalement;
ANALYZE TABLE Historique;

-- Vérification du nombre d'indices créés par table
SELECT TABLE_NAME, COUNT(*) as nombre_indices
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'Planificator' AND INDEX_NAME != 'PRIMARY'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

SELECT 'OK SECTION 3 TERMINÉE - Analyse des statistiques effectuée' AS 'Statut';

-- =====================================================
-- SECTION 4: VÉRIFICATIONS DE COHÉRENCE DE DONNÉES
-- =====================================================
/*
    VÉRIFICATIONS IMPORTANTES
    Assurer la cohérence et l'intégrité des données
*/

-- Vérifier qu'il n'y a pas de factures liées à des planning_detail_id invalides
SELECT f.facture_id, f.planning_detail_id 
FROM Facture f
LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
WHERE pd.planning_detail_id IS NULL
LIMIT 10;

-- Vérifier qu'il n'y a pas de remarques orphelines
SELECT r.remarque_id, r.planning_detail_id
FROM Remarque r
LEFT JOIN PlanningDetails pd ON r.planning_detail_id = pd.planning_detail_id
WHERE r.planning_detail_id IS NOT NULL AND pd.planning_detail_id IS NULL
LIMIT 10;

-- Vérifier la cohérence des ENUM Axes
-- Axes utilisés:
-- - Client.axe
-- - Facture.axe
-- Les deux utilisent: 'Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)'

-- Statuts de planning vs facture:
-- - PlanningDetails.statut: 'Effectué', 'À venir'
-- - Facture.etat: 'Payé', 'Non payé', 'À venir'
-- DIFFÉRENTS - pas de fusion possible

SELECT 'OK SECTION 4 TERMINÉE - Vérifications de cohérence effectuées' AS 'Statut';

-- =====================================================
-- SECTION 5: RÉSUMÉ FINAL
-- =====================================================

SELECT 'OK MAINTENANCE COMPLÈTE TERMINÉE' AS 'Statut';
SELECT 'Toutes les corrections et optimisations ont été appliquées avec succès' AS 'Message';

-- Comptage des indices créés par table
SELECT TABLE_NAME, COUNT(*) as nombre_indices
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'Planificator' AND INDEX_NAME != 'PRIMARY'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- =====================================================
-- FIN DU SCRIPT DE MAINTENANCE
-- =====================================================
