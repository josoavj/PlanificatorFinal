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
          cl.client_id,
          cl.nom as clientNom,
          cl.prenom as clientPrenom,
          tt.typeTraitement as typeTreatment,
          pd.date_planification as datePlanification,
          pd.statut as etatPlanning
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        LEFT JOIN Traitement t ON p.traitement_id = t.traitement_id
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        LEFT JOIN Contrat co ON t.contrat_id = co.contrat_id
        LEFT JOIN Client cl ON co.client_id = cl.client_id
        WHERE cl.client_id = ?
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
          cl.client_id,
          cl.nom as clientNom,
          cl.prenom as clientPrenom,
          tt.typeTraitement as typeTreatment,
          pd.date_planification as datePlanification,
          pd.statut as etatPlanning
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        LEFT JOIN Traitement t ON p.traitement_id = t.traitement_id
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        LEFT JOIN Contrat co ON t.contrat_id = co.contrat_id
        LEFT JOIN Client cl ON co.client_id = cl.client_id
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

  /// Met à jour le montant d'une facture et applique la différence aux factures postérieures
  /// du même traitement. Crée aussi des entrées dans l'historique.
  /// Logique conforme au code Kivy:
  /// - Récupère l'ID du traitement via la facture
  /// - Calcule la différence de prix (newPrix - oldPrix)
  /// - Applique cette différence aux factures du même traitement avec dateTraitement >= date actuelle
  /// - Crée des entrées historique pour chaque modification
  Future<bool> majMontantEtHistorique(
    int factureId,
    int oldMontant,
    int newMontant,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Étape 1: Récupérer la facture et sa date
      const getFactureSql = '''
        SELECT f.facture_id, f.date_traitement, pd.planning_id, p.traitement_id
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        WHERE f.facture_id = ?
      ''';

      final factureRows = await _db.query(getFactureSql, [factureId]);
      if (factureRows.isEmpty) {
        throw Exception('Facture non trouvée');
      }

      final factureRow = factureRows[0];
      final dateTraitement = factureRow['date_traitement'];
      final traitementId = factureRow['traitement_id'];

      if (dateTraitement == null || traitementId == null) {
        throw Exception('Données incomplètes pour la facture');
      }

      // Étape 2: Calculer la différence
      final prixDiff = newMontant - oldMontant;
      logger.i(
        '📊 Différence de prix: $prixDiff Ar (ancien: $oldMontant, nouveau: $newMontant)',
      );

      // Étape 3: Récupérer toutes les factures du même traitement avec date >= dateActuelle
      const getOtherFacturesSql = '''
        SELECT f.facture_id, f.montant, f.date_traitement
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        WHERE p.traitement_id = ? AND f.date_traitement >= ?
        ORDER BY f.date_traitement ASC
      ''';

      final otherFactures = await _db.query(getOtherFacturesSql, [
        traitementId,
        dateTraitement,
      ]);

      // Étape 4: Mettre à jour tous les montants et créer l'historique
      int updatedCount = 0;
      final now = DateTime.now();

      for (final row in otherFactures) {
        final fId = row['facture_id'] as int;
        final ancienMontant = row['montant'] as int;
        final nouveauMontant = ancienMontant + prixDiff;

        // Mettre à jour le montant
        const updateSql = 'UPDATE Facture SET montant = ? WHERE facture_id = ?';
        await _db.execute(updateSql, [nouveauMontant, fId]);

        // Créer une entrée historique
        const historiqueSql = '''
          INSERT INTO Historique_prix (facture_id, old_amount, new_amount, change_date)
          VALUES (?, ?, ?, ?)
        ''';
        await _db.execute(historiqueSql, [
          fId,
          ancienMontant,
          nouveauMontant,
          now.toIso8601String(),
        ]);

        logger.i(
          '✅ Facture $fId mise à jour: $ancienMontant → $nouveauMontant Ar',
        );
        updatedCount++;
      }

      // Étape 5: Mettre à jour la liste locale
      for (final facture in _factures) {
        if (facture.dateTraitement.compareTo(
                  DateTime.parse(dateTraitement.toString()),
                ) >=
                0 &&
            facture.montant > 0) {
          final newMontantLocal = facture.montant + prixDiff;
          final index = _factures.indexOf(facture);
          if (index != -1) {
            _factures[index] = facture.copyWith(montant: newMontantLocal);
          }
        }
      }

      logger.i(
        '✅ $updatedCount facture(s) mises à jour avec la différence de $prixDiff Ar',
      );

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur lors de majMontantEtHistorique: $e');
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

  /// Version complète pour créer une facture avec tous les paramètres
  Future<int> createFactureComplete({
    required int planningDetailId,
    required String referenceFacture,
    required int montant,
    required String mode,
    required String etat,
    required String axe,
    required DateTime dateTraitement,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        INSERT INTO Facture (planning_detail_id, reference_facture, montant, mode, date_traitement, etat, axe)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ''';

      final id = await _db.insert(sql, [
        planningDetailId,
        referenceFacture.isEmpty ? null : referenceFacture,
        montant,
        mode,
        dateTraitement.toIso8601String().split('T')[0],
        etat,
        axe,
      ]);

      logger.i(
        'Facture créée avec l\'ID: $id (planning_detail_id: $planningDetailId, montant: $montant)',
      );
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la création facture: $e');
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
