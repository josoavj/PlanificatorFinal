import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/excel_utils.dart';
import '../utils/date_helper.dart';

class FactureRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = Logger();

  List<Facture> _factures = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Facture> get factures => _factures;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge les factures d'un client avec tous les détails jointes
  /// Conforme à logique Kivy pour affichage complet
  Future<void> loadFacturesForClient(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          f.facture_id,
          f.planning_detail_id,
          f.reference_facture,
          f.montant,
          f.mode,
          f.etablissement_payeur,
          f.date_cheque,
          f.numero_cheque,
          f.date_traitement,
          f.etat,
          f.axe,
          c.client_id,
          c.nom as clientNom,
          c.prenom as clientPrenom,
          tt.typeTraitement as typeTreatment,
          pd.date_planification as datePlanification,
          pd.statut as etatPlanning
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        LEFT JOIN Traitement t ON p.planning_id IN (SELECT planning_id FROM PlanningDetails WHERE planning_detail_id = pd.planning_detail_id)
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        LEFT JOIN Contrat c ON t.contrat_id = c.contrat_id
        WHERE c.client_id = ?
        ORDER BY f.date_traitement DESC
      ''';

      final rows = await _db.query(sql, [clientId]);
      _factures = rows.map((row) => Facture.fromMap(row)).toList();

      logger.i(
        '✅ ${_factures.length} factures chargées pour le client $clientId avec tous détails',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur lors du chargement des factures: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge toutes les factures avec tous les détails jointes
  Future<void> loadAllFactures() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          f.facture_id,
          f.planning_detail_id,
          f.reference_facture,
          f.montant,
          f.mode,
          f.etablissement_payeur,
          f.date_cheque,
          f.numero_cheque,
          f.date_traitement,
          f.etat,
          f.axe,
          c.client_id,
          c.nom as clientNom,
          c.prenom as clientPrenom,
          tt.typeTraitement as typeTreatment,
          pd.date_planification as datePlanification,
          pd.statut as etatPlanning
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        LEFT JOIN Traitement t ON p.planning_id IN (SELECT planning_id FROM PlanningDetails WHERE planning_detail_id = pd.planning_detail_id)
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        LEFT JOIN Contrat c ON t.contrat_id = c.contrat_id
        ORDER BY f.date_traitement DESC
      ''';

      final rows = await _db.query(sql);
      _factures = rows.map((row) => Facture.fromMap(row)).toList();

      logger.i('✅ ${_factures.length} factures chargées avec tous détails');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur lors du chargement des factures: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour le prix d'une facture et recharge les données
  /// (La somme totale se mettra à jour automatiquement grâce à notifyListeners())
  Future<bool> updateFacturePrice(int factureId, int newPrice) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = 'UPDATE Facture SET montant = ? WHERE facture_id = ?';

      await _db.execute(sql, [newPrice, factureId]);

      // Mettre à jour dans la liste locale
      final index = _factures.indexWhere((f) => f.factureId == factureId);
      if (index != -1) {
        _factures[index] = _factures[index].copyWith(montant: newPrice);
      }

      logger.i('✅ Facture $factureId mise à jour: montant=$newPrice Ar');

      // Notifier les listeners pour mettre à jour la somme totale dans l'UI
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur lors de la mise à jour: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marque une facture comme payée et recharge
  Future<bool> markAsPaid(int factureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = 'UPDATE Facture SET etat = ? WHERE facture_id = ?';

      await _db.execute(sql, ['Payée', factureId]);

      // Mettre à jour dans la liste
      final index = _factures.indexWhere((f) => f.factureId == factureId);
      if (index != -1) {
        _factures[index] = _factures[index].copyWith(etat: 'Payée');
      }

      logger.i('✅ Facture $factureId marquée comme payée');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur lors du marquage: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée une facture
  Future<int> createFacture(
    int planningDetailId,
    int montant,
    String mode,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        INSERT INTO Facture (planning_detail_id, montant, mode, date_traitement, etat, axe)
        VALUES (?, ?, ?, ?, 'Non payé', 'Centre (C)')
      ''';

      final id = await _db.insert(sql, [
        planningDetailId,
        montant,
        mode,
        DateTime.now().toString().split(' ')[0], // Date du jour
      ]);

      logger.i('Facture créée avec l\'ID: $id');
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

  /// Supprime une facture
  Future<void> deleteFacture(int factureId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = 'DELETE FROM Facture WHERE facture_id = ?';

      await _db.execute(sql, [factureId]);

      _factures.removeWhere((f) => f.factureId == factureId);

      logger.i('Facture $factureId supprimée');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la suppression: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère le montant total payé
  int getTotalPaid() {
    return _factures
        .where((f) => f.isPaid)
        .fold(0, (sum, f) => sum + f.montant);
  }

  /// Récupère le montant total non payé
  int getTotalUnpaid() {
    return _factures
        .where((f) => !f.isPaid)
        .fold(0, (sum, f) => sum + f.montant);
  }

  /// Génère un export Excel avec les factures et les détails de planification
  Future<String?> generateExcelExport(int clientId, String clientName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Charger les données complètes: Facture + Planning + TypeTraitement
      const sql = '''
        SELECT 
          f.facture_id,
          f.date_traitement as factureDate,
          f.montant,
          f.etat as factureStat,
          f.mode,
          f.etablissement_payeur,
          f.numero_cheque,
          pd.date_planification as datePlanification,
          pd.statut as planningState,
          tt.typeTraitement as traitement,
          c.nom,
          c.prenom
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        LEFT JOIN Traitement t ON p.planning_id IN (
          SELECT DISTINCT planning_id FROM PlanningDetails WHERE planning_detail_id = pd.planning_detail_id
        )
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        LEFT JOIN Contrat c ON t.contrat_id = c.contrat_id
        WHERE c.client_id = ?
        ORDER BY f.date_traitement DESC
      ''';

      final rows = await _db.query(sql, [clientId]);

      // Préparer les données pour Excel
      final List<Map<String, dynamic>> excelData = [];
      for (final row in rows) {
        excelData.add({
          'facture_numero': row['facture_id'],
          'date_planification': DateHelper.format(
            DateHelper.parseAny(row['datePlanification']?.toString() ?? ''),
          ),
          'date_facturation': DateHelper.format(
            DateHelper.parseAny(row['factureDate']?.toString() ?? ''),
          ),
          'type_traitement': row['traitement'] ?? 'N/A',
          'etat_planning': row['planningState'] ?? 'N/A',
          'mode_paiement': row['mode'] ?? 'N/A',
          'etat_paiement': row['factureStat'] ?? 'N/A',
          'montant': row['montant'] ?? 0,
        });
      }

      // Générer et sauvegarder l'Excel
      final filePath = await ExcelUtils.generateAndSaveInvoiceExcel(
        data: excelData,
        clientFullName: clientName,
        clientCategory: 'N/A',
        clientAxis: 'N/A',
        clientAddress: 'N/A',
        clientPhone: 'N/A',
        contractReference: 'N/A',
      );

      logger.i('Export Excel généré: $filePath');
      return filePath;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la génération Excel: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
