import 'dart:async';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../core/sql_queries.dart';

class ClientRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final QueryCacheService _cache = QueryCacheService();
  final logger = createLoggerWithFileOutput(name: 'client_repository');

  List<Client> _clients = [];
  Client? _currentClient;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoadingPage = false; // Prevent concurrent page loads

  // Pagination
  static const int paginationSize = 50;
  int _currentPage = 0;
  bool _hasMoreClients = true;

  List<Client> get clients => _clients;
  Client? get currentClient => _currentClient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreClients => _hasMoreClients;

  /// Retourne true seulement si c'est le chargement initial (pas d'aucunes données)
  /// Utilisé pour montrer le LoadingWidget, pas pour le spinner de pagination
  bool get isInitiallyLoading => _isLoading && _clients.isEmpty;

  /// Charge les clients par page (pagination)
  /// Page 0 = 50 premiers clients, Page 1 = 50 suivants, etc.
  /// Performance: -50% mémoire au démarrage
  Future<void> loadClientsPage(int page) async {
    if (_isLoadingPage) {
      logger.w('loadClientsPage already in progress, skipping duplicate call');
      return;
    }
    _isLoadingPage = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    logger.i('=== START loadClientsPage($page) ===');

    try {
      logger.i('Calc offset: page=$page * paginationSize=$paginationSize');
      final offset = page * paginationSize;
      final cacheKey = CacheKeys.clientsList(page);
      logger.i('Get cache with key: $cacheKey');
      final cachedRows = _cache.get(cacheKey);

      if (cachedRows != null) {
        logger.i(
          'Cache HIT: Page $page (${cachedRows.length} clients from cache)',
        );
        if (page == 0) {
          _clients = cachedRows.map((row) => Client.fromMap(row)).toList();
        } else {
          _clients.addAll(
            cachedRows.map((row) => Client.fromMap(row)).toList(),
          );
        }
        _currentPage = page;
        _isLoading = false;
        _isLoadingPage = false;
        notifyListeners();
        logger.i('=== DONE loadClientsPage($page) from cache ===');
        return;
      }

      logger.i('Cache MISS: Executing SQL query for page $page...');
      logger.i('DB connection status: ${_db.isConnected}');

      final rows = await _db
          .query(SqlQueries.getClientsPaginated, [paginationSize, offset])
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              logger.e('TIMEOUT at 60s for page $page with offset=$offset');
              throw TimeoutException(
                'Timeout loading clients page $page after 60 seconds',
              );
            },
          );

      logger.i('SQL OK: ${rows.length} rows from DB');

      // Mettre en cache la page
      _cache.set(cacheKey, rows);
      logger.i('Cache set for page $page');

      final pageClients = rows.map((row) => Client.fromMap(row)).toList();
      logger.i('Mapped ${pageClients.length} rows to Client objects');

      if (page == 0) {
        _clients = pageClients;
      } else {
        _clients.addAll(pageClients);
      }

      _hasMoreClients = pageClients.length == paginationSize;
      _currentPage = page;

      logger.i(
        '=== DONE loadClientsPage($page) - Total: ${_clients.length} clients ===',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('!!! ERROR loadClientsPage($page): $e !!!');
      if (e is Error) {
        logger.e('Stack: ${e.stackTrace}');
      }
    } finally {
      _isLoading = false;
      _isLoadingPage = false;
      notifyListeners();
    }
  }

  /// Charge tous les clients (pour compatibilité - utilise pagination)
  /// Cache: 15 minutes par défaut
  Future<void> loadClients() async {
    logger.i('=== START loadClients (wrapper) ===');
    // Déléguer à loadClientsPage directement
    await loadClientsPage(0);
    logger.i('=== DONE loadClients (wrapper) ===');
  }

  /// Charger la page suivante (pour scroll infini)
  Future<void> loadNextPage() async {
    if (_isLoading || !_hasMoreClients) return;
    await loadClientsPage(_currentPage + 1);
  }

  /// Charge un client spécifique (avec cache)
  ///
  /// Cache: 15 minutes par défaut
  /// Indexes SQL: idx_client_id_pk (PRIMARY KEY)
  Future<void> loadClient(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Vérifier le cache d'abord
      final cacheKey = CacheKeys.client(clientId);
      final cachedRow = _cache.get(cacheKey);

      if (cachedRow != null) {
        logger.i('Cache HIT: Loading client $clientId from cache');
        _currentClient = Client.fromMap(cachedRow as Map<String, dynamic>);
        _isLoading = false;
        notifyListeners();
        return;
      }

      logger.i('Cache MISS: Executing SQL query for client $clientId');

      final row = await _db
          .queryOne(SqlQueries.getClientById, [clientId])
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e('TIMEOUT at 30s for loadClient($clientId)');
              throw TimeoutException(
                'Timeout loading client $clientId after 30 seconds',
              );
            },
          );
      if (row != null) {
        // Mettre en cache le résultat
        _cache.set(cacheKey, row);
        _currentClient = Client.fromMap(row);
        logger.i('Client $clientId loaded');
      } else {
        _errorMessage = 'Client not found';
      }
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Error loading client: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée un nouveau client
  ///
  /// Invalide le cache des clients après création
  Future<int> createClient(Client client) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _db.insert(SqlQueries.createClient, [
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

      logger.i('Client created with ID: $id');

      // Invalider le cache des clients
      _cache.invalidateByEntity('client');

      return id;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Error creating client: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour un client
  ///
  /// Invalide le cache après mise à jour
  Future<void> updateClient(Client client) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.execute(SqlQueries.updateClient, [
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

      logger.i('Client ${client.clientId} updated');

      // Invalider le cache spécifique et la liste
      _cache.invalidateByEntity('client', entityId: client.clientId);
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Error updating client: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime un client avec cascade: contrats → planning → planning_details → factures → remarques
  ///
  /// Invalide le cache après suppression
  /// Utilisé TRANSACTION pour garantir l'intégrité
  Future<void> deleteClient(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.transaction((conn) async {
        // 1. Récupérer tous les contrats du client
        final contrats = await conn.query(
          'SELECT contrat_id FROM Contrat WHERE client_id = ?',
          [clientId],
        );

        // 2. Pour chaque contrat, supprimer en cascade
        for (final contrat in contrats) {
          final contratId = contrat['contrat_id'] as int;

          // Récupérer les plannings du contrat
          final plannings = await conn.query(
            '''
            SELECT planning_id FROM Planning 
            WHERE traitement_id IN (SELECT traitement_id FROM Traitement WHERE contrat_id = ?)
            ''',
            [contratId],
          );

          for (final planning in plannings) {
            final planningId = planning['planning_id'] as int;

            // Suppression en cascade (l'ordre est important si FK non CASCADE en DB)
            // Note: Planificator.sql a ON DELETE CASCADE sur la plupart des FK
            // Mais on nettoie ici pour être sûr ou gérer les tables sans CASCADE.

            await conn.query(
              'DELETE FROM Remarque WHERE planning_detail_id IN (SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ?)',
              [planningId],
            );

            await conn.query(
              'DELETE FROM Signalement WHERE planning_detail_id IN (SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ?)',
              [planningId],
            );

            await conn.query(
              'DELETE FROM Facture WHERE planning_detail_id IN (SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ?)',
              [planningId],
            );

            await conn.query(
              'DELETE FROM PlanningDetails WHERE planning_id = ?',
              [planningId],
            );

            await conn.query('DELETE FROM Planning WHERE planning_id = ?', [
              planningId,
            ]);
          }

          // Supprimer le contrat
          await conn.query('DELETE FROM Contrat WHERE contrat_id = ?', [
            contratId,
          ]);
        }

        // 3. Supprimer le client
        await conn.query('DELETE FROM Client WHERE client_id = ?', [clientId]);
      });

      _clients.removeWhere((c) => c.clientId == clientId);

      if (_currentClient?.clientId == clientId) {
        _currentClient = null;
      }

      logger.i('Client $clientId supprimé avec succès via transaction');

      // Invalider le cache après suppression
      _cache.invalidateByEntity('client', entityId: clientId);
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la suppression du client: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recherche des clients (seulement ceux avec contrats)
  Future<void> searchClients(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchTerm = '%$query%';
      final rows = await _db
          .query(SqlQueries.searchClients, [searchTerm, searchTerm, searchTerm])
          .timeout(
            const Duration(seconds: 40),
            onTimeout: () {
              logger.e('Timeout searching clients for query: $query');
              throw TimeoutException('Database query timeout');
            },
          );
      _clients = rows.map((row) => Client.fromMap(row)).toList();

      // Tri garantis par Dart (en plus du SQL)
      _clients.sort((a, b) {
        final compareNom = (a.nom).compareTo(b.nom);
        if (compareNom != 0) return compareNom;
        return (a.prenom).compareTo(b.prenom);
      });

      logger.i('${_clients.length} clients trouvés pour la recherche: $query');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la recherche: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtre les clients par catégorie (seulement ceux avec contrats)
  Future<void> filterByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          c.client_id, c.nom, c.prenom, c.email, c.telephone, c.adresse,
          c.categorie, c.nif, c.stat, c.axe,
          COALESCE(COUNT(DISTINCT t.traitement_id), 0) as treatment_count
        FROM Client c
        LEFT JOIN Contrat co ON c.client_id = co.client_id
        LEFT JOIN Traitement t ON co.contrat_id = t.contrat_id
        WHERE c.categorie = ?
        GROUP BY c.client_id
        HAVING COUNT(DISTINCT co.contrat_id) > 0
        ORDER BY COALESCE(c.nom, 'Z') ASC, COALESCE(c.prenom, '') ASC
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
      final row = await _db
          .queryOne(sql, [email])
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              logger.e('Timeout checking email existence: $email');
              throw TimeoutException('Database query timeout');
            },
          );
      return row != null;
    } catch (e) {
      logger.e('Erreur lors de la vérification de l\'email: $e');
      return false;
    }
  }
}
