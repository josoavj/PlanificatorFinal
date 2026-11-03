/// Requêtes SQL liées à ce domaine fonctionnel.
class NotificationQueries {
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
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
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
    INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement AND tt.actif = TRUE
    INNER JOIN TypeTraitementCategorie tc ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
    WHERE DATE(pd.date_planification) = ?
    AND pd.statut NOT IN ('Effectué')
    ORDER BY pd.date_planification ASC
  ''';

  static const String countTodayTreatments = '''
    SELECT COUNT(*) as count
    FROM PlanningDetails
    WHERE DATE(date_planification) = ?
  ''';
}
