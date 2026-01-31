import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/index.dart';
import '../services/index.dart';

class AuthRepository extends ChangeNotifier {
  final DatabaseService _db;
  final logger = createLoggerWithFileOutput(name: 'auth_repository');

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Constructeur avec injection optionnelle (pour tests)
  AuthRepository({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Hache un mot de passe avec bcrypt (sécurisé)
  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  /// Vérifie un mot de passe contre son hash bcrypt
  bool _verifyPassword(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (e) {
      logger.e('Erreur lors de la vérification du mot de passe: $e');
      return false;
    }
  }

  /// Connexion utilisateur
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Vérifier que la base de données est connectée
      if (!_db.isConnected) {
        final connected = await _db.connect();
        if (!connected) {
          _errorMessage = 'Erreur de connexion à la base de données';
          logger.e('Base de données non connectée');
          return false;
        }
      }

      const sql = '''
        SELECT 
          id_compte as userId, email, nom, prenom, password, type_compte, date_creation as createdAt
        FROM Account
        WHERE username = ?
      ''';

      final row = await _db.queryOne(sql, [username]);

      if (row == null) {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        logger.w(
          'Tentative de connexion avec un username inexistant: $username',
        );
        return false;
      }

      // Vérifier le mot de passe avec bcrypt
      final storedHash = row['password'] as String;
      if (!_verifyPassword(password, storedHash)) {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        logger.w('Tentative de connexion échouée pour: $username');
        return false;
      }

      _currentUser = User.fromMap(row);
      _isAuthenticated = true;

      logger.i('Utilisateur ${_currentUser!.email} connecté');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la connexion: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inscription utilisateur
  Future<bool> register(
    String username,
    String email,
    String nom,
    String prenom,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Vérifier si le username existe déjà
      const checkSql = 'SELECT id_compte FROM Account WHERE username = ?';
      final existing = await _db.queryOne(checkSql, [username]);

      if (existing != null) {
        _errorMessage = 'Ce nom d\'utilisateur est déjà utilisé';
        logger.w(
          'Tentative d\'inscription avec un username existant: $username',
        );
        return false;
      }

      // Créer le nouvel utilisateur
      const insertSql = '''
        INSERT INTO Account (username, email, nom, prenom, password, type_compte, date_creation)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''';

      final hashedPassword = _hashPassword(password);
      final userId = await _db.insert(insertSql, [
        username,
        email,
        nom,
        prenom,
        hashedPassword,
        'Utilisateur',
        DateTime.now().toIso8601String(),
      ]);

      _currentUser = User(
        userId: userId,
        email: email,
        nom: nom,
        prenom: prenom,
        isAdmin: false,
        createdAt: DateTime.now(),
      );
      _isAuthenticated = true;

      logger.i('Nouvel utilisateur créé: $username');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de l\'inscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Déconnexion
  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    logger.i('Utilisateur déconnecté');
    notifyListeners();
  }

  /// Charge l'utilisateur actuel
  Future<bool> loadCurrentUser(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          id_compte as userId, email, nom, prenom, password, type_comte, date_creation as createdAt
        FROM Account
        WHERE id_compte = ?
      ''';

      final row = await _db.queryOne(sql, [userId]);

      if (row != null) {
        _currentUser = User.fromMap(row);
        _isAuthenticated = true;
        logger.i('Utilisateur $userId chargé');
        return true;
      } else {
        _errorMessage = 'Utilisateur non trouvé';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement de l\'utilisateur: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour le profil utilisateur
  Future<bool> updateProfile(String nom, String prenom) async {
    if (_currentUser == null) {
      _errorMessage = 'Aucun utilisateur connecté';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        UPDATE Account
        SET nom = ?, prenom = ?
        WHERE id_compte = ?
      ''';

      await _db.execute(sql, [nom, prenom, _currentUser!.userId]);

      _currentUser = _currentUser!.copyWith(nom: nom, prenom: prenom);

      logger.i('Profil de l\'utilisateur ${_currentUser!.userId} mis à jour');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la mise à jour du profil: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change le mot de passe
  ///
  /// IMPORTANT: Valide le mot de passe actuel avant de changer.
  /// Utilise bcrypt pour la vérification et le hachage sécurisé.
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) {
      _errorMessage = 'Aucun utilisateur connecté';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1️⃣ Récupérer le hash actuel du mot de passe
      const selectSql = 'SELECT password FROM Account WHERE id_compte = ?';
      final row = await _db.queryOne(selectSql, [_currentUser!.userId]);

      if (row == null) {
        _errorMessage = 'Utilisateur non trouvé';
        logger.e('Utilisateur ${_currentUser!.userId} introuvable');
        return false;
      }

      // 2️⃣ Vérifier que l'ancien mot de passe est correct (protection contre les accès non autorisés)
      final storedHash = row['password'] as String;
      if (!_verifyPassword(oldPassword, storedHash)) {
        _errorMessage = 'Ancien mot de passe incorrect';
        logger.w(
          'Tentative de changement de mot de passe échouée (mauvais ancien pwd) pour utilisateur ${_currentUser!.userId}',
        );
        return false;
      }

      // 3️⃣ Hacher le nouveau mot de passe
      final hashedPassword = _hashPassword(newPassword);

      // 4️⃣ Mettre à jour le mot de passe
      const updateSql = '''
        UPDATE Account
        SET password = ?
        WHERE id_compte = ?
      ''';
      await _db.execute(updateSql, [hashedPassword, _currentUser!.userId]);

      logger.i(
        '✅ Mot de passe de l\'utilisateur ${_currentUser!.userId} changé avec succès',
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du changement de mot de passe: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime le compte
  Future<bool> deleteAccount(String password) async {
    if (_currentUser == null) {
      _errorMessage = 'Aucun utilisateur connecté';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = 'DELETE FROM Account WHERE id_compte = ?';

      await _db.execute(sql, [_currentUser!.userId]);

      final deletedUserId = _currentUser!.userId;
      _currentUser = null;
      _isAuthenticated = false;

      logger.i('Compte de l\'utilisateur $deletedUserId supprimé');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la suppression du compte: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifie si le username existe
  Future<bool> usernameExists(String username) async {
    try {
      const sql = 'SELECT id_compte FROM Account WHERE username = ?';
      final row = await _db.queryOne(sql, [username]);
      return row != null;
    } catch (e) {
      logger.e('Erreur lors de la vérification du username: $e');
      return false;
    }
  }
}
