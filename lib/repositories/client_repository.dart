import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class ClientRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = Logger();

  List<Client> _clients = [];
  Client? _currentClient;
  bool _isLoading = false;
  String? _errorMessage;

  List<Client> get clients => _clients;
  Client? get currentClient => _currentClient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge tous les clients
  Future<void> loadClients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          c.client_id, c.nom, c.prenom, c.email, c.telephone, c.adresse, 
          c.categorie, c.nif, c.stat, c.axe,
          COALESCE(COUNT(p.planning_id), 0) as treatment_count
        FROM Client c
        LEFT JOIN Contrat co ON c.client_id = co.client_id
        LEFT JOIN Traitement t ON co.contrat_id = t.contrat_id
        LEFT JOIN Planning p ON t.traitement_id = p.traitement_id
        GROUP BY c.client_id
        ORDER BY c.nom ASC
      ''';

      final rows = await _db.query(sql);
      _clients = rows.map((row) => Client.fromMap(row)).toList();

      logger.i('${_clients.length} clients chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des clients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge un client spécifique
  Future<void> loadClient(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          client_id, nom, prenom, email, telephone, adresse,
          categorie, nif, stat, axe
        FROM Client
        WHERE client_id = ?
      ''';

      final row = await _db.queryOne(sql, [clientId]);
      if (row != null) {
        _currentClient = Client.fromMap(row);
        logger.i('Client $clientId chargé');
      } else {
        _errorMessage = 'Client non trouvé';
      }
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement du client: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée un nouveau client
  Future<int> createClient(Client client) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        INSERT INTO Client (nom, prenom, email, telephone, adresse, 
                           categorie, nif, stat, axe, date_ajout)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      final id = await _db.insert(sql, [
        client.nom,
        client.prenom,
        client.email,
        client.telephone,
        client.adresse,
        client.categorie,
        client.nif,
        client.stat,
        client.axe,
        DateTime.now().toIso8601String().split('T')[0],
      ]);

      final newClient = client.copyWith(clientId: id);
      _clients.add(newClient);

      logger.i('Client créé avec l\'ID: $id');
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la création: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour un client
  Future<void> updateClient(Client client) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        UPDATE Client
        SET nom = ?, prenom = ?, email = ?, telephone = ?, adresse = ?,
            categorie = ?, nif = ?, stat = ?, axe = ?
        WHERE client_id = ?
      ''';

      await _db.execute(sql, [
        client.nom,
        client.prenom,
        client.email,
        client.telephone,
        client.adresse,
        client.categorie,
        client.nif,
        client.stat,
        client.axe,
        client.clientId,
      ]);

      // Mettre à jour dans la liste
      final index = _clients.indexWhere((c) => c.clientId == client.clientId);
      if (index != -1) {
        _clients[index] = client;
      }

      if (_currentClient?.clientId == client.clientId) {
        _currentClient = client;
      }

      logger.i('Client ${client.clientId} mis à jour');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la mise à jour: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime un client avec cascade: contrats → planning → planning_details → factures → remarques
  /// Conforme à Kivy delete_client() (lignes 915-950)
  Future<void> deleteClient(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ 1. Récupérer tous les contrats du client
      const getContratsSQL = '''
        SELECT contrat_id
        FROM Contrat
        WHERE client_id = ?
      ''';

      final contrats = await _db.query(getContratsSQL, [clientId]);
      logger.i('📋 Trouvé ${contrats.length} contrats pour client $clientId');

      // ✅ 2. Pour chaque contrat, supprimer en cascade
      for (final contrat in contrats) {
        final contratId = contrat['contrat_id'] as int;

        // Supprimer tous les planning du contrat
        const getPlanningSQL = '''
          SELECT planning_id
          FROM Planning
          WHERE traitement_id IN (SELECT traitement_id FROM Traitement WHERE contrat_id = ?)
        ''';

        final plannings = await _db.query(getPlanningSQL, [contratId]);

        for (final planning in plannings) {
          final planningId = planning['planning_id'] as int;

          // Supprimer les remarques de tous les planning details
          const getRemarquesSQL = '''
            SELECT r.remarque_id
            FROM Remarque r
            JOIN PlanningDetails pd ON r.planning_details_id = pd.planning_detail_id
            WHERE pd.planning_id = ?
          ''';

          final remarques = await _db.query(getRemarquesSQL, [planningId]);
          for (final remarque in remarques) {
            await _db.execute('DELETE FROM Remarque WHERE remarque_id = ?', [
              remarque['remarque_id'],
            ]);
          }

          // Supprimer les signalements
          await _db.execute(
            'DELETE FROM Signalement WHERE planning_details_id IN (SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ?)',
            [planningId],
          );

          // Supprimer les factures
          await _db.execute(
            'DELETE FROM Facture WHERE planning_details_id IN (SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ?)',
            [planningId],
          );

          // Supprimer les planning details
          await _db.execute(
            'DELETE FROM PlanningDetails WHERE planning_id = ?',
            [planningId],
          );

          // Supprimer le planning
          await _db.execute('DELETE FROM Planning WHERE planning_id = ?', [
            planningId,
          ]);

          logger.i('  ✅ Planning $planningId supprimé (avec cascade)');
        }

        // Supprimer le contrat
        await _db.execute('DELETE FROM Contrat WHERE contrat_id = ?', [
          contratId,
        ]);

        logger.i('  ✅ Contrat $contratId supprimé');
      }

      // ✅ 3. Supprimer le client
      await _db.execute('DELETE FROM Client WHERE client_id = ?', [clientId]);

      _clients.removeWhere((c) => c.clientId == clientId);

      if (_currentClient?.clientId == clientId) {
        _currentClient = null;
      }

      logger.i(
        '✅ Client $clientId supprimé (avec tous les contrats et données associées)',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la suppression: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recherche des clients
  Future<void> searchClients(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          c.client_id, c.nom, c.prenom, c.email, c.telephone, c.adresse,
          c.categorie, c.nif, c.stat, c.axe,
          COALESCE(COUNT(p.planning_id), 0) as treatment_count
        FROM Client c
        LEFT JOIN Contrat co ON c.client_id = co.client_id
        LEFT JOIN Traitement t ON co.contrat_id = t.contrat_id
        LEFT JOIN Planning p ON t.traitement_id = p.traitement_id
        WHERE c.nom LIKE ? OR c.prenom LIKE ? OR c.email LIKE ?
        GROUP BY c.client_id
        ORDER BY c.nom ASC
      ''';

      final searchTerm = '%$query%';
      final rows = await _db.query(sql, [searchTerm, searchTerm, searchTerm]);
      _clients = rows.map((row) => Client.fromMap(row)).toList();

      logger.i('${_clients.length} clients trouvés pour la recherche: $query');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la recherche: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtre les clients par catégorie
  Future<void> filterByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          client_id, nom, prenom, email, telephone, adresse,
          categorie, nif, stat, axe
        FROM Client
        WHERE categorie = ?
        ORDER BY nom ASC
      ''';

      final rows = await _db.query(sql, [category]);
      _clients = rows.map((row) => Client.fromMap(row)).toList();

      logger.i(
        '${_clients.length} clients trouvés pour la catégorie: $category',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du filtrage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les catégories disponibles
  Future<List<String>> getCategories() async {
    try {
      const sql =
          'SELECT DISTINCT categorie FROM Client ORDER BY categorie ASC';

      final rows = await _db.query(sql);
      final categories = rows
          .map((row) => row['categorie'] as String?)
          .whereType<String>()
          .toList();

      logger.i('${categories.length} catégories trouvées');
      return categories;
    } catch (e) {
      logger.e('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  /// Récupère le nombre total de clients
  int getTotalClients() => _clients.length;

  /// Vérifie si un email existe
  Future<bool> emailExists(String email) async {
    try {
      const sql = 'SELECT client_id FROM Client WHERE email = ?';
      final row = await _db.queryOne(sql, [email]);
      return row != null;
    } catch (e) {
      logger.e('Erreur lors de la vérification de l\'email: $e');
      return false;
    }
  }
}
