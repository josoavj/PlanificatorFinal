/*
    =====================================================
    MAINTENANCE DE BASE DE DONNÉES - PLANIFICATOR
    =====================================================
    
    Ce fichier consolide les scripts de maintenance essentiels:
    1. Fix_Planning_FK.sql - Correction des contraintes erronées
    2. optimize_indexes.sql - Optimisation des indices
    3. Migration.sql - Migrations de base de données
    
    Date: 20 janvier 2026
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
-- SECTION 2: MIGRATION - INDICES CRITIQUES
-- =====================================================
/*
    AJOUTER LES INDEXES CRITIQUES
    À exécuter pour améliorer les performances des requêtes principales
*/

-- Index sur les colonnes les plus requêtées
CREATE INDEX IF NOT EXISTS idx_client_email ON Client(email);
CREATE INDEX IF NOT EXISTS idx_client_axe ON Client(axe);

CREATE INDEX IF NOT EXISTS idx_contrat_client ON Contrat(client_id);
CREATE INDEX IF NOT EXISTS idx_contrat_statut ON Contrat(statut_contrat);

CREATE INDEX IF NOT EXISTS idx_traitement_contrat ON Traitement(contrat_id);
CREATE INDEX IF NOT EXISTS idx_traitement_type ON Traitement(id_type_traitement);

CREATE INDEX IF NOT EXISTS idx_planning_traitement ON Planning(traitement_id);
CREATE INDEX IF NOT EXISTS idx_planning_dates ON Planning(date_debut_planification, date_fin_planification);

CREATE INDEX IF NOT EXISTS idx_planning_details_planning ON PlanningDetails(planning_id);
CREATE INDEX IF NOT EXISTS idx_planning_details_statut ON PlanningDetails(statut);
CREATE INDEX IF NOT EXISTS idx_planning_details_date ON PlanningDetails(date_planification);

CREATE INDEX IF NOT EXISTS idx_facture_planning_detail ON Facture(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_facture_etat ON Facture(etat);
CREATE INDEX IF NOT EXISTS idx_facture_axe ON Facture(axe);
CREATE INDEX IF NOT EXISTS idx_facture_dates ON Facture(date_traitement);

CREATE INDEX IF NOT EXISTS idx_remarque_client ON Remarque(client_id);
CREATE INDEX IF NOT EXISTS idx_remarque_planning_detail ON Remarque(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_remarque_facture ON Remarque(facture_id);

CREATE INDEX IF NOT EXISTS idx_signalement_planning_detail ON Signalement(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_signalement_type ON Signalement(type);

CREATE INDEX IF NOT EXISTS idx_historique_facture ON Historique(facture_id);
CREATE INDEX IF NOT EXISTS idx_historique_planning_detail ON Historique(planning_detail_id);
CREATE INDEX IF NOT EXISTS idx_historique_signalement ON Historique(signalement_id);

CREATE INDEX IF NOT EXISTS idx_historique_prix_facture ON Historique_prix(facture_id);

SELECT 'OK SECTION 2 TERMINÉE - Indices de migration créés' AS 'Statut';

-- =====================================================
-- SECTION 3: OPTIMISATION DES INDICES SUPPLÉMENTAIRES
-- =====================================================
/*
    OPTIMISATION AVANCÉE DES INDICES
    Indices additionnels pour les requêtes complexes et joins fréquents
*/

-- Indices pour les requêtes de Factures
ALTER TABLE Facture ADD INDEX IF NOT EXISTS idx_planning_detail_id (planning_detail_id);
ALTER TABLE Facture ADD INDEX IF NOT EXISTS idx_date_traitement (date_traitement);

-- Indices pour les joins dans PlanningDetails
ALTER TABLE PlanningDetails ADD INDEX IF NOT EXISTS idx_planning_id (planning_id);
ALTER TABLE PlanningDetails ADD INDEX IF NOT EXISTS idx_date_planification (date_planification);

-- Indices pour les joins dans Planning
ALTER TABLE Planning ADD INDEX IF NOT EXISTS idx_traitement_id (traitement_id);

-- Indices pour les joins dans Traitement
ALTER TABLE Traitement ADD INDEX IF NOT EXISTS idx_contrat_id (contrat_id);
ALTER TABLE Traitement ADD INDEX IF NOT EXISTS idx_id_type_traitement (id_type_traitement);

-- Indices pour les joins dans Contrat
ALTER TABLE Contrat ADD INDEX IF NOT EXISTS idx_client_id (client_id);

-- Indices pour les requêtes de Clients
ALTER TABLE Client ADD INDEX IF NOT EXISTS idx_nom (nom);
ALTER TABLE Client ADD INDEX IF NOT EXISTS idx_categorie (categorie);

-- Indices composites pour les requêtes complexes
ALTER TABLE Facture ADD INDEX IF NOT EXISTS idx_planning_detail_date (planning_detail_id, date_traitement);
ALTER TABLE Traitement ADD INDEX IF NOT EXISTS idx_contrat_type (contrat_id, id_type_traitement);

-- Analyse et optimisation des statistiques
ANALYZE TABLE Facture;
ANALYZE TABLE PlanningDetails;
ANALYZE TABLE Planning;
ANALYZE TABLE Traitement;
ANALYZE TABLE TypeTraitement;
ANALYZE TABLE Contrat;
ANALYZE TABLE Client;

-- Vérification des indices créés
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'Planificator'
ORDER BY TABLE_NAME, INDEX_NAME;

SELECT 'OK SECTION 3 TERMINÉE - Indices d''optimisation créés' AS 'Statut';

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
