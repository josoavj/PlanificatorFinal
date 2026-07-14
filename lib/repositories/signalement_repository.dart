import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/date_helper.dart';
import '../core/sql_queries.dart';

class SignalementRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'signalement_repository');

  List<Signalement> _signalements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Signalement> get signalements => _signalements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge tous les signalements
  Future<void> loadAllSignalements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.query(SqlQueries.getAllSignalements);
      _signalements = rows.map((row) => Signalement.fromJson(row)).toList();

      logger.i('${_signalements.length} signalements chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des signalements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée un signalement (avancement ou décalage)
  /// Conforme à Kivy signaler()
  Future<bool> createSignalement({
    required int planningDetailsId,
    required String motif,
    required String type, // 'avancement' ou 'décalage'
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.execute(SqlQueries.createSignalement, [planningDetailsId, motif, type]);
      logger.i(' Signalement créé: type=$type, motif=$motif');

      // Recharger les signalements
      await loadAllSignalements();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la création du signalement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ///  LOGIQUE CLÉE: Modifier la date de planning
  /// Conforme à Kivy: garder.active = modifier JUSTE cette date
  Future<bool> modifierDatePlanning({
    required int planningDetailsId,
    required DateTime newDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.execute(SqlQueries.updatePlanningDate, [
        DateHelper.toDbFormat(newDate),
        planningDetailsId,
      ]);

      logger.i(' Date modifiée pour planning_details_id=$planningDetailsId');
      await loadAllSignalements();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la modification de date: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> modifierRedondance({
    required int planningId,
    required int planningDetailsId,
    required DateTime ancienneDateModifiee,
    required DateTime nouvelleDateModifiee,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      //  1. Calculer l'écart de décalage EN MOIS (conforme Kivy relativedelta)
      final ecartMois = _calculateMonthsDifference(
        ancienneDateModifiee,
        nouvelleDateModifiee,
      );
      logger.i(' Décalage des dates futures de $ecartMois mois');

      //  2. Récupérer tous les details de ce planning
      final allDetails = await _db.query(SqlQueries.getPlanningDetailsByPlanningId, [planningId]);
      logger.i(' Trouvé ${allDetails.length} planning details');

      //  3. Trouver l'index du planning detail actuellement modifié
      int currentIndex = 0;
      for (int i = 0; i < allDetails.length; i++) {
        if (allDetails[i]['planning_detail_id'] == planningDetailsId) {
          currentIndex = i;
          break;
        }
      }

      //  4. Décaler TOUTES les dates à partir de currentIndex+1 du même écart EN MOIS
      for (int i = currentIndex + 1; i < allDetails.length; i++) {
        final oldDate = DateHelper.toDateTime(
          allDetails[i]['date_planification'],
        );
        //  CORRECTION: Ajouter l'écart en MOIS (pas en jours)
        final newDate = _addMonthsToDate(oldDate, ecartMois);

        await _db.execute(SqlQueries.updatePlanningDate, [
          DateHelper.toDbFormat(newDate),
          allDetails[i]['planning_detail_id'],
        ]);

        logger.i(
          '  Detail ${allDetails[i]['planning_detail_id']}: ${DateHelper.format(oldDate)} → ${DateHelper.format(newDate)} (écart: $ecartMois mois)',
        );
      }

      logger.i(' Dates décalées avec succès (redondance inchangée)');
      await loadAllSignalements();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du décalage des dates: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre complet du signalement (création + modification date/redondance)
  /// Conforme à Kivy signaler() complet (lignes 1000-1050)
  Future<bool> enregistrerSignalment({
    required int planningDetailsId,
    required int planningId,
    required String motif,
    required String type, // 'avancement' ou 'décalage'
    required DateTime dateCourante,
    required DateTime dateSignalement,
    required bool
    changerRedondance, // true=décaler TOUTES les futures, false=modifier JUSTE celle-ci
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      //  1. Créer le signalement
      await createSignalement(
        planningDetailsId: planningDetailsId,
        motif: motif,
        type: type,
      );

      //  2. Modifier la date (toujours applicable)
      await modifierDatePlanning(
        planningDetailsId: planningDetailsId,
        newDate: dateSignalement,
      );

      //  3. Si "changer la redondance" = décaler TOUTES les dates futures du même écart
      if (changerRedondance) {
        logger.i(
          ' MODE DÉCALER: appliquer l\'écart à TOUTES les dates futures',
        );

        await modifierRedondance(
          planningId: planningId,
          planningDetailsId: planningDetailsId,
          ancienneDateModifiee: dateCourante,
          nouvelleDateModifiee: dateSignalement,
        );
      }

      logger.i(' Enregistrement signalement réussi');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur enregistrement signalement: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime un signalement
  Future<bool> deleteSignalement(int signalementId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = 'DELETE FROM Signalement WHERE signalement_id = ?';
      await _db.execute(sql, [signalementId]);

      logger.i('Signalement $signalementId supprimé');
      await loadAllSignalements();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la suppression: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les signalements pour un planning detail
  Future<List<Signalement>> getSignalements(int planningDetailId) async {
    try {
      const sql = '''
        SELECT 
          signalement_id, planning_detail_id, motif, type
        FROM Signalement 
        WHERE planning_detail_id = ? 
        ORDER BY signalement_id DESC
      ''';

      final results = await _db.query(sql, [planningDetailId]);
      return results.map((row) => Signalement.fromJson(row)).toList();
    } catch (e) {
      logger.e(' Erreur récupérer signalements: $e');
      return [];
    }
  }

  /// Met à jour un signalement
  Future<bool> updateSignalement(
    int signalementId,
    String motif,
    String type,
  ) async {
    try {
      final result = await _db.query(
        'UPDATE Signalement SET motif = ?, type = ? WHERE signalement_id = ?',
        [motif, type, signalementId],
      );
      return result.isNotEmpty;
    } catch (e) {
      logger.e(' Erreur mettre à jour signalement: $e');
      return false;
    }
  }

  ///  HELPER: Calcule la différence en MOIS entre deux dates (conforme Kivy relativedelta)
  /// Exemple: 01/01/2026 → 01/03/2026 = 2 mois (pas 59 jours)
  int _calculateMonthsDifference(DateTime dateStart, DateTime dateEnd) {
    int mois = 0;
    DateTime current = dateStart;

    if (dateEnd.isAfter(dateStart)) {
      // Cas positif (décalage)
      while (current.month != dateEnd.month || current.year != dateEnd.year) {
        current = DateTime(current.year, current.month + 1, current.day);
        mois++;

        // Sécurité: limiter à 12 mois pour éviter les boucles infinies
        if (mois > 120) break;
      }
    } else if (dateStart.isAfter(dateEnd)) {
      // Cas négatif (avancement)
      while (current.month != dateEnd.month || current.year != dateEnd.year) {
        current = DateTime(current.year, current.month - 1, current.day);
        mois--;

        // Sécurité
        if (mois < -120) break;
      }
    }

    logger.i('📐 Différence mois: $dateStart → $dateEnd = $mois mois');
    return mois;
  }

  ///  HELPER: Ajoute un nombre de mois à une date (gère les débordements)
  /// Exemple: 01/01/2026 + 2 mois = 01/03/2026
  DateTime _addMonthsToDate(DateTime date, int mois) {
    int newMonth = date.month + mois;
    int newYear = date.year;

    // Gérer les débordements de mois
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }

    // Gérer les jours invalides (ex: 31 février)
    int newDay = date.day;
    DateTime lastDayOfMonth = DateTime(newYear, newMonth + 1, 0);
    if (newDay > lastDayOfMonth.day) {
      newDay = lastDayOfMonth.day;
    }

    return DateTime(newYear, newMonth, newDay);
  }
}
