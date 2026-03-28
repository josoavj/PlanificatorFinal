import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:planificator/models/planning_details.dart';
import 'package:planificator/services/index.dart';

class PlanningDetailsRepository extends ChangeNotifier {
  final _db = DatabaseService();
  final logger = createLoggerWithFileOutput(
    name: 'planning_details_repository',
  );

  List<PlanningDetails> _details = [];
  List<PlanningDetails> _currentMonthTreatments = [];
  List<PlanningDetails> _upcomingTreatments = [];
  List<Map<String, dynamic>> _currentMonthTreatmentsComplete = [];
  List<Map<String, dynamic>> _upcomingTreatmentsComplete = [];
  List<Map<String, dynamic>> _allTreatmentsComplete = [];
  bool _isLoading = false;
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
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
            'SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ? AND date_planification = ?',
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
        'INSERT INTO PlanningDetails (planning_id, date_planification, statut) VALUES (?, ?, ?)',
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
            'SELECT * FROM PlanningDetails WHERE planning_id = ? ORDER BY date_planification',
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
        'UPDATE PlanningDetails SET statut = ? WHERE planning_detail_id = ?',
        [newStatut, planningDetailId],
      );

      logger.i(' Planning detail $planningDetailId statut => $newStatut');

      // IMPORTANT: Recharger les données après la mise à jour
      await loadUpcomingTreatmentsComplete();

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
        'DELETE FROM PlanningDetails WHERE planning_detail_id = ?',
        [planningDetailsId],
      );

      return result.isNotEmpty;
    } catch (e) {
      logger.e(' Erreur supprimer planning_details: $e');
      return false;
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
            'SELECT * FROM PlanningDetails ORDER BY date_planification DESC',
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

      // Requête optimisée: utilise COALESCE, exclut "Classé sans suite" et ajoute LIMIT
      final results = await _db
          .query(
            '''SELECT 
             pd.planning_detail_id,
             DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
             CONCAT(COALESCE(tt.typeTraitement, 'Sans type'), ' pour ', COALESCE(c.prenom, ''), ' ', COALESCE(c.nom, '')) as traitement,
             COALESCE(pd.statut, 'Non planifié') as etat,
             COALESCE(c.axe, 'Non défini') as axe,
             COALESCE(tt.categorieTraitement, '') as categorieTraitement,
             COALESCE(c.categorie, '') as categorie
           FROM PlanningDetails pd
           INNER JOIN Planning p ON pd.planning_id = p.planning_id
           INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
           LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
           INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
           INNER JOIN Client c ON ct.client_id = c.client_id
           WHERE YEAR(pd.date_planification) = ?
           AND MONTH(pd.date_planification) = ?
           AND COALESCE(pd.statut, 'Non planifié') != 'Classé sans suite'
           ORDER BY pd.date_planification ASC
           LIMIT 5000''',
            [currentYear, currentMonth],
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
      _currentMonthTreatmentsComplete = completeData;

      logger.i(
        ' ${_currentMonthTreatments.length} traitements du mois courant chargés',
      );
      return completeData;
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
  /// Retourne: List<Map> avec clés: date, traitement, etat, axe
  Future<List<Map<String, dynamic>>> loadUpcomingTreatmentsComplete() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];

      logger.i(
        '🔍 Chargement COMPLET traitements à venir (à partir de $todayStr)',
      );

      // Requête optimisée: utilise COALESCE, exclut "Classé sans suite" et ajoute LIMIT
      final results = await _db
          .query(
            '''SELECT 
             pd.planning_detail_id,
             pd.planning_id,
             DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
             pd.date_planification,
             CONCAT(COALESCE(tt.typeTraitement, 'Sans type'), ' pour ', COALESCE(c.prenom, ''), ' ', COALESCE(c.nom, '')) as traitement,
             COALESCE(pd.statut, 'Non planifié') as etat,
             COALESCE(c.axe, 'Non défini') as axe,
             COALESCE(tt.categorieTraitement, '') as categorieTraitement,
             COALESCE(c.categorie, '') as categorie
           FROM PlanningDetails pd
           INNER JOIN Planning p ON pd.planning_id = p.planning_id
           INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
           LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
           INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
           INNER JOIN Client c ON ct.client_id = c.client_id
           WHERE pd.date_planification >= ?
           AND COALESCE(pd.statut, 'Non planifié') != 'Classé sans suite'
           ORDER BY pd.date_planification ASC
           LIMIT 10000''',
            [todayStr],
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
      _upcomingTreatmentsComplete = completeData;

      logger.i(' ${_upcomingTreatments.length} traitements à venir chargés');
      return completeData;
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
  /// IMPORTANT: Charge TOUS les records SANS filtrer par date
  Future<List<Map<String, dynamic>>> loadAllTreatmentsComplete() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      logger.i('🔍 Chargement COMPLET tous les traitements (passés + futurs)');

      // Requête SANS filtre de date - récupère TOUS les traitements
      final results = await _db
          .query('''SELECT 
             pd.planning_detail_id,
             pd.planning_id,
             DATE_FORMAT(pd.date_planification, '%Y-%m-%d') as date,
             pd.date_planification,
             CONCAT(tt.typeTraitement, ' pour ', c.prenom, ' ', c.nom) as traitement,
             pd.statut as etat,
             c.axe,
             tt.categorieTraitement,
             tt.id_type_traitement,
             c.client_id,
             ct.contrat_id,
             c.categorie
           FROM PlanningDetails pd
           INNER JOIN Planning p ON pd.planning_id = p.planning_id
           INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
           LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
           INNER JOIN Contrat ct ON t.contrat_id = ct.contrat_id
           INNER JOIN Client c ON ct.client_id = c.client_id
           ORDER BY pd.date_planification DESC''')
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              logger.e('Timeout loading all treatments complete');
              throw TimeoutException('Database query timeout');
            },
          );

      logger.i(' Reçu ${results.length} traitements (tous les statuts)');
      if (results.isNotEmpty) {
        logger.d('Colonnes: ${results.first.keys.toList()}');
        logger.d(
          'Nombre d\'effectués: ${results.where((r) => (r['etat'] as String?)?.contains('Effectué') ?? false).length}',
        );
        logger.d(
          'Nombre d\'à venir: ${results.where((r) => (r['etat'] as String?)?.contains('À venir') ?? false).length}',
        );
      }

      // Assurer le tri DESC par date_planification (le plus récent en premier)
      final completeData = results.cast<Map<String, dynamic>>();
      completeData.sort((a, b) {
        try {
          final dateA = a['date_planification'];
          final dateB = b['date_planification'];

          DateTime? dateTimeA;
          DateTime? dateTimeB;

          if (dateA is DateTime) {
            dateTimeA = dateA;
          } else if (dateA is String) {
            dateTimeA = DateTime.tryParse(dateA);
          }
          if (dateB is DateTime) {
            dateTimeB = dateB;
          } else if (dateB is String) {
            dateTimeB = DateTime.tryParse(dateB);
          }

          if (dateTimeA == null || dateTimeB == null) return 0;
          return dateTimeB.compareTo(dateTimeA); // DESC: plus récent en premier
        } catch (e) {
          return 0;
        }
      });

      _allTreatmentsComplete = completeData;

      logger.i(
        ' ${_allTreatmentsComplete.length} traitements totaux chargés (tous les statuts)',
      );
      return completeData;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur charger tous les traitements: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
          .query('''
        SELECT 
          pd.date_planification AS `Date du traitement`,
          tt.typeTraitement AS `Traitement concerné`,
          tt.categorieTraitement AS `Catégorie du traitement`,
          CONCAT(c.nom, ' ', c.prenom) AS `Client concerné`,
          c.categorie AS `Catégorie du client`,
          c.axe AS `Axe du client`,
          pd.statut AS `Etat traitement`
        FROM PlanningDetails pd
        INNER JOIN Planning p ON pd.planning_id = p.planning_id
        INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
        INNER JOIN Client c ON co.client_id = c.client_id
        $whereClause
        ORDER BY pd.date_planification ASC
      ''', params)
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
                ? '''
        SELECT DISTINCT tt.typeTraitement
        FROM Traitement t
        INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        ORDER BY tt.typeTraitement ASC
      '''
                : '''
        SELECT DISTINCT tt.typeTraitement
        FROM Traitement t
        INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
        WHERE co.client_id = ?
        ORDER BY tt.typeTraitement ASC
      ''',
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
}
