/// Requêtes SQL liées à ce domaine fonctionnel.
class ClientQueries {
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

  static const String checkEmail =
      'SELECT client_id FROM Client WHERE email = ?';

  static const String getCategories =
      'SELECT DISTINCT categorie FROM Client ORDER BY categorie ASC';

  static const String getAllClientsBasic = '''
    SELECT 
      client_id, nom, prenom, email, telephone, adresse, 
      categorie, nif, stat, axe
    FROM Client
    ORDER BY nom ASC
  ''';
}
