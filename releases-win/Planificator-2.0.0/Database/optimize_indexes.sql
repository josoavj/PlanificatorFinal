-- Optimisation des indices pour les requêtes de chargement de données
-- À exécuter sur la base de données Planificator pour améliorer les performances

-- 1. Indices pour les requêtes de Factures
ALTER TABLE Facture ADD INDEX idx_planning_detail_id (planning_detail_id);
ALTER TABLE Facture ADD INDEX idx_date_traitement (date_traitement);

-- 2. Indices pour les joins dans PlanningDetails
ALTER TABLE PlanningDetails ADD INDEX idx_planning_id (planning_id);
ALTER TABLE PlanningDetails ADD INDEX idx_date_planification (date_planification);

-- 3. Indices pour les joins dans Planning
ALTER TABLE Planning ADD INDEX idx_traitement_id (traitement_id);

-- 4. Indices pour les joins dans Traitement
ALTER TABLE Traitement ADD INDEX idx_contrat_id (contrat_id);
ALTER TABLE Traitement ADD INDEX idx_id_type_traitement (id_type_traitement);

-- 5. Indices pour les joins dans Contrat
ALTER TABLE Contrat ADD INDEX idx_client_id (client_id);

-- 6. Indices pour les requêtes de Clients
ALTER TABLE Client ADD INDEX idx_nom (nom);
ALTER TABLE Client ADD INDEX idx_categorie (categorie);

-- 7. Indices composites pour les requêtes complexes
ALTER TABLE Facture ADD INDEX idx_planning_detail_date (planning_detail_id, date_traitement);
ALTER TABLE Traitement ADD INDEX idx_contrat_type (contrat_id, id_type_traitement);

-- 8. Analyse et optimisation des statistiques
ANALYZE TABLE Facture;
ANALYZE TABLE PlanningDetails;
ANALYZE TABLE Planning;
ANALYZE TABLE Traitement;
ANALYZE TABLE TypeTraitement;
ANALYZE TABLE Contrat;
ANALYZE TABLE Client;

-- 9. Vérification des indices créés
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'Planificator'
ORDER BY TABLE_NAME, INDEX_NAME;
