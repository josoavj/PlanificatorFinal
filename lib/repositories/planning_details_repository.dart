import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:planificator/models/planning_details.dart';
import 'package:planificator/services/database_service.dart';

class PlanningDetailsRepository extends ChangeNotifier {
  final _db = DatabaseService();
  final logger = Logger();

  List<PlanningDetails> _details = [];
  List<PlanningDetails> _currentMonthTreatments = [];
  List<PlanningDetails> _upcomingTreatments = [];
  List<Map<String, dynamic>> _currentMonthTreatmentsComplete = [];
  List<Map<String, dynamic>> _upcomingTreatmentsComplete = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PlanningDetails> get details => _details;
  List<PlanningDetails> get currentMonthTreatments => _currentMonthTreatments;
  List<PlanningDetails> get upcomingTreatments => _upcomingTreatments;
  List<Map<String, dynamic>> get currentMonthTreatmentsComplete =>
      _currentMonthTreatmentsComplete;
  List<Map<String, dynamic>> get upcomingTreatmentsComplete =>
      _upcomingTreatmentsComplete;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Créer un détail de planning
  Future<PlanningDetails?> createPlanningDetails(
    int planningId,
    DateTime datePlanification, {
    String statut = 'À venir',
  }) async {
    try {
      final result = await _db.query(
        'INSERT INTO PlanningDetails (planning_id, date_planification, statut) VALUES (?, ?, ?)',
        [planningId, datePlanification.toIso8601String().split('T')[0], statut],
      );

      if (result.isNotEmpty) {
        int insertId = result[0]['planning_detail_id'] as int? ?? 0;
        if (insertId == 0) return null;

        return PlanningDetails(
          planningDetailId: insertId,
          planningId: planningId,
          datePlanification: datePlanification,
          statut: statut,
        );
      }
      return null;
    } catch (e) {
      print('❌ Erreur créer planning_details: $e');
      rethrow;
    }
  }

  /// Récupérer détails d'un planning
  Future<List<PlanningDetails>> getPlanningDetails(int planningId) async {
    try {
      final results = await _db.query(
        'SELECT * FROM PlanningDetails WHERE planning_id = ? ORDER BY date_planification',
        [planningId],
      );

      return results.map((row) => PlanningDetails.fromJson(row)).toList();
    } catch (e) {
      print('❌ Erreur récupérer planning_details: $e');
      return [];
    }
  }

  /// Mettre à jour l'état d'un détail
  Future<bool> updatePlanningDetailsStatut(
    int planningDetailId,
    String newStatut,
  ) async {
    try {
      final result = await _db.query(
        'UPDATE PlanningDetails SET statut = ? WHERE planning_detail_id = ?',
        [newStatut, planningDetailId],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('❌ Erreur mettre à jour planning_details: $e');
      return false;
    }
  }

  /// Supprimer un détail
  Future<bool> deletePlanningDetails(int planningDetailsId) async {
    try {
      final result = await _db.query(
        'DELETE FROM PlanningDetails WHERE planning_detail_id = ?',
        [planningDetailsId],
      );

      return result.isNotEmpty;
    } catch (e) {
      print('❌ Erreur supprimer planning_details: $e');
      return false;
    }
  }

  /// ✅ Charger tous les détails de planning
  Future<void> loadAllDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _db.query(
        'SELECT * FROM PlanningDetails ORDER BY date_planification DESC',
      );

      _details = results.map((row) => PlanningDetails.fromJson(row)).toList();
      logger.i('✅ ${_details.length} détails de planning chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur charger tous les détails: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Charger les traitements du mois courant (table_en_cours) - Version complète avec JOINs
  /// Retourne: List<Map> avec clés: date, traitement, etat, axe
  Future<List<Map<String, dynamic>>>
  loadCurrentMonthTreatmentsComplete() async {
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

      // ✅ Requête COMPLÈTE: récupère typeTraitement + categorieTraitement + nom + prenom + axe
      final results = await _db.query(
        '''SELECT 
             pd.planning_detail_id,
             DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
             CONCAT(tt.typeTraitement, ' pour ', c.prenom, ' ', c.nom) as traitement,
             pd.statut as etat,
             c.axe,
             tt.categorieTraitement
           FROM PlanningDetails pd
           INNER JOIN Planning p ON pd.planning_id = p.planning_id
           INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
           INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
           INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
           INNER JOIN Client c ON ct.client_id = c.client_id
           WHERE YEAR(pd.date_planification) = ?
           AND MONTH(pd.date_planification) = ?
           ORDER BY pd.date_planification ASC''',
        [currentYear, currentMonth],
      );

      logger.i('✅ Reçu ${results.length} traitements du mois courant');
      if (results.isNotEmpty) {
        logger.d('Colonnes: ${results.first.keys.toList()}');
        logger.d('Premier résultat: ${results.first}');
      }

      final completeData = results.cast<Map<String, dynamic>>();

      // ✅ IMPORTANT: Convertir en PlanningDetails ET garder les données enrichies
      _currentMonthTreatments = results
          .map((row) => PlanningDetails.fromJson(row))
          .toList();

      // ✅ Stocker aussi les données enrichies pour affichage
      _currentMonthTreatmentsComplete = completeData;

      logger.i(
        '✅ ${_currentMonthTreatments.length} traitements du mois courant chargés',
      );
      return completeData;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur charger traitements du mois: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Charger les traitements à venir (table_prevision) - Version complète avec JOINs
  /// Retourne: List<Map> avec clés: date, traitement, etat, axe
  Future<List<Map<String, dynamic>>> loadUpcomingTreatmentsComplete() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      logger.i('🔍 Chargement COMPLET traitements à venir (après $todayStr)');

      // ✅ Requête COMPLÈTE: récupère typeTraitement + categorieTraitement + nom + prenom + axe
      final results = await _db.query(
        '''SELECT 
             pd.planning_detail_id,
             DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
             CONCAT(tt.typeTraitement, ' pour ', c.prenom, ' ', c.nom) as traitement,
             pd.statut as etat,
             c.axe,
             tt.categorieTraitement
           FROM PlanningDetails pd
           INNER JOIN Planning p ON pd.planning_id = p.planning_id
           INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
           INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
           INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
           INNER JOIN Client c ON ct.client_id = c.client_id
           WHERE pd.date_planification > ?
           ORDER BY pd.date_planification ASC''',
        [todayStr],
      );

      logger.i('✅ Reçu ${results.length} traitements à venir');
      if (results.isNotEmpty) {
        logger.d('Colonnes: ${results.first.keys.toList()}');
        logger.d('Premier résultat: ${results.first}');
      }

      final completeData = results.cast<Map<String, dynamic>>();

      // ✅ IMPORTANT: Convertir en PlanningDetails ET garder les données enrichies
      _upcomingTreatments = results
          .map((row) => PlanningDetails.fromJson(row))
          .toList();

      // ✅ Stocker aussi les données enrichies pour affichage
      _upcomingTreatmentsComplete = completeData;

      logger.i('✅ ${_upcomingTreatments.length} traitements à venir chargés');
      return completeData;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur charger traitements à venir: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
