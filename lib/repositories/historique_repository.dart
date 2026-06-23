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

  bool _hasMore = true;
  int _currentPage = 0;
  static const int pageSize = 50;

  List<HistoriqueEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  /// Charge tous les événements d'historique avec pagination
  Future<void> loadAllEvents({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = _currentPage * pageSize;
      final rows = await _db
          .query(SqlQueries.getAllHistoriqueDetailed, [pageSize, offset])
          .timeout(
            const Duration(seconds: 50),
            onTimeout: () {
              logger.e('Timeout loading historique page $_currentPage');
              throw TimeoutException('Database query timeout');
            },
          );
      
      final newEvents = rows.map((row) => HistoriqueEvent.fromMap(row)).toList();

      if (refresh) {
        _events = newEvents;
      } else {
        _events.addAll(newEvents);
      }

      _hasMore = newEvents.length == pageSize;
      _currentPage++;

      logger.i('${newEvents.length} interventions d\'historique chargées (Total: ${_events.length})');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement de l\'historique: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge la page suivante
  Future<void> loadNextPage() async {
    await loadAllEvents();
  }

  /// Charge les événements d'historique filtrés par axe (région)
  Future<void> loadEventsByAxe(String axe) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.query(SqlQueries.getHistoriqueByCategory, [axe, axe, axe]);
      _events = rows.map((row) => HistoriqueEvent.fromMap(row)).toList();

      logger.i('${_events.length} événements pour l\'axe $axe chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement par axe: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge l'historique pour un client spécifique
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
      _events = rows.map((row) => HistoriqueEvent.fromMap(row)).toList();

      logger.i('${_events.length} événements du client $clientId chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement client: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre une nouvelle intervention dans l'historique
  Future<int> logIntervention({
    required int factureId,
    int? planningDetailId,
    int? signalementId,
    required String contenu,
    String? issue,
    required String action,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await _db.insert(SqlQueries.createHistoriqueEvent, [
        factureId,
        planningDetailId,
        signalementId,
        contenu,
        issue,
        action,
      ]);

      final newEvent = HistoriqueEvent(
        historiqueId: id,
        factureId: factureId,
        planningDetailId: planningDetailId,
        signalementId: signalementId,
        date: DateTime.now(),
        contenu: contenu,
        issue: issue,
        action: action,
      );
      _events.insert(0, newEvent);

      logger.i('Nouvelle entrée d\'historique créée (ID: $id)');
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la création de l\'historique: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recherche dans l'historique (contenu, issue ou action)
  Future<void> searchEvents(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchTerm = '%$query%';
      final rows = await _db
          .query(SqlQueries.searchHistorique, [searchTerm, searchTerm, searchTerm])
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e('Timeout searching historique for query: $query');
              throw TimeoutException('Database query timeout');
            },
          );
      _events = rows.map((row) => HistoriqueEvent.fromMap(row)).toList();

      logger.i('${_events.length} résultats pour: $query');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la recherche: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nettoie l'historique plus ancien que X jours
  Future<void> cleanupOldEvents(int days) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      await _db.execute(SqlQueries.deleteOldHistorique, [cutoffDate.toIso8601String()]);
      await loadAllEvents();
      logger.i('Nettoyage effectué: événements avant $days jours supprimés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du nettoyage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
