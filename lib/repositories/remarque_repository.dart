import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/date_helper.dart';
import '../core/sql_queries.dart';

/// Repository pour la gestion des remarques
/// Conforme à Kivy create_remarque() - crée remarque + met à jour état planning + facture
class RemarqueRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'remarque_repository');

  List<Remarque> _remarques = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Remarque> get remarques => _remarques;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> createRemarque({
    required int planningDetailsId,
    required int factureId,
    String? contenu,
    String? probleme,
    String? action,
    String? modePaiement,
    String? numeroFacture,
    String? datePayement,
    String? etablissement,
    String? numeroCheque,
    bool estPayee = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      //  1. Créer la remarque
      // Récupérer clientId depuis la BD
      int clientId = 0;
      try {
        final result = await _db.queryOne(
          SqlQueries.getClientIdFromPlanningDetail,
          [planningDetailsId],
        );
        clientId = result?['client_id'] as int? ?? 0;
      } catch (e) {
        clientId = 0;
      }

      await _db.execute(SqlQueries.createRemarque, [
        clientId,
        planningDetailsId,
        factureId,
        contenu,
        probleme,
        action,
      ]);

      logger.i(' Remarque créée pour planning_detail_id=$planningDetailsId');

      //  2. Marquer le planning detail comme "Effectué"
      await _db.execute(SqlQueries.updatePlanningDetailStatut, ['Effectué', planningDetailsId]);
      logger.i(' Planning detail $planningDetailsId marqué comme Effectué');

      //  3. Si payée, mettre à jour l'état de la facture
      if (estPayee) {
        await _db.execute(SqlQueries.updateFactureFull, [
          'Payé',
          modePaiement,
          numeroCheque,
          datePayement != null ? DateHelper.reverseFormat(datePayement) : null,
          modePaiement == 'Chèque' ? etablissement : null,
          factureId,
        ]);

        logger.i(' Facture $factureId marquée comme payée');
      }

      // Recharger les remarques
      await loadRemarques();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la création de la remarque: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge toutes les remarques
  Future<void> loadRemarques() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rows = await _db.query(SqlQueries.getAllRemarquesDetailed);
      _remarques = rows.map((row) => Remarque.fromJson(row)).toList();

      logger.i('${_remarques.length} remarques chargées');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des remarques: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge les remarques pour un planning detail
  Future<List<Remarque>> getRemarques(int planningDetailId) async {
    try {
      final rows = await _db.query(SqlQueries.getRemarquesByPlanningDetail, [planningDetailId]);
      return rows.map((row) => Remarque.fromJson(row)).toList();
    } catch (e) {
      logger.e(' Erreur récupérer remarques: $e');
      return [];
    }
  }

  /// Met à jour l'état de paiement d'une remarque + facture
  Future<bool> updateRemarquePaiement({
    required int remarqueId,
    required int factureId,
    required String modePaiement,
    String? numeroFacture,
    String? datePayement,
    String? etablissement,
    String? numeroCheque,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Mettre à jour remarque - Remarque n'a pas ces colonnes
      // On ne peut modifier que contenu, issue, action dans Remarque
      await _db.execute(SqlQueries.updateRemarqueBasic, [
        'Paiement effectué',
        null,
        'Facture marquée comme payée',
        remarqueId,
      ]);

      // Mettre à jour facture
      await _db.execute(SqlQueries.updateFacturePaymentOnly, [
        'Payé',
        modePaiement,
        numeroCheque,
        datePayement != null ? DateHelper.reverseFormat(datePayement) : null,
        factureId,
      ]);

      logger.i(' Remarque et facture mises à jour');
      await loadRemarques();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la mise à jour: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime une remarque
  Future<bool> deleteRemarque(int remarqueId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.execute(SqlQueries.deleteRemarque, [remarqueId]);

      logger.i('Remarque $remarqueId supprimée');
      await loadRemarques();
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
}
