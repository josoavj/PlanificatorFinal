import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/date_helper.dart';

/// Repository pour la gestion des signalements (avancement/décalage)
/// Conforme à la logique Kivy (main.py, signaler())
class SignalementRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = Logger();

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
      const sql = '''
        SELECT 
          signalement_id, planning_detail_id, motif, type
        FROM Signalement
        ORDER BY signalement_id DESC
      ''';

      final rows = await _db.query(sql);
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
      const sql = '''
        INSERT INTO Signalement 
        (planning_details_id, motif, type, date_signalement)
        VALUES (?, ?, ?, ?)
      ''';

      final now = DateTime.now();
      await _db.execute(sql, [
        planningDetailsId,
        motif,
        type,
        DateHelper.toDbFormat(now),
      ]);

      logger.i('✅ Signalement créé: type=$type, motif=$motif');

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

  /// ✅ LOGIQUE CLÉE: Modifier la date de planning
  /// Conforme à Kivy: garder.active = modifier JUSTE cette date
  Future<bool> modifierDatePlanning({
    required int planningDetailsId,
    required DateTime newDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        UPDATE PlanningDetails 
        SET date_planification = ?
        WHERE id_planning_details = ?
      ''';

      await _db.execute(sql, [
        DateHelper.toDbFormat(newDate),
        planningDetailsId,
      ]);

      logger.i('✅ Date modifiée pour planning_details_id=$planningDetailsId');
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

  /// ✅ LOGIQUE CLÉE: Modifier la redondance (fréquence) pour TOUTES les dates futures
  /// Conforme à Kivy: decaler.active = modifier TOUTES les dates futures
  ///
  /// Paramètres:
  /// - planningId: ID du planning principal
  /// - planningDetailsId: ID du planning detail où on est
  /// - newRedondance: nouvelle fréquence en mois (0='1 jour', 1='1 mois', 2='2 mois', etc.)
  Future<bool> modifierRedondance({
    required int planningId,
    required int planningDetailsId,
    required int newRedondance,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ 1. Mettre à jour la redondance du Planning
      const updatePlanningSQL = '''
        UPDATE Planning 
        SET redondance = ?
        WHERE planning_id = ?
      ''';

      await _db.execute(updatePlanningSQL, [newRedondance, planningId]);
      logger.i(
        '✅ Redondance mise à jour: planning_id=$planningId, redondance=$newRedondance',
      );

      // ✅ 2. Récupérer la date actuelle
      const getDateSQL = '''
        SELECT date_planification
        FROM PlanningDetails
        WHERE planning_detail_id = ?
      ''';

      final dateRow = await _db.queryOne(getDateSQL, [planningDetailsId]);
      if (dateRow == null) {
        throw Exception('Planning detail non trouvé');
      }

      final currentDate = DateHelper.toDateTime(dateRow['date_planification']);

      // ✅ 3. Récupérer tous les details de ce planning
      const getAllDetailsSQL = '''
        SELECT planning_detail_id, date_planification
        FROM PlanningDetails
        WHERE planning_id = ?
        ORDER BY date_planification ASC
      ''';

      final allDetails = await _db.query(getAllDetailsSQL, [planningId]);
      logger.i('📋 Trouvé ${allDetails.length} planning details');

      // ✅ 4. Recalculer les dates avec la nouvelle redondance
      // Trouver l'index de la date actuelle
      int currentIndex = 0;
      for (int i = 0; i < allDetails.length; i++) {
        final detailDate = DateHelper.toDateTime(
          allDetails[i]['date_planification'],
        );
        if (detailDate.year == currentDate.year &&
            detailDate.month == currentDate.month &&
            detailDate.day == currentDate.day) {
          currentIndex = i;
          break;
        }
      }

      // ✅ 5. Modifier TOUTES les dates à partir de currentIndex+1
      const updateDetailsSQL = '''
        UPDATE PlanningDetails 
        SET date_planification = ?
        WHERE planning_detail_id = ?
      ''';

      if (newRedondance == 0) {
        // Cas spécial: "une seule fois" = supprimer toutes les autres dates
        logger.i(
          '🔄 Suppression des dates après la date courante (redondance=0)',
        );
        // On garde juste la date actuelle, on supprime les autres
        for (int i = currentIndex + 1; i < allDetails.length; i++) {
          const deleteSQL =
              '''DELETE FROM PlanningDetails WHERE planning_detail_id = ?''';
          await _db.execute(deleteSQL, [allDetails[i]['planning_detail_id']]);
        }
      } else {
        // Cas normal: recalculer avec nouvelle fréquence
        DateTime newDate = currentDate;
        for (int i = currentIndex + 1; i < allDetails.length; i++) {
          // Ajouter newRedondance mois (peut être négatif pour avancement)
          // Utiliser DateTime pour calculer correctement même avec mois négatifs
          newDate = DateTime(
            newDate.year,
            newDate.month + newRedondance,
            newDate.day,
          );

          // Gérer les débordements de mois (avant mois 1 ou après mois 12)
          while (newDate.month < 1) {
            newDate = DateTime(
              newDate.year - 1,
              newDate.month + 12,
              newDate.day,
            );
          }
          while (newDate.month > 12) {
            newDate = DateTime(
              newDate.year + 1,
              newDate.month - 12,
              newDate.day,
            );
          }

          await _db.execute(updateDetailsSQL, [
            DateHelper.toDbFormat(newDate),
            allDetails[i]['planning_detail_id'],
          ]);

          logger.i(
            '  📅 Detail ${allDetails[i]['planning_detail_id']} → ${DateHelper.format(newDate)}',
          );
        }
      }

      logger.i('✅ Redondance modifiée avec succès');
      await loadAllSignalements();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la modification de redondance: $e');
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
    changerRedondance, // true=modifier TOUTES les futures, false=modifier JUSTE celle-ci
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ 1. Créer le signalement
      await createSignalement(
        planningDetailsId: planningDetailsId,
        motif: motif,
        type: type,
      );

      // ✅ 2. Modifier la date (toujours applicable)
      await modifierDatePlanning(
        planningDetailsId: planningDetailsId,
        newDate: dateSignalement,
      );

      // ✅ 3. Si "changer la redondance" = recalculer intervalle et modifier TOUTES les futures
      if (changerRedondance) {
        // Calculer l'intervalle entre ancienne et nouvelle date
        final difference = dateSignalement.difference(dateCourante);
        var newRedondance = (difference.inDays / 30).round();

        // ✅ IMPORTANT: Appliquer le type pour influer sur la redondance
        // - Si "avancement" (date antérieure): la redondance doit diminuer ou devenir négative
        // - Si "décalage" (date postérieure): la redondance doit augmenter ou rester positive
        if (type == 'avancement') {
          // Avancement = on rapproche les dates (redondance diminue)
          // Si différence est négative (-30 jours), newRedondance = -1 (moins souvent)
          newRedondance = newRedondance.abs() * -1; // Forcer négatif
          logger.i(
            '⏪ AVANCEMENT détecté: intervalle=${difference.inDays} jours ≈ $newRedondance mois (diminue la fréquence)',
          );
        } else if (type == 'décalage') {
          // Décalage = on éloigne les dates (redondance augmente)
          // Si différence est positive (+30 jours), newRedondance = +1 (plus souvent)
          newRedondance = newRedondance.abs(); // Forcer positif
          logger.i(
            '⏩ DÉCALAGE détecté: intervalle=${difference.inDays} jours ≈ $newRedondance mois (augmente la fréquence)',
          );
        }

        logger.i(
          '📊 Changement redondance: type=$type, intervalle=${difference.inDays} jours ≈ $newRedondance mois',
        );

        await modifierRedondance(
          planningId: planningId,
          planningDetailsId: planningDetailsId,
          newRedondance: newRedondance,
        );
      }

      logger.i('✅ Enregistrement signalement réussi');
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
      const sql = 'DELETE FROM Signalement WHERE signalementId = ?';
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
          signalementId, planning_details_id, motif, type, date_signalement
        FROM Signalement 
        WHERE planning_details_id = ? 
        ORDER BY date_signalement DESC
      ''';

      final results = await _db.query(sql, [planningDetailId]);
      return results.map((row) => Signalement.fromJson(row)).toList();
    } catch (e) {
      logger.e('❌ Erreur récupérer signalements: $e');
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
      print('❌ Erreur mettre à jour signalement: $e');
      return false;
    }
  }
}
