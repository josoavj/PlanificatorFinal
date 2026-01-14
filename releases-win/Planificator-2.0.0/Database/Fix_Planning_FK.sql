/*
    =====================================================
    FIX: Correction de la contrainte de clé étrangère circulaire
    =====================================================
    
    PROBLÈME:
    - Une FK erronée a été ajoutée: Planning.planning_id → PlanningDetails(planning_id)
    - Cela crée une dépendance circulaire car PlanningDetails.planning_id → Planning(planning_id) existe déjà
    - Résultat: Erreur 1452 "Cannot add or update a child row" lors de l'insertion dans Planning
    
    SOLUTION:
    - Supprimer la contrainte erronée
    - La relation correcte existe déjà (PlanningDetails → Planning)
    
    =====================================================
*/

USE Planificator;

-- Étape 1: Vérifier qu'on est sur la bonne base
SELECT DATABASE() AS 'Base de données actuelle';

-- Étape 2: Vérifier si la contrainte erronée existe
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'Planning' AND CONSTRAINT_NAME = 'fk_planning_planning_details';

-- Étape 3: Supprimer la contrainte erronée
ALTER TABLE Planning
DROP FOREIGN KEY IF EXISTS fk_planning_planning_details;

-- Étape 4: Vérifier que c'est supprimé
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'Planning' AND CONSTRAINT_NAME = 'fk_planning_planning_details';

-- Étape 5: Vérifier que la relation correcte existe toujours dans PlanningDetails
SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'PlanningDetails' AND REFERENCED_TABLE_NAME = 'Planning';

-- ✅ Résultat attendu:
-- Planning: Aucune FK vers PlanningDetails
-- PlanningDetails: Une FK planning_id → Planning(planning_id)

SELECT '✅ FIX TERMINÉ - La contrainte erronée a été supprimée' AS 'Statut';
