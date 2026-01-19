import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../services/logging_service.dart';
import '../utils/excel_utils.dart';
import '../utils/date_helper.dart';
import '../utils/date_utils.dart' as date_utils;

class FactureRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'facture_repository');

  List<Facture> _factures = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Facture> get factures => _factures;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ✅ Charge les factures d'un contrat
  Future<List<Facture>> loadFacturesForContrat(int contratId) async {
    try {
      const sql = '''
        SELECT DISTINCT f.*
        FROM Facture f
        INNER JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        INNER JOIN Planning p ON pd.planning_id = p.planning_id
        INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
        INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
        INNER JOIN Client cl ON co.client_id = cl.client_id
        WHERE t.contrat_id = ?
        ORDER BY cl.nom ASC
      ''';

      final rows = await _db.query(sql, [contratId]);
      final factures = rows.map((row) => Facture.fromMap(row)).toList();
      logger.i(
        '✅ ${factures.length} factures chargées pour contrat $contratId',
      );
      return factures;
    } catch (e) {
      logger.e('Erreur chargement factures contrat: $e');
      return [];
    }
  }

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
          cl.categorie as clientCategorie,
          tt.typeTraitement as typeTreatment,
          pd.date_planification as datePlanification,
          pd.statut as etatPlanning
        FROM Facture f
        INNER JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        INNER JOIN Planning p ON pd.planning_id = p.planning_id
        INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
        INNER JOIN Client cl ON co.client_id = cl.client_id
        WHERE cl.client_id = ?
        ORDER BY cl.nom ASC
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
      // Requête optimisée: utilise INNER JOIN pour les liens critiques
      // et LEFT JOIN pour les données optionnelles
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
          COALESCE(cl.client_id, 0) as client_id,
          COALESCE(cl.nom, 'Non associé') as clientNom,
          COALESCE(cl.prenom, '') as clientPrenom,
          COALESCE(cl.categorie, '') as clientCategorie,
          COALESCE(tt.typeTraitement, 'Non défini') as typeTreatment,
          COALESCE(pd.date_planification, '2000-01-01') as datePlanification,
          COALESCE(pd.statut, 'Non planifié') as etatPlanning
        FROM Facture f
        INNER JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        INNER JOIN Planning p ON pd.planning_id = p.planning_id
        INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        INNER JOIN Contrat co ON t.contrat_id = co.contrat_id
        INNER JOIN Client cl ON co.client_id = cl.client_id
        ORDER BY COALESCE(cl.nom, 'Z') ASC
        LIMIT 10000
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

  /// Récupère les factures associées à un planning_detail_id
  Future<List<Facture>> getFacturesByPlanningDetail(
    int planningDetailId,
  ) async {
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
          f.axe
        FROM Facture f
        WHERE f.planning_detail_id = ?
        ORDER BY f.date_traitement DESC
      ''';

      final rows = await _db.query(sql, [planningDetailId]);
      final factures = rows.map((row) => Facture.fromMap(row)).toList();

      logger.i(
        '✅ ${factures.length} factures trouvées pour planning_detail_id $planningDetailId',
      );
      return factures;
    } catch (e) {
      logger.e('❌ Erreur lors du chargement des factures: $e');
      return [];
    }
  }

  /// Récupère l'historique des changements de prix d'une facture
  Future<List<Map<String, dynamic>>> getPriceHistory(int factureId) async {
    try {
      const sql = '''
        SELECT 
          history_id,
          facture_id,
          old_amount,
          new_amount,
          change_date,
          changed_by
        FROM Historique_prix
        WHERE facture_id = ?
        ORDER BY change_date ASC
      ''';

      final rows = await _db.query(sql, [factureId]);
      logger.i(
        '✅ ${rows.length} changements de prix trouvés pour facture_id $factureId',
      );
      return rows;
    } catch (e) {
      logger.e('❌ Erreur lors du chargement de l\'historique des prix: $e');
      return [];
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

  /// Met à jour la référence d'une facture
  Future<bool> updateFactureReference(
    int factureId,
    String newReference,
  ) async {
    try {
      const sql =
          'UPDATE Facture SET reference_facture = ? WHERE facture_id = ?';

      // Envoyer null à la BD si vide, sinon la nouvelle valeur
      final refValue = newReference.isEmpty ? null : newReference;
      await _db.execute(sql, [refValue, factureId]);

      // Mettre à jour dans la liste locale
      final index = _factures.indexWhere((f) => f.factureId == factureId);
      if (index != -1) {
        final old = _factures[index];
        // Créer une nouvelle instance avec la référence mise à jour
        _factures[index] = Facture(
          factureId: old.factureId,
          planningDetailsId: old.planningDetailsId,
          referenceFacture: refValue,
          montant: old.montant,
          mode: old.mode,
          etablissementPayeur: old.etablissementPayeur,
          dateCheque: old.dateCheque,
          numeroCheque: old.numeroCheque,
          dateTraitement: old.dateTraitement,
          etat: old.etat,
          axe: old.axe,
          clientId: old.clientId,
          clientNom: old.clientNom,
          clientPrenom: old.clientPrenom,
          typeTreatment: old.typeTreatment,
          datePlanification: old.datePlanification,
          etatPlanning: old.etatPlanning,
        );
      }

      logger.i('✅ Référence facture $factureId mise à jour: $newReference');

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('❌ Erreur lors de la mise à jour de la référence: $e');
      return false;
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
        SELECT f.facture_id, f.montant, f.date_traitement, f.etat
        FROM Facture f
        LEFT JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        LEFT JOIN Planning p ON pd.planning_id = p.planning_id
        WHERE p.traitement_id = ? AND f.date_traitement >= ?
        ORDER BY f.date_traitement DESC
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
        final etat = (row['etat'] as String?)?.trim() ?? '';

        // ✅ LOGIQUE: Si la facture est déjà payée, ne pas modifier le montant
        if (etat == 'Payé' || etat == 'Payée') {
          logger.i('⚠️ Facture $fId est payée, montant inchangé (état: $etat)');
          continue; // Passer à la prochaine facture
        }

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
          // ✅ LOGIQUE: Ne pas modifier les factures payées
          if (facture.etat != 'Payé' && facture.etat != 'Payée') {
            final newMontantLocal = facture.montant + prixDiff;
            final index = _factures.indexOf(facture);
            if (index != -1) {
              _factures[index] = facture.copyWith(montant: newMontantLocal);
            }
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
  /// Évite les doublons - vérifie si la facture existe déjà pour ce planning detail
  Future<int> createFactureComplete({
    required int planningDetailId,
    required String referenceFacture,
    required int montant,
    String? mode, // ✅ Mode peut être null (à définir plus tard)
    required String etat,
    String? axe, // ✅ Axe peut être null (à définir plus tard)
    required DateTime dateTraitement,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ✅ Vérifier si une facture existe déjà pour ce planning detail
      const checkSql =
          'SELECT facture_id FROM Facture WHERE planning_detail_id = ?';
      final existing = await _db.query(checkSql, [planningDetailId]);

      if (existing.isNotEmpty) {
        logger.i(
          '⚠️ Facture existe déjà pour planning_detail_id=$planningDetailId, ID=${existing[0]['facture_id']}',
        );
        return existing[0]['facture_id'] as int;
      }

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
      final excelService = ExcelService();
      await excelService.genererFactureExcel(
        excelData,
        clientName,
        DateTime.now().year,
        DateTime.now().month,
      );

      logger.i('Export Excel généré pour le client: $clientName');
      return 'Export généré avec succès';
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la génération Excel: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ REPAIR FUNCTION: Régénère les factures pour un contrat
  /// Utile pour corriger les factures manquantes ou erronées
  ///
  /// Étapes:
  /// 1. Récupère l'axe du client et le montant automatiquement
  /// 2. Récupère tous les PlanningDetails du contrat
  /// 3. Supprime les factures existantes (OPTIONAL)
  /// 4. Crée de nouvelles factures pour chaque PlanningDetail
  Future<int> regenerateFacturesForContrat({
    required int contratId,
    bool deleteExisting = false,
  }) async {
    // DEPRECATED: Use regenerateFacturesForTraitement instead
    return 0;
  }

  /// ✅ REPAIR FUNCTION: Régénère les factures pour un traitement spécifique
  /// Utile pour corriger les factures manquantes ou erronées d'un traitement
  ///
  /// Étapes:
  /// 1. Crée les PlanningDetails manquants si besoin
  /// 2. Crée une facture pour chaque PlanningDetail manquant
  /// 3. Génère les références avec le montant demandé
  Future<int> regenerateFacturesForTraitement({
    required int traitementId,
    required int montant,
    required String referencePrefix,
    bool deleteExisting = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      logger.i('🔧 REPAIR: Planning + Factures pour traitement $traitementId');
      logger.i('   💰 Montant: $montant Ar');
      logger.i('   📑 Référence: $referencePrefix');

      // 1. Récupérer l'axe et le Planning
      const sqlGetAxe = '''
        SELECT DISTINCT cl.axe
        FROM Traitement t
        INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
        INNER JOIN Client cl ON c.client_id = cl.client_id
        WHERE t.traitement_id = ?
      ''';

      final axeResult = await _db.query(sqlGetAxe, [traitementId]);
      if (axeResult.isEmpty) throw Exception('Traitement non trouvé');
      final axe = axeResult[0]['axe'] as String;

      const sqlGetPlanning = '''
        SELECT p.planning_id, p.date_debut_planification, p.duree_traitement, p.redondance
        FROM Planning p WHERE p.traitement_id = ? LIMIT 1
      ''';

      final planningResult = await _db.query(sqlGetPlanning, [traitementId]);
      if (planningResult.isEmpty) throw Exception('Planning non trouvé');

      final planningId = planningResult[0]['planning_id'] as int;
      final dureeTraitement = planningResult[0]['duree_traitement'] as int;
      final redondance = planningResult[0]['redondance'] as int;
      logger.i(
        '   📅 Planning: ID=$planningId, Durée=$dureeTraitement, Redondance=$redondance',
      );

      // 2. Créer les PlanningDetails manquants
      const sqlCountDetails =
          'SELECT COUNT(*) as count FROM PlanningDetails WHERE planning_id = ?';
      final countResult = await _db.query(sqlCountDetails, [planningId]);
      final existingCount = (countResult[0]['count'] as int?) ?? 0;

      int planningDetailsCreated = 0;
      if (existingCount == 0) {
        final dateDebut = DateTime.parse(
          planningResult[0]['date_debut_planification'] as String,
        );
        logger.i('   🔄 Génération des dates...');

        final planningDates = _generatePlanningDates(
          dateDebut: dateDebut,
          dureeTraitement: dureeTraitement,
          redondance: redondance,
        );

        logger.i('   ✅ ${planningDates.length} dates générées');

        for (final date in planningDates) {
          try {
            const sqlInsert = '''
              INSERT INTO PlanningDetails (planning_id, date_planification)
              VALUES (?, ?)
            ''';
            await _db.execute(sqlInsert, [planningId, date.toIso8601String()]);
            planningDetailsCreated++;
            logger.i(
              '   ✅ PlanningDetail créé: ${date.toIso8601String()} (ID Planning=$planningId)',
            );
          } catch (e) {
            logger.e('   ❌ Erreur création PlanningDetail: $e');
          }
        }
        logger.i('   🎉 $planningDetailsCreated Planning Details créés');
      } else {
        logger.i('   ℹ️ $existingCount Planning Details existent déjà');
      }

      // 3. Créer les factures
      const sqlGetDetails = '''
        SELECT DISTINCT pd.planning_detail_id, pd.date_planification
        FROM PlanningDetails pd WHERE pd.planning_id = ? ORDER BY pd.date_planification ASC
      ''';

      final planningDetails = await _db.query(sqlGetDetails, [planningId]);
      logger.i(
        '   📋 Total Planning Details trouvés: ${planningDetails.length}',
      );

      if (planningDetails.isEmpty) {
        logger.w('   ⚠️ Aucun PlanningDetail trouvé! Vérifiez la création.');
        return 0;
      }

      int facturesCreated = 0;
      int sequenceNumber = 1;

      for (final pd in planningDetails) {
        final pdId = pd['planning_detail_id'] as int;
        final dateStr = pd['date_planification'] as String;

        const sqlCheck =
            'SELECT facture_id FROM Facture WHERE planning_detail_id = ?';
        final existing = await _db.query(sqlCheck, [pdId]);

        if (existing.isNotEmpty && !deleteExisting) {
          logger.i('   ⏭️ Facture existe pour PD #$pdId');
          continue;
        }

        final ref = '$referencePrefix-$sequenceNumber';
        final factureId = await createFactureComplete(
          planningDetailId: pdId,
          referenceFacture: ref,
          montant: montant,
          mode: null,
          etat: 'À venir',
          axe: axe,
          dateTraitement: DateTime.parse(dateStr),
        );

        if (factureId != -1) {
          facturesCreated++;
          logger.i('   ✅ Facture créée: $ref (PD#$pdId)');
        }
        sequenceNumber++;
      }

      logger.i(
        '🎉 TERMINÉ: $planningDetailsCreated PD + $facturesCreated factures',
      );
      return facturesCreated;
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      logger.e('❌ $e');
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Génère les dates de planning (utilise date_utils pour cohérence)
  List<DateTime> _generatePlanningDates({
    required DateTime dateDebut,
    required int dureeTraitement,
    required int redondance,
  }) {
    return date_utils.DateUtils.generatePlanningDates(
      dateDebut: dateDebut,
      dureeTraitement: dureeTraitement,
      redondance: redondance,
    );
  }
}
