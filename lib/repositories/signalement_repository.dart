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

  /// ✅ LOGIQUE CLÉE: Décaler TOUTES les dates futures du même écart
  /// Conforme à Kivy: decaler.active = modifier TOUTES les dates futures
  ///
  /// Le point clé: on ne change PAS la redondance, on décale juste les dates
  /// Exemple: Si on décale le 5 Jan au 15 Jan (+10j), les 5 Fév, 5 Mar... deviennent 15 Fév, 15 Mar...
  ///
  /// Paramètres:
  /// - planningId: ID du planning principal
  /// - planningDetailsId: ID du planning detail qu'on vient de modifier
  /// - ancienneDateModifiee: la date AVANT modification (ex: 5 Jan)
  /// - nouvelleDateModifiee: la date APRÈS modification (ex: 15 Jan)
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
      // ✅ 1. Calculer l'écart de décalage
      final ecartDays = nouvelleDateModifiee
          .difference(ancienneDateModifiee)
          .inDays;
      logger.i('🔄 Décalage des dates futures de $ecartDays jours');

      // ✅ 2. Récupérer tous les details de ce planning
      const getAllDetailsSQL = '''
        SELECT planning_detail_id, date_planification
        FROM PlanningDetails
        WHERE planning_id = ?
        ORDER BY date_planification ASC
      ''';

      final allDetails = await _db.query(getAllDetailsSQL, [planningId]);
      logger.i('📋 Trouvé ${allDetails.length} planning details');

      // ✅ 3. Trouver l'index du planning detail actuellement modifié
      int currentIndex = 0;
      for (int i = 0; i < allDetails.length; i++) {
        if (allDetails[i]['planning_detail_id'] == planningDetailsId) {
          currentIndex = i;
          break;
        }
      }

      // ✅ 4. Décaler TOUTES les dates à partir de currentIndex+1 du même écart
      const updateDetailsSQL = '''
        UPDATE PlanningDetails 
        SET date_planification = ?
        WHERE planning_detail_id = ?
      ''';

      for (int i = currentIndex + 1; i < allDetails.length; i++) {
        final oldDate = DateHelper.toDateTime(
          allDetails[i]['date_planification'],
        );
        // Ajouter l'écart à la date existante
        final newDate = oldDate.add(Duration(days: ecartDays));

        await _db.execute(updateDetailsSQL, [
          DateHelper.toDbFormat(newDate),
          allDetails[i]['planning_detail_id'],
        ]);

        logger.i(
          '  📅 Detail ${allDetails[i]['planning_detail_id']}: ${DateHelper.format(oldDate)} → ${DateHelper.format(newDate)}',
        );
      }

      logger.i('✅ Dates décalées avec succès (redondance inchangée)');
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

      // ✅ 3. Si "changer la redondance" = décaler TOUTES les dates futures du même écart
      if (changerRedondance) {
        logger.i(
          '🔄 MODE DÉCALER: appliquer l\'écart à TOUTES les dates futures',
        );

        await modifierRedondance(
          planningId: planningId,
          planningDetailsId: planningDetailsId,
          ancienneDateModifiee: dateCourante,
          nouvelleDateModifiee: dateSignalement,
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
      logger.e('❌ Erreur mettre à jour signalement: $e');
      return false;
    }
  }
}
