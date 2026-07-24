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
      return await _db.transaction((conn) async {
        // 1. Récupérer clientId
        int clientId = 0;
        final clientRes = await conn.query(
          SqlQueries.getClientIdFromPlanningDetail,
          [planningDetailsId],
        );
        if (clientRes.isNotEmpty) {
          clientId = clientRes.first['client_id'] as int? ?? 0;
        }

        // 2. Créer la remarque
        await conn.query(SqlQueries.createRemarque, [
          clientId,
          planningDetailsId,
          factureId,
          contenu,
          probleme,
          action,
        ]);

        // 3. Marquer le planning detail comme "Effectué"
        await conn.query(SqlQueries.updatePlanningDetailStatut, ['Effectué', planningDetailsId]);

        // 4. Si payée, mettre à jour la facture
        if (estPayee) {
          await conn.query(SqlQueries.updateFactureFull, [
            'Payé',
            modePaiement,
            numeroCheque,
            datePayement != null ? DateHelper.reverseFormat(datePayement) : null,
            modePaiement == 'Chèque' ? etablissement : null,
            factureId,
          ]);
        }

        logger.i(' Transaction Remarque réussie pour PD $planningDetailsId');
        await loadRemarques();
        return true;
      });
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur Transaction Remarque: $e');
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
  Future<List<Remarque>> getRemarques(int planningDetailId, {bool useCache = true}) async {
    try {
      final rows = await _db.query(SqlQueries.getRemarquesByPlanningDetail, [planningDetailId], useCache);
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

  /// Met à jour une remarque existante et éventuellement la facture associée
  Future<bool> updateRemarqueFull({
    required int remarqueId,
    required int factureId,
    String? contenu,
    String? probleme,
    String? action,
    String? modePaiement,
    String? datePayement,
    String? etablissement,
    String? numeroCheque,
    bool estPayee = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Mettre à jour la table Remarque
      await _db.execute(SqlQueries.updateRemarqueBasic, [
        contenu,
        probleme,
        action,
        remarqueId,
      ]);

      // 2. Mettre à jour la table Facture
      // On utilise updateFactureFull pour tout synchroniser
      await _db.execute(SqlQueries.updateFactureFull, [
        estPayee ? 'Payé' : 'Non payé',
        modePaiement,
        numeroCheque,
        datePayement != null ? DateHelper.reverseFormat(datePayement) : null,
        modePaiement == 'Chèque' ? etablissement : null,
        factureId,
      ]);

      logger.i(' Mise à jour complète effectuée pour remarque $remarqueId');
      await loadRemarques();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la mise à jour de la remarque: $e');
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
