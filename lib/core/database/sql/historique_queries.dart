/// Requêtes SQL liées à ce domaine fonctionnel.
class HistoriqueQueries {
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

  static const String deleteOldHistorique =
      'DELETE FROM Historique WHERE date_historique < ?';
}
