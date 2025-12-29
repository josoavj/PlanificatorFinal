import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class PlanningRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = Logger();

  List<PlanningEvent> _events = [];
  PlanningEvent? _currentEvent;
  bool _isLoading = false;
  String? _errorMessage;

  List<PlanningEvent> get events => _events;
  PlanningEvent? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge tous les événements
  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          planningId, contratId, titre, description, dateDebut, dateFin
        FROM Planning
        ORDER BY dateDebut DESC
      ''';

      final rows = await _db.query(sql);
      _events = rows.map((row) => PlanningEvent.fromMap(row)).toList();

      logger.i('${_events.length} événements chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des événements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les événements d'un contrat
  Future<void> loadEventsForContrat(int contratId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          planningId, contratId, titre, description, dateDebut, dateFin
        FROM Planning
        WHERE contratId = ?
        ORDER BY dateDebut ASC
      ''';

      final rows = await _db.query(sql, [contratId]);
      _events = rows.map((row) => PlanningEvent.fromMap(row)).toList();

      logger.i(
        '${_events.length} événements chargés pour le contrat $contratId',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des événements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les événements d'une date spécifique
  Future<void> loadEventsByDate(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      const sql = '''
        SELECT 
          planningId, contratId, titre, description, dateDebut, dateFin
        FROM Planning
        WHERE dateDebut >= ? AND dateDebut < ?
        ORDER BY dateDebut ASC
      ''';

      final rows = await _db.query(sql, [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ]);
      _events = rows.map((row) => PlanningEvent.fromMap(row)).toList();

      logger.i(
        '${_events.length} événements trouvés pour ${date.toIso8601String().split('T')[0]}',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des événements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les événements entre deux dates
  Future<void> loadEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          planningId, contratId, titre, description, dateDebut, dateFin
        FROM Planning
        WHERE dateDebut >= ? AND dateDebut <= ?
        ORDER BY dateDebut ASC
      ''';

      final rows = await _db.query(sql, [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ]);
      _events = rows.map((row) => PlanningEvent.fromMap(row)).toList();

      logger.i('${_events.length} événements trouvés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des événements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge un événement spécifique
  Future<void> loadEvent(int planningId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          planningId, contratId, titre, description, dateDebut, dateFin
        FROM Planning
        WHERE planningId = ?
      ''';

      final row = await _db.queryOne(sql, [planningId]);
      if (row != null) {
        _currentEvent = PlanningEvent.fromMap(row);
        logger.i('Événement $planningId chargé');
      } else {
        _errorMessage = 'Événement non trouvé';
      }
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement de l\'événement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée un nouvel événement
  Future<int> createEvent(
    int contratId,
    String titre,
    String description,
    DateTime dateDebut,
    DateTime dateFin,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        INSERT INTO Planning (contratId, titre, description, dateDebut, dateFin)
        VALUES (?, ?, ?, ?, ?)
      ''';

      final id = await _db.insert(sql, [
        contratId,
        titre,
        description,
        dateDebut.toIso8601String(),
        dateFin.toIso8601String(),
      ]);

      final newEvent = PlanningEvent(
        planningId: id,
        contratId: contratId,
        titre: titre,
        description: description,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );
      _events.add(newEvent);

      logger.i('Événement créé avec l\'ID: $id');
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

  /// Met à jour un événement
  Future<void> updateEvent(PlanningEvent event) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        UPDATE Planning
        SET contratId = ?, titre = ?, description = ?, dateDebut = ?, dateFin = ?
        WHERE planningId = ?
      ''';

      await _db.execute(sql, [
        event.contratId,
        event.titre,
        event.description,
        event.dateDebut.toIso8601String(),
        event.dateFin.toIso8601String(),
        event.planningId,
      ]);

      // Mettre à jour dans la liste
      final index = _events.indexWhere((e) => e.planningId == event.planningId);
      if (index != -1) {
        _events[index] = event;
      }

      if (_currentEvent?.planningId == event.planningId) {
        _currentEvent = event;
      }

      logger.i('Événement ${event.planningId} mis à jour');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la mise à jour: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime un événement
  Future<void> deleteEvent(int planningId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = 'DELETE FROM Planning WHERE planningId = ?';

      await _db.execute(sql, [planningId]);

      _events.removeWhere((e) => e.planningId == planningId);

      if (_currentEvent?.planningId == planningId) {
        _currentEvent = null;
      }

      logger.i('Événement $planningId supprimé');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la suppression: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les événements à venir
  List<PlanningEvent> getUpcomingEvents() {
    final now = DateTime.now();
    return _events.where((e) => e.dateDebut.isAfter(now)).toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
  }

  /// Récupère les événements passés
  List<PlanningEvent> getPastEvents() {
    final now = DateTime.now();
    return _events.where((e) => e.dateFin.isBefore(now)).toList()
      ..sort((a, b) => b.dateDebut.compareTo(a.dateDebut));
  }

  /// Recherche des événements
  Future<void> searchEvents(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          planningId, contratId, titre, description, dateDebut, dateFin
        FROM Planning
        WHERE titre LIKE ? OR description LIKE ?
        ORDER BY dateDebut DESC
      ''';

      final searchTerm = '%$query%';
      final rows = await _db.query(sql, [searchTerm, searchTerm]);
      _events = rows.map((row) => PlanningEvent.fromMap(row)).toList();

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

  /// ✅ NOUVEAU : Logique complète save_planning avec création de details + factures
  /// Conforme à main.py save_planning() (lignes 502-650)
  Future<bool> savePlanningComplete({
    required int traitement_id,
    required DateTime debut,
    required int mois_debut,
    required int? mois_fin,
    required int redondance, // 0='une seule fois', 1='1 mois', 2='2 mois', etc.
    required DateTime dateFinContrat,
    required List<DateTime>
    planningDates, // Dates générées par planning_per_year
    required double montant,
    required String axe_client,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ 1. Créer le planning dans la BD
      const createPlanningSQL = '''
        INSERT INTO Planning 
        (traitement_id, date_debut_planification, mois_debut, mois_fin, duree_traitement, redondance, date_fin_planification)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''';

      final planning = await _db.query(createPlanningSQL, [
        traitement_id,
        debut.toIso8601String().split('T')[0],
        mois_debut,
        mois_fin ?? 0,
        12,
        redondance,
        dateFinContrat.toIso8601String().split('T')[0],
      ]);

      if (planning.isEmpty) {
        throw Exception('Erreur création planning');
      }

      int planningId = planning[0]['planning_id'] ?? 0;
      if (planningId == 0) throw Exception('Planning ID non défini');

      logger.i('✅ Planning créé: ID $planningId');

      // ✅ 2. Créer planning_details pour chaque date
      const createDetailsSQL = '''
        INSERT INTO PlanningDetails 
        (planning_id, date_planification, statut)
        VALUES (?, ?, ?)
      ''';

      int facturesCreated = 0;

      for (final planningDate in planningDates) {
        try {
          // Créer planning_detail
          final details = await _db.query(createDetailsSQL, [
            planningId,
            planningDate.toIso8601String().split('T')[0],
            'À venir',
          ]);

          int detailId = details[0]['planning_detail_id'] ?? 0;
          if (detailId == 0) {
            logger.w(
              '⚠️ Impossible de créer planning_detail pour $planningDate',
            );
            continue;
          }

          // ✅ 3. Créer facture pour chaque détail
          const createFactureSQL = '''
            INSERT INTO Facture 
            (planning_detail_id, montant, date_traitement, etat, axe)
            VALUES (?, ?, ?, ?, ?)
          ''';

          await _db.execute(createFactureSQL, [
            detailId,
            montant.toInt(), // Convertir double en int
            planningDate.toIso8601String().split('T')[0],
            'Non payé',
            axe_client,
          ]);

          facturesCreated++;
          logger.i('✅ Facture $facturesCreated créée pour $planningDate');
        } catch (e) {
          logger.e('❌ Erreur création facture pour $planningDate: $e');
          continue; // Continuer avec la prochaine date
        }
      }

      logger.i('✅ Planning complet créé: $facturesCreated factures');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur savePlanningComplete: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ NOUVEAU : Extraire redondance depuis fréquence (conforme à main.py)
  /// "une seule fois" → 0
  /// "1 mois" → 1
  /// "2 mois" → 2
  /// "3 mois" → 3, etc.
  /// Créer un planning pour un traitement avec génération automatique des détails
  ///
  /// Paramètres:
  /// - traitementId: ID du traitement
  /// - dateDebutPlanification: Date de début de la planification
  /// - moisDebut: Mois de début (1-12)
  /// - dureeTraitement: Durée totale du traitement en mois
  /// - redondance: Fréquence d'exécution en mois
  ///
  /// Retourne l'ID du planning créé, ou -1 en cas d'erreur
  Future<int> createPlanning({
    required int traitementId,
    required DateTime dateDebutPlanification,
    required int moisDebut,
    required int dureeTraitement,
    required int redondance,
  }) async {
    try {
      // Calculer les dates de fin en fonction de la durée
      final dateFinPlanification = DateTime(
        dateDebutPlanification.year + (dureeTraitement ~/ 12),
        dateDebutPlanification.month + (dureeTraitement % 12),
        dateDebutPlanification.day,
      );

      const sql = '''
        INSERT INTO Planning 
        (traitement_id, date_debut_planification, mois_debut, mois_fin, duree_traitement, redondance, date_fin_planification)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''';

      final planningId = await _db.insert(sql, [
        traitementId,
        dateDebutPlanification.toIso8601String().split('T')[0],
        moisDebut,
        moisDebut + dureeTraitement - 1, // mois_fin
        dureeTraitement,
        redondance,
        dateFinPlanification.toIso8601String().split('T')[0],
      ]);

      logger.i('✅ Planning créé: ID $planningId pour traitement $traitementId');
      return planningId;
    } catch (e) {
      logger.e('❌ Erreur création planning: $e');
      return -1;
    }
  }

  static int extractRedondanceFromFrequency(String frequence) {
    if (frequence.toLowerCase() == 'une seule fois') {
      return 0;
    }
    try {
      final parts = frequence.split(' ');
      if (parts.isNotEmpty) {
        return int.parse(parts[0]);
      }
    } catch (e) {
      print('❌ Erreur parsing frequency: $e');
    }
    return 1; // Défaut: 1 mois
  }

  /// ✅ NOUVEAU : Valider montant (remove spaces: "1 234" → 1234)
  static int cleanMontant(String montantStr) {
    return int.parse(montantStr.replaceAll(' ', '').replaceAll('Ar', ''));
  }
}
