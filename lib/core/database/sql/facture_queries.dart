/// Requêtes SQL liées à ce domaine fonctionnel.
class FactureQueries {
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
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
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
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    LEFT JOIN Contrat co ON t.contrat_id = co.contrat_id
    LEFT JOIN Client cl ON co.client_id = cl.client_id
    GROUP BY f.facture_id
    ORDER BY f.date_traitement DESC
    LIMIT ? OFFSET ?
  ''';

  static const String countAllFactures =
      'SELECT COUNT(*) as count FROM Facture';

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
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
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

  static const String updateFacturePrice =
      'UPDATE Facture SET montant = ? WHERE facture_id = ?';

  static const String markFactureAsPaid =
      'UPDATE Facture SET etat = ? WHERE facture_id = ?';

  static const String updateFactureReference =
      'UPDATE Facture SET reference_facture = ? WHERE facture_id = ?';

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

  static const String checkFactureExistence =
      'SELECT facture_id FROM Facture WHERE planning_detail_id = ?';

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

  static const String deleteFacture =
      'DELETE FROM Facture WHERE facture_id = ?';

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
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    JOIN Contrat co ON t.contrat_id = co.contrat_id
    JOIN Client c ON co.client_id = c.client_id
    ORDER BY f.date_traitement DESC
  ''';
}
