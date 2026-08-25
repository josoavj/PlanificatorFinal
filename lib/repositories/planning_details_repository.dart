import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:planificator/models/planning_details.dart';
import 'package:planificator/services/index.dart';
import 'package:planificator/core/sql_queries.dart';

class PlanningDetailsRepository extends ChangeNotifier {
  final DatabaseService _db;
  final logger = createLoggerWithFileOutput(
    name: 'planning_details_repository',
  );

  PlanningDetailsRepository({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService();

  List<PlanningDetails> _details = [];
  List<PlanningDetails> _currentMonthTreatments = [];
  List<PlanningDetails> _upcomingTreatments = [];
  List<Map<String, dynamic>> _currentMonthTreatmentsComplete = [];
  List<Map<String, dynamic>> _upcomingTreatmentsComplete = [];
  List<Map<String, dynamic>> _allTreatmentsComplete = [];
  Map<String, int> _historyCategoryCounts = {};
  bool _isLoading = false;
  bool _hasMoreHistory = true;
  String? _errorMessage;

  List<PlanningDetails> get details => _details;
  List<PlanningDetails> get currentMonthTreatments => _currentMonthTreatments;
  List<PlanningDetails> get upcomingTreatments => _upcomingTreatments;
  List<Map<String, dynamic>> get currentMonthTreatmentsComplete =>
      _currentMonthTreatmentsComplete;
  List<Map<String, dynamic>> get upcomingTreatmentsComplete =>
      _upcomingTreatmentsComplete;
  List<Map<String, dynamic>> get allTreatmentsComplete =>
      _allTreatmentsComplete;
  Map<String, int> get historyCategoryCounts => _historyCategoryCounts;
  bool get isLoading => _isLoading;
  bool get hasMoreHistory => _hasMoreHistory;
  String? get errorMessage => _errorMessage;

  ///  NOUVEAU: Charger seulement les compteurs par catégorie (Performance ++ )
  Future<void> loadHistoryCategoryCounts() async {
    try {
      final results = await _db.query(SqlQueries.countTreatmentsByCategory);
      final Map<String, int> counts = {'AT': 0, 'PC': 0, 'NI': 0, 'RO': 0};
      
      for (final row in results) {
        final cat = row['categorieTraitement']?.toString() ?? '';
        final count = int.tryParse(row['count']?.toString() ?? '0') ?? 0;
        final code = _normalizeCategoryCode(cat);
        if (counts.containsKey(code)) {
          counts[code] = counts[code]! + count;
        }
      }
      _historyCategoryCounts = counts;
      notifyListeners();
    } catch (e) {
      logger.e('Erreur compteurs historique: $e');
    }
  }

  String _normalizeCategoryCode(String raw) {
    final upper = raw.toUpperCase().trim();
    if (upper.startsWith('AT') || upper.contains('ANTI TERMITES')) return 'AT';
    if (upper.startsWith('NI') || upper.contains('NETTOYAGE')) return 'NI';
    if (upper.startsWith('RO') || upper.contains('RAMASSAGE')) return 'RO';
    return 'PC';
  }

  /// Créer un détail de planning
  /// Vérifie et évite les doublons (ne crée pas si la date existe déjà)
  Future<PlanningDetails?> createPlanningDetails(
    int planningId,
    DateTime datePlanification, {
    String statut = 'À venir',
  }) async {
    try {
      // Vérifier si la date existe déjà pour ce planning
      final dateStr = datePlanification.toIso8601String().split('T')[0];
      final existingCheck = await _db
          .query(
            SqlQueries.checkExistingPlanningDetail,
            [planningId, dateStr],
          )
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () {
              logger.e(
                'Timeout checking existing planning_details for planning_id $planningId',
              );
              throw TimeoutException('Database query timeout');
            },
          );

      if (existingCheck.isNotEmpty) {
        logger.i(
          ' PlanningDetail existe déjà: planning_id=$planningId, date=$dateStr',
        );
        return PlanningDetails(
          planningDetailId: existingCheck[0]['planning_detail_id'] as int,
          planningId: planningId,
          datePlanification: datePlanification,
          statut: statut,
        );
      }

      // Utiliser insert() au lieu de query() pour les INSERT
      final insertId = await _db.insert(
        SqlQueries.insertPlanningDetailWithStatut,
        [planningId, dateStr, statut],
      );

      if (insertId > 0) {
        logger.i(
          ' PlanningDetail créé: ID $insertId pour planning $planningId',
        );

        return PlanningDetails(
          planningDetailId: insertId,
          planningId: planningId,
          datePlanification: datePlanification,
          statut: statut,
        );
      }
      logger.e(' PlanningDetail insertion retourned ID: $insertId');
      return null;
    } catch (e) {
      logger.e(' Erreur créer planning_details: $e');
      rethrow;
    }
  }

  /// Récupérer détails d'un planning
  Future<List<PlanningDetails>> getPlanningDetails(int planningId) async {
    try {
      final results = await _db
          .query(
            SqlQueries.getPlanningDetailsByPlanningId,
            [planningId],
          )
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () {
              logger.e(
                'Timeout loading planning_details for planning_id $planningId',
              );
              throw TimeoutException('Database query timeout');
            },
          );

      return results.map((row) => PlanningDetails.fromJson(row)).toList();
    } catch (e) {
      logger.e(' Erreur récupérer planning_details: $e');
      return [];
    }
  }

  /// Mettre à jour l'état d'un détail
  Future<bool> updatePlanningDetailsStatut(
    int planningDetailId,
    String newStatut,
  ) async {
    try {
      await _db.execute(
        SqlQueries.updatePlanningDetailStatut,
        [newStatut, planningDetailId],
      );

      logger.i(' Planning detail $planningDetailId statut => $newStatut');

      // IMPORTANT: Recharger globalement sans cache pour la réactivité
      await refreshAll();

      return true;
    } catch (e) {
      logger.e(' Erreur mettre à jour planning_details: $e');
      return false;
    }
  }

  /// Supprimer un détail
  Future<bool> deletePlanningDetails(int planningDetailsId) async {
    try {
      final result = await _db.query(
        SqlQueries.deletePlanningDetail,
        [planningDetailsId],
      );

      return result.isNotEmpty;
    } catch (e) {
      logger.e(' Erreur supprimer planning_details: $e');
      return false;
    }
  }

  /// Récupère un détail complet par son ID (pour rafraîchissement)
  Future<Map<String, dynamic>?> getPlanningDetailComplete(int id) async {
    try {
      // SÉCURITÉ : Ne pas utiliser le cache pour les détails individuels lors d'un rafraîchissement
      final result = await _db.queryOne(SqlQueries.getPlanningDetailCompleteById, params: [id], useCache: false);
      return result;
    } catch (e) {
      logger.e(' Erreur getPlanningDetailComplete: $e');
      return null;
    }
  }

  /// Charger tous les détails de planning
  Future<void> loadAllDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _db
          .query(
            SqlQueries.getAllPlanningDetails,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              logger.e('Timeout loading all planning_details');
              throw TimeoutException('Database query timeout');
            },
          );

      _details = results.map((row) => PlanningDetails.fromJson(row)).toList();
      logger.i(' ${_details.length} détails de planning chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur charger tous les détails: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les traitements du mois courant (table_en_cours) - Version complète avec JOINs
  /// Retourne: List<Map> avec clés: date, traitement, etat, axe
  Future<List<Map<String, dynamic>>> loadCurrentMonthTreatmentsComplete({bool useCache = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      logger.i(
        '🔍 Chargement COMPLET traitements du mois $currentMonth/$currentYear',
      );

      // Requête optimisée: utilise COALESCE, exclut "Classé sans suite" et ajoute LIMIT
      final results = await _db
          .query(
            SqlQueries.getCurrentMonthTreatmentsComplete,
            [currentYear, currentMonth],
            useCache,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              logger.e('Timeout loading current month treatments');
              throw TimeoutException('Database query timeout');
            },
          );

      logger.i(' Reçu ${results.length} traitements du mois courant');
      if (results.isNotEmpty) {
        logger.d('Colonnes: ${results.first.keys.toList()}');
        logger.d('Premier résultat: ${results.first}');
      }

      final completeData = results.cast<Map<String, dynamic>>();

      // IMPORTANT: Convertir en PlanningDetails ET garder les données enrichies
      _currentMonthTreatments = results
          .map((row) => PlanningDetails.fromJson(row))
          .toList();

      // Stocker aussi les données enrichies pour affichage
      _currentMonthTreatmentsComplete = _sortTreatmentsIntelligently(completeData);

      logger.i(
        ' ${_currentMonthTreatments.length} traitements du mois courant chargés',
      );
      return _currentMonthTreatmentsComplete;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur charger traitements du mois: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les traitements à venir (table_prevision) - Version complète avec JOINs
  /// [startDate] : Date à partir de laquelle charger les traitements (par défaut aujourd'hui)
  Future<List<Map<String, dynamic>>> loadUpcomingTreatmentsComplete({DateTime? startDate, bool useCache = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final effectiveDate = startDate ?? DateTime.now();
      final dateStr = effectiveDate.toIso8601String().split('T')[0];

      logger.i(
        '🔍 Chargement COMPLET traitements à venir (à partir de $dateStr)',
      );

      // Requête optimisée: utilise COALESCE, exclut "Classé sans suite" et ajoute LIMIT
      final results = await _db
          .query(
            SqlQueries.getUpcomingTreatmentsComplete,
            [dateStr],
            useCache,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              logger.e('Timeout loading upcoming treatments');
              throw TimeoutException('Database query timeout');
            },
          );

      logger.i(' Reçu ${results.length} traitements à venir');
      if (results.isNotEmpty) {
        logger.d('Colonnes: ${results.first.keys.toList()}');
        logger.d('Premier résultat: ${results.first}');
      }

      final completeData = results.cast<Map<String, dynamic>>();

      //  IMPORTANT: Convertir en PlanningDetails ET garder les données enrichies
      _upcomingTreatments = results
          .map((row) => PlanningDetails.fromJson(row))
          .toList();

      //  Stocker aussi les données enrichies pour affichage
      _upcomingTreatmentsComplete = _sortTreatmentsIntelligently(completeData);

      logger.i(' ${_upcomingTreatments.length} traitements à venir chargés');
      return _upcomingTreatmentsComplete;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur charger traitements à venir: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ///  NOUVEAU: Charger TOUS les traitements (effectués + à venir) pour Historique
  /// Supporte désormais la PAGINATION pour les flux élevés
  Future<List<Map<String, dynamic>>> loadHistoryPage({
    int page = 0,
    int pageSize = 100,
    bool useCache = true,
  }) async {
    _isLoading = page == 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = page * pageSize;
      final results = await _db
          .query(SqlQueries.getAllTreatmentsPaginated, [pageSize, offset], useCache)
          .timeout(const Duration(seconds: 45));

      final sorted = _sortTreatmentsIntelligently(results.cast<Map<String, dynamic>>());

      if (page == 0) {
        _allTreatmentsComplete = sorted;
      } else {
        _allTreatmentsComplete.addAll(sorted);
      }

      _hasMoreHistory = results.length == pageSize;

      logger.i('Page $page: ${results.length} interventions chargées (Total: ${_allTreatmentsComplete.length}, Plus: $_hasMoreHistory)');
      return sorted;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur pagination historique: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ///  NOUVEAU: Charger TOUS les traitements (effectués + à venir) pour Historique
  /// Obsolète pour les gros flux, privilégier loadHistoryPage
  Future<List<Map<String, dynamic>>> loadAllTreatmentsComplete({bool useCache = true}) async {
    return await loadHistoryPage(pageSize: 5000, useCache: useCache);
  }

  /// Récupère les traitements d'un mois/année spécifique, optionnellement filtrés par client
  Future<List<Map<String, dynamic>>> getTreatmentsByMonthAndClient({
    required int year,
    required int month,
    int? clientId, // Si null, récupère tous les clients
    String? treatmentType, // Si null ou 'Tous', récupère tous les traitements
  }) async {
    try {
      String whereClause =
          'WHERE YEAR(pd.date_planification) = ? AND MONTH(pd.date_planification) = ?';
      List<dynamic> params = [year, month];

      if (clientId != null && clientId != -1) {
        whereClause += ' AND c.client_id = ?';
        params.add(clientId);
      }

      if (treatmentType != null && treatmentType != 'Tous') {
        whereClause += ' AND tt.typeTraitement = ?';
        params.add(treatmentType);
      }

      final results = await _db
          .query(
            '${SqlQueries.getTreatmentsByMonthAndClientBase} $whereClause ORDER BY pd.date_planification ASC',
            params,
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              logger.e('Timeout loading treatments by month and client');
              throw TimeoutException('Database query timeout');
            },
          );

      logger.i(' ${results.length} traitements récupérés pour $month/$year');
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.e(' Erreur récupération traitements par mois: $e');
      return [];
    }
  }

  /// Récupère les types de traitements uniques pour un client (ou tous si clientId == -1)
  Future<List<String>> getTreatmentTypesForClient(int clientId) async {
    try {
      final results = await _db
          .query(
            clientId == -1
                ? SqlQueries.getDistinctTreatmentTypes
                : SqlQueries.getDistinctTreatmentTypesByClient,
            clientId == -1 ? [] : [clientId],
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e('Timeout loading treatment types for client $clientId');
              throw TimeoutException('Database query timeout');
            },
          );

      final treatments = results
          .map((r) => (r['typeTraitement'] as String?) ?? 'N/A')
          .toList();

      logger.i(
        ' ${treatments.length} types de traitements trouvés pour client $clientId',
      );
      return treatments;
    } catch (e) {
      logger.e(' Erreur récupération types de traitements: $e');
      return [];
    }
  }

  ///  Rechargement global de toutes les listes pour assurer la synchronisation
  /// (Mois actuel, À venir, Historique complet)
  Future<void> refreshAll() async {
    logger.i('Refresh global du planning lancé...');
    // Lancer les 3 chargements en parallèle pour l'efficience (SANS CACHE pour le refresh)
    await Future.wait([
      loadCurrentMonthTreatmentsComplete(useCache: false),
      loadUpcomingTreatmentsComplete(useCache: false),
      loadAllTreatmentsComplete(useCache: false),
    ]);
    logger.i('Refresh global terminé');
    notifyListeners();
  }

  /// Applique un tri intelligent :
  /// 1. Interventions FAITES (Effectué) en premier, triées par date DESC (plus récent d'abord).
  /// 2. Interventions À VENIR en second, triées par date ASC (plus proche d'abord).
  List<Map<String, dynamic>> _sortTreatmentsIntelligently(List<Map<String, dynamic>> data) {
    final list = List<Map<String, dynamic>>.from(data);
    
    list.sort((a, b) {
      final statusA = (a['etat'] as String? ?? '').toLowerCase();
      final statusB = (b['etat'] as String? ?? '').toLowerCase();
      
      final isDoneA = statusA.contains('effectué');
      final isDoneB = statusB.contains('effectué');

      // 1. Les faits en premier
      if (isDoneA != isDoneB) return isDoneA ? -1 : 1;

      // Extraire les dates pour le tri chronologique
      DateTime? dateA = _parseDate(a['date_planification'] ?? a['date']);
      DateTime? dateB = _parseDate(b['date_planification'] ?? b['date']);
      
      if (dateA == null || dateB == null) return 0;

      // 2. Si les deux sont faits : le plus récent en premier (DESC)
      if (isDoneA) return dateB.compareTo(dateA);

      // 3. Si les deux sont à venir : le plus proche en premier (ASC)
      return dateA.compareTo(dateB);
    });

    return list;
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }
}
