import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/date_helper.dart';

/// Repository pour la gestion des remarques
/// Conforme à Kivy create_remarque() - crée remarque + met à jour état planning + facture
class RemarqueRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = Logger();

  List<Remarque> _remarques = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Remarque> get remarques => _remarques;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ✅ CLÉE: Crée une remarque COMPLÈTE
  /// Conforme à Kivy create_remarque() (lignes 866-925)
  ///
  /// Étapes:
  /// 1. Créer la remarque
  /// 2. Marquer le planning detail comme "Effectué"
  /// 3. Mettre à jour l'état de la facture si payée
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
      // ✅ 1. Créer la remarque
      const createRemarqueSQL = '''
        INSERT INTO Remarque 
        (client_id, planning_detail_id, facture_id, contenu, issue, action)
        VALUES (?, ?, ?, ?, ?, ?)
      ''';

      // Récupérer clientId depuis la BD si non fourni
      int? clientId = null;
      if (clientId == null && factureId != null) {
        try {
          final result = await _db.queryOne(
            'SELECT c.client_id FROM Client c JOIN Contrat ct ON c.client_id = ct.client_id JOIN Traitement t ON ct.contrat_id = t.contrat_id JOIN Planning p ON t.traitement_id = p.traitement_id JOIN PlanningDetails pd ON p.planning_id = pd.planning_id WHERE pd.planning_detail_id = ?',
            [planningDetailsId],
          );
          clientId = result?['client_id'] as int? ?? 0;
        } catch (e) {
          clientId = 0;
        }
      }

      await _db.execute(createRemarqueSQL, [
        clientId ?? 0,
        planningDetailsId,
        factureId,
        contenu,
        probleme,
        action,
      ]);

      logger.i('✅ Remarque créée pour planning_detail_id=$planningDetailsId');

      // ✅ 2. Marquer le planning detail comme "Effectué"
      const updatePlanningSQL = '''
        UPDATE PlanningDetails
        SET statut = ?
        WHERE planning_detail_id = ?
      ''';

      await _db.execute(updatePlanningSQL, ['Effectué', planningDetailsId]);
      logger.i('✅ Planning detail $planningDetailsId marqué comme Effectué');

      // ✅ 3. Si payée, mettre à jour l'état de la facture
      if (estPayee) {
        const updateFactureSQL = '''
          UPDATE Facture
          SET etat = ?, mode = ?, numero_cheque = ?, date_cheque = ?
          WHERE facture_id = ?
        ''';

        await _db.execute(updateFactureSQL, [
          'Payé',
          modePaiement,
          numeroCheque,
          datePayement != null ? DateHelper.reverseFormat(datePayement) : null,
          factureId,
        ]);

        logger.i('✅ Facture $factureId marquée comme payée');
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
      const sql = '''
        SELECT 
          r.remarque_id, r.client_id, r.planning_detail_id, r.facture_id, r.contenu, 
          r.issue, r.action, r.date_remarque
        FROM Remarque r
        ORDER BY r.date_remarque DESC
      ''';

      final rows = await _db.query(sql);
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
      const sql = '''
        SELECT 
          r.remarque_id, r.client_id, r.planning_detail_id, r.facture_id, r.contenu, 
          r.issue, r.action, r.date_remarque
        FROM Remarque r
        WHERE r.planning_detail_id = ?
        ORDER BY r.date_remarque DESC
      ''';

      final rows = await _db.query(sql, [planningDetailId]);
      return rows.map((row) => Remarque.fromJson(row)).toList();
    } catch (e) {
      logger.e('❌ Erreur récupérer remarques: $e');
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
      const updateRemarqueSQL = '''
        UPDATE Remarque
        SET contenu = ?, issue = ?, action = ?
        WHERE remarque_id = ?
      ''';

      await _db.execute(updateRemarqueSQL, [
        'Paiement effectué',
        null,
        'Facture marquée comme payée',
        remarqueId,
      ]);

      // Mettre à jour facture
      const updateFactureSQL = '''
        UPDATE Facture
        SET etat = ?, mode = ?, numero_cheque = ?, date_cheque = ?
        WHERE facture_id = ?
      ''';

      await _db.execute(updateFactureSQL, [
        'Payé',
        modePaiement,
        numeroCheque,
        datePayement != null ? DateHelper.reverseFormat(datePayement) : null,
        factureId,
      ]);

      logger.i('✅ Remarque et facture mises à jour');
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
      const sql = 'DELETE FROM Remarque WHERE remarque_id = ?';
      await _db.execute(sql, [remarqueId]);

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
