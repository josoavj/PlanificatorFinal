/// Requêtes SQL liées à ce domaine fonctionnel.
class ContratQueries {
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

  static const String deleteContrat =
      'DELETE FROM Contrat WHERE contrat_id = ?';

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

  static const String getTreatmentsByContrat =
      'SELECT traitement_id FROM Traitement WHERE contrat_id = ?';

  static const String countTreatmentsByContrat =
      'SELECT COUNT(*) as count FROM Traitement WHERE contrat_id = ?';

  static const String getTraitementsDetailedByContrat = '''
    SELECT 
        t.traitement_id, 
        t.contrat_id, 
        tt.typeTraitement as nom,
        tt.categorieTraitement as type,
        (SELECT COUNT(*) FROM Planning p2 INNER JOIN PlanningDetails pd2 ON p2.planning_id = pd2.planning_id WHERE p2.traitement_id = t.traitement_id) as total_planif,
        (SELECT COUNT(*) FROM Planning p3 INNER JOIN PlanningDetails pd3 ON p3.planning_id = pd3.planning_id WHERE p3.traitement_id = t.traitement_id AND pd3.statut = 'Effectué') as planif_faites,
        (SELECT GROUP_CONCAT(DISTINCT pd4.statut) FROM Planning p4 INNER JOIN PlanningDetails pd4 ON p4.planning_id = pd4.planning_id WHERE p4.traitement_id = t.traitement_id) as statuts,
        (SELECT SUM(f.montant) 
         FROM Facture f 
         WHERE f.facture_id IN (
             SELECT DISTINCT pd5.facture_id 
             FROM PlanningDetails pd5 
             INNER JOIN Planning p5 ON pd5.planning_id = p5.planning_id 
             WHERE p5.traitement_id = t.traitement_id
         )) as montant_total
    FROM Traitement t
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    WHERE t.contrat_id = ?
  ''';

  static const String getFuturePlanningsByTreatment =
      'SELECT planning_id FROM Planning WHERE traitement_id = ? AND date_debut_planification > ?';

  static const String deleteFuturePlanningDetailsByPlanning = '''
    DELETE FROM PlanningDetails 
    WHERE planning_id = ? AND statut = 'À venir'
  ''';
}
