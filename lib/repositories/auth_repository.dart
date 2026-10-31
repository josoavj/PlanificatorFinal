import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../core/sql_queries.dart';
import '../utils/email_validator.dart';
import '../utils/password_validator.dart';

class AuthRepository extends ChangeNotifier {
  final DatabaseService _db;
  final logger = createLoggerWithFileOutput(name: 'auth_repository');

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _lastGeneratedRecoveryCode;
  final RateLimitService _rateLimit = RateLimitService();
  final RateLimitService _recoveryRateLimit = RateLimitService();

  // Constructeur avec injection optionnelle (pour tests)
  AuthRepository({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get lastGeneratedRecoveryCode => _lastGeneratedRecoveryCode;

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
      await _rateLimit.check(username);
      // Vérifier que la base de données est connectée
      if (!_db.isConnected) {
        final connected = await _db.connect();
        if (!connected) {
          _errorMessage = 'Erreur de connexion à la base de données';
          logger.e('Base de données non connectée');
          return false;
        }
      }

      final row = await _db
          .queryOne(SqlQueries.login, params: [username])
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              logger.e('Timeout querying user account for login: $username');
              throw TimeoutException('Database query timeout');
            },
          );

      if (row == null) {
        await _rateLimit.recordFailure(username);
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        logger.w(
          'Tentative de connexion avec un username inexistant: $username',
        );
        return false;
      }

      // Vérifier le mot de passe avec bcrypt
      final storedHash = row['password'] as String;
      if (!_verifyPassword(password, storedHash)) {
        await _rateLimit.recordFailure(username);
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        logger.w('Tentative de connexion échouée pour: $username');
        return false;
      }

      _currentUser = User.fromMap(row);
      _isAuthenticated = true;
      await _rateLimit.recordSuccess(username);

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

  /// Inscription publique : crée uniquement des comptes Utilisateur.
  Future<bool> register(
    String username,
    String email,
    String nom,
    String prenom,
    String password,
  ) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = EmailValidator.normalizeEmail(email);
    if (normalizedUsername.length < 3 ||
        !EmailValidator.isValidEmail(normalizedEmail)) {
      _errorMessage = 'Identifiant ou adresse e-mail invalide';
      return false;
    }
    final passwordError = PasswordValidator.validatePassword(
      password,
      password,
      nom.trim(),
      prenom.trim(),
    );
    if (passwordError.isNotEmpty) {
      _errorMessage = passwordError;
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureAccountBootstrapLock();
      await _db.transaction((conn) async {
        await conn.query(
          'SELECT lock_id FROM AccountBootstrapLock WHERE lock_id = 1 FOR UPDATE',
        );
        final countRows = await conn.query(
          'SELECT COUNT(*) AS count FROM Account',
        );
        if (((countRows.first['count'] as num?)?.toInt() ?? 0) == 0) {
          throw StateError('Créez d’abord le compte administrateur initial.');
        }
        final existing = await conn.query(
          'SELECT id_compte FROM Account WHERE username = ? OR email = ?',
          [normalizedUsername, normalizedEmail],
        );
        if (existing.isNotEmpty) {
          throw StateError('Cet identifiant ou e-mail est déjà utilisé');
        }
        await conn.query(
          """INSERT INTO Account (
            username, email, nom, prenom, password, type_compte, date_creation,
            recovery_code_hash, recovery_code_created_at
          ) VALUES (?, ?, ?, ?, ?, 'Utilisateur', ?, NULL, NULL)""",
          [
            normalizedUsername,
            normalizedEmail,
            nom.trim(),
            prenom.trim(),
            _hashPassword(password),
            DateTime.now().toIso8601String(),
          ],
        );
      });
      _currentUser = null;
      _isAuthenticated = false;
      _lastGeneratedRecoveryCode = null;
      logger.i('Nouvel utilisateur créé: $normalizedUsername (Utilisateur)');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de l’inscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Création unique du premier administrateur d’une base vide.
  Future<String?> createFirstAdmin(
    String username,
    String email,
    String nom,
    String prenom,
    String password,
  ) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = EmailValidator.normalizeEmail(email);
    if (normalizedUsername.length < 3 ||
        !EmailValidator.isValidEmail(normalizedEmail)) {
      _errorMessage = 'Identifiant ou adresse e-mail invalide';
      return null;
    }
    final passwordError = PasswordValidator.validatePassword(
      password,
      password,
      nom.trim(),
      prenom.trim(),
    );
    if (passwordError.isNotEmpty) {
      _errorMessage = passwordError;
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureAccountBootstrapLock();
      final recoveryCode = _generateRecoveryCode();
      await _db.transaction((conn) async {
        await conn.query(
          'SELECT lock_id FROM AccountBootstrapLock WHERE lock_id = 1 FOR UPDATE',
        );
        final countRows = await conn.query(
          'SELECT COUNT(*) AS count FROM Account',
        );
        if (((countRows.first['count'] as num?)?.toInt() ?? 0) != 0) {
          throw StateError('Un compte existe déjà dans cette base de données.');
        }
        final existing = await conn.query(
          'SELECT id_compte FROM Account WHERE username = ? OR email = ?',
          [normalizedUsername, normalizedEmail],
        );
        if (existing.isNotEmpty) {
          throw StateError('Cet identifiant ou e-mail est déjà utilisé');
        }
        await conn.query(
          """INSERT INTO Account (
            username, email, nom, prenom, password, type_compte, date_creation,
            recovery_code_hash, recovery_code_created_at
          ) VALUES (?, ?, ?, ?, ?, 'Administrateur', ?, ?, ?)""",
          [
            normalizedUsername,
            normalizedEmail,
            nom.trim(),
            prenom.trim(),
            _hashPassword(password),
            DateTime.now().toIso8601String(),
            _hashPassword(recoveryCode),
            DateTime.now().toIso8601String(),
          ],
        );
      });
      _currentUser = null;
      _isAuthenticated = false;
      _lastGeneratedRecoveryCode = recoveryCode;
      logger.i('Premier compte administrateur créé: $normalizedUsername');
      return recoveryCode;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la création du premier admin: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureAccountBootstrapLock() async {
    await _db.execute(
      'CREATE TABLE IF NOT EXISTS AccountBootstrapLock '
      '(lock_id INT NOT NULL PRIMARY KEY) ENGINE=InnoDB',
    );
    await _db.execute(
      'INSERT IGNORE INTO AccountBootstrapLock (lock_id) VALUES (1)',
    );
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    if (!isAdmin) throw StateError('Accès réservé aux administrateurs.');
    return _db.query(
      'SELECT id_compte, username, email, nom, prenom, type_compte, date_creation '
      'FROM Account ORDER BY nom, prenom, username',
    );
  }

  Future<bool> updateAccountRole(
    int accountId,
    String newRole,
    String adminPassword,
  ) async {
    if (!isAdmin || _currentUser == null) {
      _errorMessage = 'Accès réservé aux administrateurs.';
      return false;
    }
    if (accountId == _currentUser!.userId) {
      _errorMessage = 'Vous ne pouvez pas modifier votre propre rôle.';
      return false;
    }
    if (!const {'Administrateur', 'Utilisateur'}.contains(newRole)) {
      _errorMessage = 'Type de compte invalide.';
      return false;
    }
    if (!await verifyCurrentPassword(adminPassword)) {
      _errorMessage = 'Mot de passe administrateur incorrect.';
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureAccountBootstrapLock();
      await _db.transaction((conn) async {
        await conn.query(
          'SELECT lock_id FROM AccountBootstrapLock WHERE lock_id = 1 FOR UPDATE',
        );
        final actor = await conn.query(
          'SELECT type_compte FROM Account WHERE id_compte = ?',
          [_currentUser!.userId],
        );
        if (actor.isEmpty || actor.first['type_compte'] != 'Administrateur') {
          throw StateError(
            'Vos privilèges administrateur ne sont plus actifs.',
          );
        }
        final rows = await conn.query(
          'SELECT type_compte FROM Account WHERE id_compte = ?',
          [accountId],
        );
        if (rows.isEmpty) throw StateError('Compte introuvable.');
        final oldRole = rows.first['type_compte'] as String?;
        final admins = await conn.query(
          "SELECT COUNT(*) AS count FROM Account WHERE type_compte = 'Administrateur'",
        );
        final count = (admins.first['count'] as num?)?.toInt() ?? 0;
        if (oldRole == 'Administrateur' && newRole != oldRole && count <= 1) {
          throw StateError('Il doit rester au moins un administrateur.');
        }
        if (oldRole != 'Administrateur' &&
            newRole == 'Administrateur' &&
            count >= 3) {
          throw StateError('La base est limitée à trois administrateurs.');
        }
        await conn.query(
          'UPDATE Account SET type_compte = ? WHERE id_compte = ?',
          [newRole, accountId],
        );
      });
      return true;
    } catch (e) {
      _errorMessage = e is StateError
          ? e.message.toString()
          : 'Impossible de modifier le rôle.';
      logger.e('Erreur modification rôle compte $accountId: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adminDeleteAccount(int accountId, String adminPassword) async {
    if (!isAdmin || _currentUser == null) {
      _errorMessage = 'Accès réservé aux administrateurs.';
      return false;
    }
    if (accountId == _currentUser!.userId) {
      _errorMessage =
          'Utilisez « Supprimer mon compte » pour votre propre compte.';
      return false;
    }
    if (!await verifyCurrentPassword(adminPassword)) {
      _errorMessage = 'Mot de passe administrateur incorrect.';
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureAccountBootstrapLock();
      await _db.transaction((conn) async {
        await conn.query(
          'SELECT lock_id FROM AccountBootstrapLock WHERE lock_id = 1 FOR UPDATE',
        );
        final actor = await conn.query(
          'SELECT type_compte FROM Account WHERE id_compte = ?',
          [_currentUser!.userId],
        );
        if (actor.isEmpty || actor.first['type_compte'] != 'Administrateur') {
          throw StateError(
            'Vos privilèges administrateur ne sont plus actifs.',
          );
        }
        final rows = await conn.query(
          'SELECT type_compte FROM Account WHERE id_compte = ?',
          [accountId],
        );
        if (rows.isEmpty) throw StateError('Compte introuvable.');
        if (rows.first['type_compte'] == 'Administrateur') {
          final admins = await conn.query(
            "SELECT COUNT(*) AS count FROM Account WHERE type_compte = 'Administrateur'",
          );
          if (((admins.first['count'] as num?)?.toInt() ?? 0) <= 1) {
            throw StateError('Il doit rester au moins un administrateur.');
          }
        }
        await conn.query('DELETE FROM Account WHERE id_compte = ?', [
          accountId,
        ]);
      });
      return true;
    } catch (e) {
      _errorMessage = e is StateError
          ? e.message.toString()
          : 'Impossible de supprimer ce compte.';
      logger.e('Erreur suppression compte $accountId: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPasswordWithRecoveryCode(
    String email,
    String recoveryCode,
    String newPassword,
  ) async {
    if (newPassword.length < 8) {
      _errorMessage =
          'Le nouveau mot de passe doit contenir au moins 8 caractères';
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _recoveryRateLimit.check(email);
      final row = await _db.queryOne(
        'SELECT id_compte, password, recovery_code_hash, nom, prenom '
        'FROM Account WHERE email = ? AND type_compte = ?',
        params: [email.trim(), 'Administrateur'],
        useCache: false,
      );
      final recoveryHash = row?['recovery_code_hash'] as String?;
      if (row == null ||
          recoveryHash == null ||
          !_verifyPassword(recoveryCode.trim().toUpperCase(), recoveryHash)) {
        await _recoveryRateLimit.recordFailure(email);
        _errorMessage = 'Code de récupération invalide';
        return false;
      }
      final passwordError = PasswordValidator.validatePassword(
        newPassword,
        newPassword,
        row['nom'] as String? ?? '',
        row['prenom'] as String? ?? '',
      );
      if (passwordError.isNotEmpty) {
        _errorMessage = passwordError;
        return false;
      }
      await _db.execute(
        'UPDATE Account SET password = ?, recovery_code_hash = NULL, '
        'recovery_code_created_at = NULL WHERE id_compte = ?',
        [_hashPassword(newPassword), row['id_compte']],
      );
      await _recoveryRateLimit.recordSuccess(email);
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de réinitialiser le mot de passe';
      logger.e('Erreur récupération compte: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _generateRecoveryCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      16,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
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
          id_compte as userId, email, nom, prenom, password, type_compte, date_creation as createdAt
        FROM Account
        WHERE id_compte = ?
      ''';

      final row = await _db.queryOne(sql, params: [userId]);

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

  /// Met à jour le profil utilisateur complet
  Future<bool> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String username,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'Aucun utilisateur connecté';
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Vérifier si le username ou email est déjà pris par quelqu'un d'autre
      const checkSql =
          'SELECT id_compte FROM Account WHERE (username = ? OR email = ?) AND id_compte != ?';
      final existing = await _db.query(checkSql, [
        username,
        email,
        _currentUser!.userId,
      ]);

      if (existing.isNotEmpty) {
        _errorMessage =
            'Cet identifiant ou cet email est déjà utilisé par un autre compte';
        return false;
      }

      // 2. Mettre à jour en base de données
      const sql = '''
        UPDATE Account
        SET nom = ?, prenom = ?, email = ?, username = ?
        WHERE id_compte = ?
      ''';

      await _db.execute(sql, [
        nom,
        prenom,
        email,
        username,
        _currentUser!.userId,
      ]);

      // 3. Mettre à jour l'état local
      _currentUser = _currentUser!.copyWith(
        nom: nom,
        prenom: prenom,
        email: email,
      );

      logger.i(
        'Profil complet de l\'utilisateur ${_currentUser!.userId} mis à jour',
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la mise à jour complète du profil: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifie le mot de passe actuel de l'utilisateur
  Future<bool> verifyCurrentPassword(String password) async {
    if (_currentUser == null) return false;

    try {
      const sql = 'SELECT password FROM Account WHERE id_compte = ?';
      final row = await _db.queryOne(sql, params: [_currentUser!.userId]);
      if (row == null) return false;

      return _verifyPassword(password, row['password'] as String);
    } catch (e) {
      logger.e('Erreur lors de la vérification du mot de passe: $e');
      return false;
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
      final row = await _db.queryOne(selectSql, params: [_currentUser!.userId]);

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
        ' Mot de passe de l\'utilisateur ${_currentUser!.userId} changé avec succès',
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
      if (!await verifyCurrentPassword(password)) {
        _errorMessage = 'Mot de passe incorrect';
        return false;
      }
      await _db.execute(
        'CREATE TABLE IF NOT EXISTS AccountBootstrapLock '
        '(lock_id INT NOT NULL PRIMARY KEY) ENGINE=InnoDB',
      );
      await _db.execute(
        'INSERT IGNORE INTO AccountBootstrapLock (lock_id) VALUES (1)',
      );
      await _db.transaction((conn) async {
        await conn.query(
          'SELECT lock_id FROM AccountBootstrapLock WHERE lock_id = 1 FOR UPDATE',
        );
        if (isAdmin) {
          final admins = await conn.query(
            "SELECT COUNT(*) AS count FROM Account WHERE type_compte = 'Administrateur'",
          );
          if (((admins.first['count'] as num?)?.toInt() ?? 0) <= 1) {
            throw StateError(
              'Transférez le rôle administrateur avant de supprimer ce dernier compte admin',
            );
          }
        }
        await conn.query('DELETE FROM Account WHERE id_compte = ?', [
          _currentUser!.userId,
        ]);
      });

      final deletedUserId = _currentUser!.userId;
      _currentUser = null;
      _isAuthenticated = false;

      logger.i('Compte de l\'utilisateur $deletedUserId supprimé');
      return true;
    } catch (e) {
      _errorMessage = e is StateError ? e.message.toString() : e.toString();
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
      final row = await _db.queryOne(sql, params: [username]);
      return row != null;
    } catch (e) {
      logger.e('Erreur lors de la vérification du username: $e');
      return false;
    }
  }

  /// Vérifie si la base de données ne contient aucun utilisateur
  /// Utile pour accorder automatiquement le rôle Admin au premier inscrit
  Future<bool> hasNoUsers() async {
    try {
      const sql = 'SELECT COUNT(*) as count FROM Account';
      final result = await _db.queryOne(sql);
      final count = (result?['count'] as num?)?.toInt() ?? 0;
      return count == 0;
    } catch (e) {
      logger.e('Erreur lors du comptage des utilisateurs: $e');
      return false;
    }
  }
}
