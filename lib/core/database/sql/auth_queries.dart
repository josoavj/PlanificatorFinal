/// Requêtes SQL liées à ce domaine fonctionnel.
class AuthQueries {
  static const String login = '''
    SELECT id_compte as userId, email, nom, prenom, password, type_compte, date_creation as createdAt
    FROM Account WHERE username = ?
  ''';

  static const String checkUsername =
      'SELECT id_compte FROM Account WHERE username = ?';

  static const String getUserById = 'SELECT * FROM Account WHERE id_compte = ?';

  static const String updateUserProfile =
      'UPDATE Account SET nom = ?, prenom = ?, email = ?, username = ? WHERE id_compte = ?';

  static const String getAllAccounts = 'SELECT * FROM Account ORDER BY nom ASC';

  static const String deleteAccount = 'DELETE FROM Account WHERE id_compte = ?';
}
