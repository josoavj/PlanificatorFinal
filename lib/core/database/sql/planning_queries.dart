/// Requêtes SQL liées à ce domaine fonctionnel.
class PlanningQueries {
  static const String getClientAxeByTreatment = '''
    SELECT DISTINCT cl.axe
    FROM Traitement t
    INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
    INNER JOIN Client cl ON c.client_id = cl.client_id
    WHERE t.traitement_id = ?
  ''';

  static const String getPlanningByTreatment =
      'SELECT p.planning_id, p.date_debut_planification, p.duree_traitement, p.redondance FROM Planning p WHERE p.traitement_id = ? LIMIT 1';

  static const String countPlanningDetails =
      'SELECT COUNT(*) as count FROM PlanningDetails WHERE planning_id = ?';

  static const String countPlanningDetailsByTreatment =
      'SELECT COUNT(*) as count FROM Planning WHERE traitement_id = ?';

  static const String countFacturesByTreatment = '''
    SELECT COUNT(*) as count FROM Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    WHERE p.traitement_id = ?
  ''';

  static const String countRemarquesByTreatment = '''
    SELECT COUNT(*) as count FROM Remarque r
    INNER JOIN PlanningDetails pd ON r.planning_detail_id = pd.planning_detail_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    WHERE p.traitement_id = ?
  ''';

  static const String countHistoriqueByTreatment = '''
    SELECT COUNT(*) as count FROM Historique h
    WHERE h.facture_id IN (
      SELECT f.facture_id FROM Facture f
      INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
      INNER JOIN Planning p ON pd.planning_id = p.planning_id
      WHERE p.traitement_id = ?
    )
  ''';

  static const String sumMontantByTreatment = '''
    SELECT COALESCE(SUM(CAST(f.montant AS DECIMAL(10,2))), 0) as total FROM Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    WHERE p.traitement_id = ?
  ''';

  static const String getRedondanceByTreatment =
      'SELECT redondance FROM Planning WHERE traitement_id = ? LIMIT 1';

  static const String getTreatmentIdByType = '''
    SELECT t.traitement_id, t.contrat_id
    FROM Traitement t
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    WHERE t.contrat_id = ? AND tt.typeTraitement = ?
    LIMIT 1
  ''';

  static const String insertPlanningDetail =
      'INSERT INTO PlanningDetails (planning_id, date_planification) VALUES (?, ?)';

  static const String getPlanningDetailsByPlanningIdOrdered =
      'SELECT DISTINCT pd.planning_detail_id, pd.date_planification FROM PlanningDetails pd WHERE pd.planning_id = ? ORDER BY pd.date_planification ASC';

  // --- PLANNING DETAILS ---

  static const String checkExistingPlanningDetail =
      'SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ? AND date_planification = ?';

  static const String insertPlanningDetailWithStatut =
      'INSERT INTO PlanningDetails (planning_id, date_planification, statut, facture_id) VALUES (?, ?, ?, ?)';

  static const String updatePlanningDetailFacture =
      'UPDATE PlanningDetails SET facture_id = ? WHERE planning_detail_id = ?';

  static const String getPlanningDetailsByPlanningId =
      'SELECT * FROM PlanningDetails WHERE planning_id = ? ORDER BY date_planification';

  static const String updatePlanningDetailStatut =
      'UPDATE PlanningDetails SET statut = ? WHERE planning_detail_id = ?';

  static const String deletePlanningDetail =
      'DELETE FROM PlanningDetails WHERE planning_detail_id = ?';

  static const String getAllPlanningDetails =
      'SELECT * FROM PlanningDetails ORDER BY date_planification DESC';

  static const String getPlanningDetailCompleteById = '''
    SELECT 
      pd.planning_detail_id,
      pd.planning_id,
      DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
      CAST(CONCAT(COALESCE(tt.typeTraitement, 'Sans type'), ' pour ', COALESCE(c.prenom, ''), ' ', COALESCE(c.nom, '')) AS CHAR) as traitement,
      COALESCE(pd.statut, 'Non planifié') as etat,
      COALESCE(c.axe, 'Non défini') as axe,
      COALESCE(tt.categorieTraitement, '') as categorieTraitement,
      COALESCE(c.categorie, '') as categorie,
      COALESCE(f.montant, 0) as montant,
      COALESCE(f.etat, 'Non payé') as facture_etat,
      c.telephone,
      c.email,
      c.client_id
    FROM PlanningDetails pd
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
    INNER JOIN Client c ON ct.client_id = c.client_id
    LEFT JOIN Facture f ON pd.facture_id = f.facture_id
    WHERE pd.planning_detail_id = ?
    LIMIT 1
  ''';

  static const String getCurrentMonthTreatmentsComplete = '''
    SELECT 
      pd.planning_detail_id,
      pd.planning_id,
      DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
      CAST(CONCAT(COALESCE(tt.typeTraitement, 'Sans type'), ' pour ', COALESCE(c.prenom, ''), ' ', COALESCE(c.nom, '')) AS CHAR) as traitement,
      COALESCE(pd.statut, 'Non planifié') as etat,
      COALESCE(c.axe, 'Non défini') as axe,
      COALESCE(tt.categorieTraitement, '') as categorieTraitement,
      COALESCE(c.categorie, '') as categorie,
      COALESCE(f.montant, 0) as montant,
      COALESCE(f.etat, 'Non payé') as facture_etat,
      c.telephone,
      c.email,
      c.client_id
    FROM PlanningDetails pd
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
    INNER JOIN Client c ON ct.client_id = c.client_id
    LEFT JOIN Facture f ON pd.facture_id = f.facture_id
    WHERE YEAR(pd.date_planification) = ?
    AND MONTH(pd.date_planification) = ?
    AND COALESCE(pd.statut, 'Non planifié') != 'Classé sans suite'
    ORDER BY pd.date_planification ASC
    LIMIT 5000
  ''';

  static const String getUpcomingTreatmentsComplete = '''
    SELECT 
      pd.planning_detail_id,
      pd.planning_id,
      DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
      pd.date_planification,
      CAST(CONCAT(COALESCE(tt.typeTraitement, 'Sans type'), ' pour ', COALESCE(c.prenom, ''), ' ', COALESCE(c.nom, '')) AS CHAR) as traitement,
      COALESCE(pd.statut, 'Non planifié') as etat,
      COALESCE(c.axe, 'Non défini') as axe,
      COALESCE(tt.categorieTraitement, '') as categorieTraitement,
      COALESCE(c.categorie, '') as categorie,
      COALESCE(f.montant, 0) as montant,
      COALESCE(f.etat, 'Non payé') as facture_etat,
      c.telephone,
      c.email,
      c.client_id
    FROM PlanningDetails pd
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
    INNER JOIN Client c ON ct.client_id = c.client_id
    LEFT JOIN Facture f ON pd.facture_id = f.facture_id
    WHERE pd.date_planification >= ?
    AND COALESCE(pd.statut, 'Non planifié') != 'Classé sans suite'
    ORDER BY pd.date_planification ASC
    LIMIT 10000
  ''';

  static const String getAllTreatmentsComplete = '''
    SELECT 
      pd.planning_detail_id,
      pd.planning_id,
      DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
      pd.date_planification,
      CONCAT(tt.typeTraitement, ' pour ', c.prenom, ' ', c.nom) as traitement,
      pd.statut as etat,
      c.axe,
      tt.categorieTraitement,
      tt.id_type_traitement,
      c.client_id,
      ct.contrat_id,
      c.categorie
    FROM PlanningDetails pd
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
    INNER JOIN Client c ON ct.client_id = c.client_id
    ORDER BY pd.date_planification DESC
  ''';

  static const String getAllTreatmentsPaginated = '''
    SELECT 
      pd.planning_detail_id,
      pd.planning_id,
      DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
      pd.date_planification,
      CONCAT(tt.typeTraitement, ' pour ', c.prenom, ' ', c.nom) as traitement,
      pd.statut as etat,
      c.axe,
      tt.categorieTraitement,
      tt.id_type_traitement,
      c.client_id,
      ct.contrat_id,
      c.categorie
    FROM PlanningDetails pd
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
    INNER JOIN Client c ON ct.client_id = c.client_id
    ORDER BY pd.date_planification DESC
    LIMIT ? OFFSET ?
  ''';

  static const String countAllTreatments =
      'SELECT COUNT(*) as count FROM PlanningDetails';

  static const String countTreatmentsByCategory = '''
    SELECT tt.categorieTraitement, COUNT(*) as count
    FROM PlanningDetails pd
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    GROUP BY tt.categorieTraitement
  ''';

  static const String getTreatmentsByMonthAndClientBase = '''
    SELECT 
      pd.date_planification AS `Date du traitement`,
      tt.typeTraitement AS `Traitement concerné`,
      tt.categorieTraitement AS `Catégorie du traitement`,
      CONCAT(c.nom, ' ', c.prenom) AS `Client concerné`,
      c.categorie AS `Catégorie du client`,
      c.axe AS `Axe du client`,
      pd.statut AS `Etat traitement`
    FROM PlanningDetails pd
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
    INNER JOIN Client c ON co.client_id = c.client_id
  ''';

  static const String getDistinctTreatmentTypes = '''
    SELECT DISTINCT tt.typeTraitement
    FROM Traitement t
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    ORDER BY tt.typeTraitement ASC
  ''';

  static const String getDistinctTreatmentTypesByClient = '''
    SELECT DISTINCT tt.typeTraitement
    FROM Traitement t
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
    WHERE co.client_id = ?
    ORDER BY tt.typeTraitement ASC
  ''';

  // --- PLANNING NEW ---

  static const String createPlanning = '''
    INSERT INTO Planning 
    (traitement_id, date_debut_planification, mois_debut, mois_fin, duree_traitement, redondance, date_fin_planification)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ''';

  static const String checkPlanningExistence =
      'SELECT planning_id FROM Planning WHERE traitement_id = ?';

  // --- HISTORIQUE ---

  static const String getAllSignalements =
      'SELECT * FROM Signalement ORDER BY signalement_id DESC';

  static const String createSignalement =
      'INSERT INTO Signalement (planning_detail_id, motif, type) VALUES (?, ?, ?)';

  static const String updatePlanningDate =
      'UPDATE PlanningDetails SET date_planification = ? WHERE planning_detail_id = ?';

  // --- REMARQUES ---

  static const String createRemarque =
      'INSERT INTO Remarque (client_id, planning_detail_id, facture_id, contenu, issue, action) VALUES (?, ?, ?, ?, ?, ?)';

  static const String getClientIdFromPlanningDetail = '''
    SELECT c.client_id FROM Client c 
    JOIN Contrat ct ON c.client_id = ct.client_id 
    JOIN Traitement t ON ct.contrat_id = t.contrat_id 
    JOIN Planning p ON t.traitement_id = p.traitement_id 
    JOIN PlanningDetails pd ON p.planning_id = pd.planning_id 
    WHERE pd.planning_detail_id = ?
  ''';

  static const String getAllRemarquesDetailed = '''
    SELECT 
      r.remarque_id, r.client_id, r.planning_detail_id, r.facture_id, r.contenu, 
      r.issue, r.action, r.date_remarque
    FROM Remarque r
    ORDER BY r.date_remarque DESC
  ''';

  static const String getRemarquesByPlanningDetail = '''
    SELECT 
      r.remarque_id, r.client_id, r.planning_detail_id, r.facture_id, r.contenu, 
      r.issue, r.action, r.date_remarque
    FROM Remarque r
    WHERE r.planning_detail_id = ?
    ORDER BY r.date_remarque DESC
  ''';

  static const String updateRemarqueBasic = '''
    UPDATE Remarque
    SET contenu = ?, issue = ?, action = ?
    WHERE remarque_id = ?
  ''';

  static const String deleteRemarque =
      'DELETE FROM Remarque WHERE remarque_id = ?';

  // --- EXPORTS ---
}
