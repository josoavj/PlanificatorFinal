import 'dart:async';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../core/sql_queries.dart';

class HistoriqueRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'historique_repository');

  List<HistoriqueEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HistoriqueEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge tous les événements d'historique avec données de factures
  /// Utilise la vraie table Historique pour les données complètes
  Future<void> loadAllEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db
          .query(SqlQueries.getAllHistoriqueDetailed)
          .timeout(
            const Duration(seconds: 50),
            onTimeout: () {
              logger.e('Timeout loading all historique events');
              throw TimeoutException('Database query timeout');
            },
          );
      _events = rows.map((row) {
        return HistoriqueEvent(
          historiqueId: row['historique_id'] as int? ?? 0,
          type: 'historique',
          description: row['description'] ?? 'Événement',
          date: DateTime.tryParse(row['date'].toString()) ?? DateTime.now(),
          details: '${row['issue'] ?? ''} | Action: ${row['action'] ?? ''}',
        );
      }).toList();

      logger.i('${_events.length} événements d\'historique chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement de l\'historique: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les événements d'historique filtrés par type/catégorie
  Future<void> loadEventsByCategory(String categorie) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.query(SqlQueries.getHistoriqueByCategory, [categorie, categorie, categorie]);
      _events = rows.map((row) {
        return HistoriqueEvent(
          historiqueId: row['historique_id'] as int? ?? 0,
          type: 'historique_categorie',
          description: row['description'] ?? 'Événement',
          date: DateTime.tryParse(row['date'].toString()) ?? DateTime.now(),
          details: '${row['issue'] ?? ''} | Action: ${row['action'] ?? ''}',
        );
      }).toList();

      logger.i('${_events.length} événements de catégorie $categorie chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement de l\'historique: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les événements d'historique pour un client
  Future<void> loadEventsForClient(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db
          .query(SqlQueries.getHistoriqueByClient, [clientId])
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              logger.e('Timeout loading historique for client $clientId');
              throw TimeoutException('Database query timeout');
            },
          );
      _events = rows.map((row) {
        return HistoriqueEvent(
          historiqueId: row['historique_id'] as int? ?? 0,
          type: 'historique_client',
          description: row['description'] ?? 'Événement',
          date: DateTime.tryParse(row['date'].toString()) ?? DateTime.now(),
          details: '${row['issue'] ?? ''} | Action: ${row['action'] ?? ''}',
        );
      }).toList();

      logger.i('${_events.length} événements du client $clientId chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement de l\'historique: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les événements d'historique pour une plage de dates
  Future<void> loadEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.query(SqlQueries.getHistoriqueByDateRange, [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ]);
      _events = rows.map((row) => HistoriqueEvent.fromMap(row)).toList();

      logger.i('${_events.length} événements trouvés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement de l\'historique: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre un nouvel événement d'historique
  Future<int> logEvent(String type, String description, String details) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _db.insert(SqlQueries.createHistoriqueEvent, [
        type,
        description,
        DateTime.now().toIso8601String(),
        details,
      ]);

      final newEvent = HistoriqueEvent(
        historiqueId: id,
        type: type,
        description: description,
        date: DateTime.now(),
        details: details,
      );
      _events.insert(0, newEvent);

      logger.i('Événement d\'historique créé: $type');
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la création de l\'événement: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre la création d'un client
  Future<void> logClientCreation(int clientId, String clientName) async {
    await logEvent(
      'client',
      'Nouveau client créé',
      'clientId:$clientId,nom:$clientName',
    );
  }

  /// Enregistre la modification d'un client
  Future<void> logClientUpdate(int clientId, String clientName) async {
    await logEvent(
      'client',
      'Client modifié',
      'clientId:$clientId,nom:$clientName',
    );
  }

  /// Enregistre la suppression d'un client
  Future<void> logClientDeletion(int clientId, String clientName) async {
    await logEvent(
      'client',
      'Client supprimé',
      'clientId:$clientId,nom:$clientName',
    );
  }

  /// Enregistre la création d'une facture
  Future<void> logFactureCreation(int factureId, double montant) async {
    await logEvent(
      'facture',
      'Nouvelle facture créée',
      'factureId:$factureId,montant:$montant',
    );
  }

  /// Enregistre le paiement d'une facture
  Future<void> logFacturePayment(int factureId, double montant) async {
    await logEvent(
      'paiement',
      'Facture payée',
      'factureId:$factureId,montant:$montant',
    );
  }

  /// Enregistre la création d'un contrat
  Future<void> logContratCreation(int contratId) async {
    await logEvent('contrat', 'Nouveau contrat créé', 'contratId:$contratId');
  }

  /// Enregistre la fin d'un contrat
  Future<void> logContratEnd(int contratId) async {
    await logEvent('contrat', 'Contrat terminé', 'contratId:$contratId');
  }

  /// Recherche dans l'historique
  Future<void> searchEvents(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchTerm = '%$query%';
      final rows = await _db
          .query(SqlQueries.searchHistorique, [searchTerm, searchTerm])
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e('Timeout searching historique for query: $query');
              throw TimeoutException('Database query timeout');
            },
          );
      _events = rows.map((row) => HistoriqueEvent.fromMap(row)).toList();

      logger.i(
        '${_events.length} événements trouvés pour la recherche: $query',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la recherche: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les statistiques d'historique
  Map<String, int> getStatistics() {
    final stats = <String, int>{};
    for (final event in _events) {
      stats[event.type] = (stats[event.type] ?? 0) + 1;
    }
    return stats;
  }

  /// Nettoie l'historique plus ancien que X jours
  Future<void> cleanupOldEvents(int days) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      await _db.execute(SqlQueries.deleteOldHistorique, [cutoffDate.toIso8601String()]);

      // Recharger les événements
      await loadAllEvents();

      logger.i('Événements plus vieux que $days jours supprimés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du nettoyage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
