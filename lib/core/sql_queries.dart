/// Centralisation de toutes les requêtes SQL du projet
/// Permet une maintenance facile et évite la duplication.
class SqlQueries {
  // --- AUTH ---
  static const String login = '''
    SELECT id_compte as userId, email, nom, prenom, password, type_compte, date_creation as createdAt
    FROM Account WHERE username = ?
  ''';
  static const String checkUsername = 'SELECT id_compte FROM Account WHERE username = ?';

  // --- CLIENTS ---
  static const String getClientsPaginated = '''
    SELECT 
      c.client_id, 
      COALESCE(c.nom, 'Sans nom') as nom, 
      COALESCE(c.prenom, '') as prenom, 
      COALESCE(c.email, '') as email, 
      COALESCE(c.telephone, '') as telephone, 
      COALESCE(c.adresse, '') as adresse, 
      COALESCE(c.categorie, '') as categorie, 
      COALESCE(c.nif, '') as nif, 
      COALESCE(c.stat, '') as stat, 
      COALESCE(c.axe, '') as axe,
      COALESCE((
        SELECT COUNT(*)
        FROM Traitement t
        INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
        WHERE co.client_id = c.client_id
      ), 0) as treatment_count
    FROM Client c
    WHERE EXISTS (
      SELECT 1 FROM Contrat co 
      WHERE co.client_id = c.client_id
    )
    ORDER BY COALESCE(c.nom, 'Z') ASC, COALESCE(c.prenom, '') ASC
    LIMIT ? OFFSET ?
  ''';

  static const String getClientById = '''
    SELECT 
      c.client_id, c.nom, c.prenom, c.email, c.telephone, c.adresse,
      c.categorie, c.nif, c.stat, c.axe, c.date_ajout,
      COALESCE(COUNT(DISTINCT t.traitement_id), 0) as treatment_count
    FROM Client c
    LEFT JOIN Contrat co ON c.client_id = co.client_id
    LEFT JOIN Traitement t ON co.contrat_id = t.contrat_id
    WHERE c.client_id = ?
    GROUP BY c.client_id
  ''';

  static const String createClient = '''
    INSERT INTO Client (nom, prenom, email, telephone, adresse, 
                       categorie, nif, stat, axe, date_ajout)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const String updateClient = '''
    UPDATE Client
    SET nom = ?, prenom = ?, email = ?, telephone = ?, adresse = ?,
        categorie = ?, nif = ?, stat = ?, axe = ?
    WHERE client_id = ?
  ''';

  static const String searchClients = '''
    SELECT 
      c.client_id, c.nom, c.prenom, c.email, c.telephone, c.adresse,
      c.categorie, c.nif, c.stat, c.axe,
      COALESCE(COUNT(DISTINCT t.traitement_id), 0) as treatment_count
    FROM Client c
    LEFT JOIN Contrat co ON c.client_id = co.client_id
    LEFT JOIN Traitement t ON co.contrat_id = t.contrat_id
    WHERE c.nom LIKE ? OR c.prenom LIKE ? OR c.email LIKE ?
    GROUP BY c.client_id
    HAVING COUNT(DISTINCT co.contrat_id) > 0
    ORDER BY COALESCE(c.nom, 'Z') ASC, COALESCE(c.prenom, '') ASC
  ''';

  static const String checkEmail = 'SELECT client_id FROM Client WHERE email = ?';

  static const String getCategories = 'SELECT DISTINCT categorie FROM Client ORDER BY categorie ASC';

  static const String getAllClientsBasic = '''
    SELECT 
      client_id, nom, prenom, email, telephone, adresse, 
      categorie, nif, stat, axe
    FROM Client
    ORDER BY nom ASC
  ''';

  // --- CONTRATS ---
  static const String getContratsPaginated = '''
    SELECT 
      c.contrat_id, c.client_id, c.reference_contrat, c.date_contrat, c.date_debut, c.date_fin, 
      c.statut_contrat, c.duree_contrat, c.duree, c.categorie
    FROM Contrat c
    JOIN Client cli ON c.client_id = cli.client_id
    ORDER BY cli.nom ASC
    LIMIT ? OFFSET ?
  ''';

  static const String getContratById = '''
    SELECT 
      contrat_id, client_id, reference_contrat, date_contrat, date_debut, date_fin, 
      statut_contrat, duree_contrat, duree, categorie
    FROM Contrat
    WHERE contrat_id = ?
  ''';

  static const String createContrat = '''
    INSERT INTO Contrat (client_id, reference_contrat, date_contrat, date_debut, date_fin, statut_contrat, duree_contrat, duree, categorie)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const String updateContrat = '''
    UPDATE Contrat 
    SET client_id = ?, reference_contrat = ?, date_contrat = ?, date_debut = ?, date_fin = ?, statut_contrat = ?, duree_contrat = ?, duree = ?, categorie = ?
    WHERE contrat_id = ?
  ''';

  static const String deleteContrat = 'DELETE FROM Contrat WHERE contrat_id = ?';

  static const String searchContrats = '''
    SELECT 
      c.contrat_id, c.client_id, c.reference_contrat, c.date_contrat, c.date_debut, c.date_fin, c.statut_contrat, c.duree_contrat, c.duree, c.categorie
    FROM Contrat c
    JOIN Client cli ON c.client_id = cli.client_id
    WHERE cli.nom LIKE ? OR cli.prenom LIKE ?
    ORDER BY cli.nom ASC
  ''';

  static const String createTraitement = '''
    INSERT INTO Traitement (contrat_id, id_type_traitement)
    VALUES (?, ?)
  ''';

  static const String abrogateContrat = '''
    UPDATE Contrat 
    SET statut_contrat = 'Résilié', 
        date_abrogation = ?, 
        motif_abrogation = ?,
        date_fin = ?
    WHERE contrat_id = ?
  ''';

  static const String getTreatmentsByContrat = 'SELECT traitement_id FROM Traitement WHERE contrat_id = ?';
  static const String countTreatmentsByContrat = 'SELECT COUNT(*) as count FROM Traitement WHERE contrat_id = ?';

  static const String getTraitementsDetailedByContrat = '''
    SELECT 
        t.traitement_id, 
        t.contrat_id, 
        tt.typeTraitement as nom,
        tt.categorieTraitement as type,
        COALESCE(COUNT(pd.planning_detail_id), 0) as total_planif,
        COALESCE(SUM(CASE WHEN pd.statut = 'Effectué' THEN 1 ELSE 0 END), 0) as planif_faites,
        CAST(IFNULL(GROUP_CONCAT(DISTINCT pd.statut), '') AS CHAR) as statuts,
        (SELECT SUM(f.montant) 
         FROM Facture f 
         WHERE f.facture_id IN (
             SELECT DISTINCT pd2.facture_id 
             FROM PlanningDetails pd2 
             INNER JOIN Planning p2 ON pd2.planning_id = p2.planning_id 
             WHERE p2.traitement_id = t.traitement_id
         )) as montant_total
    FROM Traitement t
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    LEFT JOIN Planning p ON t.traitement_id = p.traitement_id
    LEFT JOIN PlanningDetails pd ON p.planning_id = pd.planning_id
    WHERE t.contrat_id = ?
    GROUP BY t.traitement_id
  ''';

  static const String getFuturePlanningsByTreatment = 'SELECT planning_id FROM Planning WHERE traitement_id = ? AND date_debut_planification > ?';

  static const String deleteFuturePlanningDetailsByPlanning = '''
    DELETE FROM PlanningDetails 
    WHERE planning_id = ? AND statut = 'À venir'
  ''';

  // --- FACTURES ---
  // Note: Toutes les requêtes de factures utilisent désormais le lien réciproque (PlanningDetails.facture_id)
  // pour supporter les factures groupées (N passages -> 1 Facture)

  static const String getFacturesByContrat = '''
    SELECT DISTINCT f.*
    FROM Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
    INNER JOIN Client cl ON co.client_id = cl.client_id
    WHERE t.contrat_id = ?
    ORDER BY f.date_traitement DESC
  ''';

  static const String getFacturesByClientDetailed = '''
    SELECT 
      f.facture_id,
      pd.planning_detail_id,
      f.reference_facture,
      f.montant,
      f.mode,
      f.etablissement_payeur,
      f.date_cheque,
      f.numero_cheque,
      f.date_traitement,
      f.etat,
      f.axe,
      cl.client_id,
      cl.nom as clientNom,
      cl.prenom as clientPrenom,
      cl.categorie as clientCategorie,
      CAST(GROUP_CONCAT(DISTINCT tt.typeTraitement SEPARATOR ' + ') AS CHAR) as typeTreatment,
      pd.date_planification as datePlanification,
      pd.statut as etatPlanning
    FROM Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
    INNER JOIN Client cl ON co.client_id = cl.client_id
    WHERE cl.client_id = ?
    GROUP BY f.facture_id
    ORDER BY f.date_traitement DESC
  ''';

  static const String getAllFacturesDetailed = '''
    SELECT 
      f.facture_id,
      MAX(pd.planning_detail_id) as planning_detail_id,
      p.traitement_id as traitement_id,
      f.reference_facture,
      f.montant,
      f.mode,
      f.etablissement_payeur,
      f.date_cheque,
      f.numero_cheque,
      f.date_traitement,
      f.etat,
      f.axe,
      COALESCE(cl.client_id, 0) as client_id,
      COALESCE(cl.nom, 'Non associé') as clientNom,
      COALESCE(cl.prenom, '') as clientPrenom,
      COALESCE(cl.categorie, '') as clientCategorie,
      CAST(GROUP_CONCAT(DISTINCT tt.typeTraitement SEPARATOR ' + ') AS CHAR) as typeTreatment,
      COALESCE(f.date_traitement, '2000-01-01') as datePlanification,
      'Groupée' as etatPlanning
    FROM Facture f
    LEFT JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    LEFT JOIN Planning p ON pd.planning_id = p.planning_id
    LEFT JOIN Traitement t ON p.traitement_id = t.traitement_id
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    LEFT JOIN Contrat co ON t.contrat_id = co.contrat_id
    LEFT JOIN Client cl ON co.client_id = cl.client_id
    GROUP BY f.facture_id
    ORDER BY f.date_traitement DESC
    LIMIT 10000
  ''';

  static const String getFacturesByPlanningDetail = '''
    SELECT f.*
    FROM Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    WHERE pd.planning_detail_id = ?
    ORDER BY f.date_traitement DESC
  ''';

  static const String getFacturesGroupedByTraitement = '''
    SELECT DISTINCT 
      f.facture_id, 
      f.montant, 
      f.date_traitement,
      f.etat,
      tt.typeTraitement
    FROM Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    WHERE t.contrat_id = ?
    ORDER BY tt.typeTraitement ASC, f.date_traitement DESC
  ''';

  static const String getPriceHistory = '''
    SELECT 
      history_id,
      facture_id,
      old_amount,
      new_amount,
      change_date,
      changed_by
    FROM Historique_prix
    WHERE facture_id = ?
    ORDER BY change_date ASC
  ''';

  static const String updateFacturePrice = 'UPDATE Facture SET montant = ? WHERE facture_id = ?';
  static const String markFactureAsPaid = 'UPDATE Facture SET etat = ? WHERE facture_id = ?';
  static const String updateFactureReference = 'UPDATE Facture SET reference_facture = ? WHERE facture_id = ?';

  static const String massUpdateFutureFacturePrices = '''
    UPDATE Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    SET f.montant = f.montant + ?
    WHERE p.traitement_id = ? 
    AND f.date_traitement >= ? 
    AND f.etat NOT IN ('Payé', 'Payée')
  ''';

  static const String getFactureAndTreatmentInfo = '''
    SELECT f.facture_id, f.date_traitement, pd.planning_id, p.traitement_id
    FROM Facture f
    LEFT JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    LEFT JOIN Planning p ON pd.planning_id = p.planning_id
    WHERE f.facture_id = ?
    LIMIT 1
  ''';

  static const String getOtherFacturesByTreatmentFromDate = '''
    SELECT f.facture_id, f.montant, f.date_traitement, f.etat
    FROM Facture f
    INNER JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    INNER JOIN Planning p ON pd.planning_id = p.planning_id
    WHERE p.traitement_id = ? AND f.date_traitement >= ?
    ORDER BY f.date_traitement DESC
  ''';

  static const String createPriceHistoryEntry = '''
    INSERT INTO Historique_prix (facture_id, old_amount, new_amount, change_date)
    VALUES (?, ?, ?, ?)
  ''';

  static const String createFacture = '''
    INSERT INTO Facture (planning_detail_id, montant, date_traitement, etat, axe)
    VALUES (?, ?, ?, ?, ?)
  ''';

  static const String createFactureWithMode = '''
    INSERT INTO Facture (planning_detail_id, montant, mode, date_traitement, etat, axe)
    VALUES (?, ?, ?, ?, 'Non payé', 'Centre (C)')
  ''';

  static const String checkFactureExistence = 'SELECT facture_id FROM Facture WHERE planning_detail_id = ?';

  static const String createFactureComplete = '''
    INSERT INTO Facture (planning_detail_id, reference_facture, montant, mode, date_traitement, etat, axe)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ''';

  static const String updateFactureFull = '''
    UPDATE Facture
    SET etat = ?, mode = ?, numero_cheque = ?, date_cheque = ?, etablissement_payeur = ?
    WHERE facture_id = ?
  ''';

  static const String updateFacturePaymentOnly = '''
    UPDATE Facture
    SET etat = ?, mode = ?, numero_cheque = ?, date_cheque = ?
    WHERE facture_id = ?
  ''';

  static const String deleteFacture = 'DELETE FROM Facture WHERE facture_id = ?';

  static const String getClientAxeByTreatment = '''
    SELECT DISTINCT cl.axe
    FROM Traitement t
    INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
    INNER JOIN Client cl ON c.client_id = cl.client_id
    WHERE t.traitement_id = ?
  ''';

  static const String getPlanningByTreatment = 'SELECT p.planning_id, p.date_debut_planification, p.duree_traitement, p.redondance FROM Planning p WHERE p.traitement_id = ? LIMIT 1';

  static const String countPlanningDetails = 'SELECT COUNT(*) as count FROM PlanningDetails WHERE planning_id = ?';
  static const String countPlanningDetailsByTreatment = 'SELECT COUNT(*) as count FROM Planning WHERE traitement_id = ?';
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
  static const String getRedondanceByTreatment = 'SELECT redondance FROM Planning WHERE traitement_id = ? LIMIT 1';

  static const String getTreatmentIdByType = '''
    SELECT t.traitement_id, t.contrat_id
    FROM Traitement t
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    WHERE t.contrat_id = ? AND tt.typeTraitement = ?
    LIMIT 1
  ''';

  static const String insertPlanningDetail = 'INSERT INTO PlanningDetails (planning_id, date_planification) VALUES (?, ?)';
  static const String getPlanningDetailsByPlanningIdOrdered = 'SELECT DISTINCT pd.planning_detail_id, pd.date_planification FROM PlanningDetails pd WHERE pd.planning_id = ? ORDER BY pd.date_planification ASC';

  // --- PLANNING DETAILS ---
  static const String checkExistingPlanningDetail = 'SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ? AND date_planification = ?';
  static const String insertPlanningDetailWithStatut = 'INSERT INTO PlanningDetails (planning_id, date_planification, statut, facture_id) VALUES (?, ?, ?, ?)';
  static const String updatePlanningDetailFacture = 'UPDATE PlanningDetails SET facture_id = ? WHERE planning_detail_id = ?';
  static const String getPlanningDetailsByPlanningId = 'SELECT * FROM PlanningDetails WHERE planning_id = ? ORDER BY date_planification';
  static const String updatePlanningDetailStatut = 'UPDATE PlanningDetails SET statut = ? WHERE planning_detail_id = ?';
  static const String deletePlanningDetail = 'DELETE FROM PlanningDetails WHERE planning_detail_id = ?';
  static const String getAllPlanningDetails = 'SELECT * FROM PlanningDetails ORDER BY date_planification DESC';

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
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
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
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
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
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
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
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
    INNER JOIN Client c ON ct.client_id = c.client_id
    ORDER BY pd.date_planification DESC
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
    LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
    INNER JOIN Client c ON co.client_id = c.client_id
  ''';

  static const String getDistinctTreatmentTypes = '''
    SELECT DISTINCT tt.typeTraitement
    FROM Traitement t
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    ORDER BY tt.typeTraitement ASC
  ''';

  static const String getDistinctTreatmentTypesByClient = '''
    SELECT DISTINCT tt.typeTraitement
    FROM Traitement t
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
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
  static const String checkPlanningExistence = 'SELECT planning_id FROM Planning WHERE traitement_id = ?';

  // --- HISTORIQUE ---
  static const String getAllHistoriqueDetailed = '''
    SELECT 
      h.historique_id,
      h.date_historique as date,
      h.facture_id,
      pd.date_planification,
      h.contenu as description,
      h.issue,
      h.action
    FROM Historique h
    LEFT JOIN Facture f ON h.facture_id = f.facture_id
    LEFT JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    ORDER BY h.date_historique DESC
    LIMIT ? OFFSET ?
  ''';

  static const String getHistoriqueByCategory = '''
    SELECT 
      h.historique_id,
      h.date_historique as date,
      COALESCE(h.contenu, 'Événement') as description,
      COALESCE(h.issue, 'Non défini') as issue,
      COALESCE(h.action, 'Aucune') as action
    FROM Historique h
    LEFT JOIN Facture f ON h.facture_id = f.facture_id
    WHERE f.axe = ? OR COALESCE(f.axe, ?) = ?
    ORDER BY h.date_historique DESC
    LIMIT 2000
  ''';

  static const String getHistoriqueByClient = '''
    SELECT 
      h.historique_id,
      h.date_historique as date,
      h.contenu as description,
      h.issue,
      h.action
    FROM Historique h
    LEFT JOIN Facture f ON h.facture_id = f.facture_id
    LEFT JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    LEFT JOIN Planning p ON pd.planning_id = p.planning_id
    LEFT JOIN Traitement t ON p.planning_id IN (
      SELECT DISTINCT planning_id FROM PlanningDetails WHERE planning_detail_id = pd.planning_detail_id
    )
    LEFT JOIN Contrat c ON t.contrat_id = c.contrat_id
    WHERE c.client_id = ?
    ORDER BY h.date_historique DESC
  ''';

  static const String getHistoriqueByDateRange = '''
    SELECT 
      h.historique_id, h.date_historique as date, h.facture_id, h.planning_detail_id,
      h.contenu as description, h.issue, h.action
    FROM Historique h
    WHERE h.date_historique >= ? AND h.date_historique <= ?
    ORDER BY h.date_historique DESC
  ''';

  static const String createHistoriqueEvent = '''
    INSERT INTO Historique (facture_id, planning_detail_id, signalement_id, contenu, issue, action)
    VALUES (?, ?, ?, ?, ?, ?)
  ''';

  static const String searchHistorique = '''
    SELECT 
      h.historique_id, h.date_historique as date, h.facture_id, h.planning_detail_id,
      h.contenu as description, h.issue, h.action
    FROM Historique h
    WHERE h.contenu LIKE ? OR h.issue LIKE ? OR h.action LIKE ?
    ORDER BY h.date_historique DESC
  ''';

  static const String deleteOldHistorique = 'DELETE FROM Historique WHERE date_historique < ?';

  // --- NOTIFICATIONS ---
  static const String getNextDayTreatmentsDetailed = '''
    SELECT 
      pd.planning_detail_id,
      pd.planning_id,
      pd.date_planification,
      pd.statut,
      tt.typeTraitement,
      c.nom,
      c.prenom,
      c.telephone,
      c.email,
      p.traitement_id
    FROM PlanningDetails pd
    JOIN Planning p ON pd.planning_id = p.planning_id
    JOIN Traitement t ON p.traitement_id = t.traitement_id
    JOIN Contrat co ON t.contrat_id = co.contrat_id
    JOIN Client c ON co.client_id = c.client_id
    JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    WHERE DATE(pd.date_planification) = ?
    AND pd.statut NOT IN ('Effectué')
    ORDER BY pd.date_planification ASC
  ''';

  static const String getNextDayTreatmentsWithDetails = '''
    SELECT 
      pd.planning_detail_id,
      pd.planning_id,
      pd.date_planification,
      pd.statut,
      tt.typeTraitement,
      c.nom,
      c.prenom,
      c.telephone,
      c.email,
      c.adresse,
      p.traitement_id
    FROM PlanningDetails pd
    JOIN Planning p ON pd.planning_id = p.planning_id
    JOIN Traitement t ON p.traitement_id = t.traitement_id
    JOIN Contrat co ON t.contrat_id = co.contrat_id
    JOIN Client c ON co.client_id = c.client_id
    JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    WHERE DATE(pd.date_planification) = ?
    AND pd.statut NOT IN ('Effectué')
    ORDER BY pd.date_planification ASC
  ''';

  static const String countTodayTreatments = '''
    SELECT COUNT(*) as count
    FROM PlanningDetails
    WHERE DATE(date_planification) = ?
  ''';

  // --- SETTINGS / ACCOUNTS ---
  static const String getUserById = 'SELECT * FROM Account WHERE id_compte = ?';
  static const String updateUserProfile = 'UPDATE Account SET nom = ?, prenom = ?, email = ?, username = ? WHERE id_compte = ?';
  static const String getAllAccounts = 'SELECT * FROM Account ORDER BY nom ASC';
  static const String deleteAccount = 'DELETE FROM Account WHERE id_compte = ?';

  // --- TYPE TRAITEMENT ---
  static const String getAllTypeTraitements = 'SELECT * FROM TypeTraitement ORDER BY id_type_traitement';

  // --- SIGNALEMENTS ---
  static const String getAllSignalements = 'SELECT * FROM Signalement ORDER BY signalement_id DESC';
  static const String createSignalement = 'INSERT INTO Signalement (planning_detail_id, motif, type) VALUES (?, ?, ?)';
  static const String updatePlanningDate = 'UPDATE PlanningDetails SET date_planification = ? WHERE planning_detail_id = ?';

  // --- REMARQUES ---
  static const String createRemarque = 'INSERT INTO Remarque (client_id, planning_detail_id, facture_id, contenu, issue, action) VALUES (?, ?, ?, ?, ?, ?)';
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

  static const String deleteRemarque = 'DELETE FROM Remarque WHERE remarque_id = ?';

  // --- EXPORTS ---
  static const String getExportData = '''
    SELECT 
      f.facture_id as `N° Facture`,
      f.date_traitement as `Date Facture`,
      f.montant as `Montant`,
      f.etat as `Statut`,
      tt.typeTraitement as `Traitement`,
      c.nom as `Nom Client`,
      c.prenom as `Prénom Client`,
      c.axe as `Axe`
    FROM Facture f
    JOIN PlanningDetails pd ON f.facture_id = pd.facture_id
    JOIN Planning p ON pd.planning_id = p.planning_id
    JOIN Traitement t ON p.traitement_id = t.traitement_id
    JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
    JOIN Contrat co ON t.contrat_id = co.contrat_id
    JOIN Client c ON co.client_id = c.client_id
    ORDER BY f.date_traitement DESC
  ''';
}
