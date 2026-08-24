import 'dart:async';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/excel_utils.dart';
import '../utils/date_helper.dart';
import '../utils/date_utils.dart' as date_utils;
import '../core/sql_queries.dart';

class FactureRepository extends ChangeNotifier {
  final DatabaseService _db;
  final logger = createLoggerWithFileOutput(name: 'facture_repository');

  List<Facture> _factures = [];
  bool _isLoading = false;
  bool _hasMoreFactures = true;
  String? _errorMessage;

  // Constructeur avec injection optionnelle
  FactureRepository({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService();

  List<Facture> get factures => _factures;
  bool get isLoading => _isLoading;
  bool get hasMoreFactures => _hasMoreFactures;
  String? get errorMessage => _errorMessage;

  /// Charge les factures par page
  Future<void> loadFacturesPage(int page, {int pageSize = 100}) async {
    _isLoading = page == 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = page * pageSize;
      final rows = await _db.query(SqlQueries.getAllFacturesDetailed, [pageSize, offset]);
      
      final newFactures = rows.map((row) => Facture.fromMap(row)).toList();
      
      if (page == 0) {
        _factures = newFactures;
      } else {
        _factures.addAll(newFactures);
      }

      _hasMoreFactures = newFactures.length == pageSize;
      logger.i('Page $page: ${newFactures.length} factures chargées (Total: ${_factures.length}, Plus: $_hasMoreFactures)');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur pagination factures: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge toutes les factures (Legacy wrapper)
  Future<void> loadAllFactures() async {
    await loadFacturesPage(0, pageSize: 1000);
  }

  ///  Charge les factures d'un contrat
  Future<List<Facture>> loadFacturesForContrat(int contratId) async {
    try {
      final rows = await _db
          .query(SqlQueries.getFacturesByContrat, [contratId])
          .timeout(
            const Duration(seconds: 40),
            onTimeout: () {
              logger.e('Timeout loading factures for contrat $contratId');
              throw TimeoutException('Database query timeout');
            },
          );
      final factures = rows.map((row) => Facture.fromMap(row)).toList();
      logger.i(' ${factures.length} factures chargées pour contrat $contratId');
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
      final rows = await _db
          .query(SqlQueries.getFacturesByClientDetailed, [clientId])
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              logger.e('Timeout loading factures for client $clientId');
              throw TimeoutException('Database query timeout');
            },
          );
      _factures = rows.map((row) => Facture.fromMap(row)).toList();

      logger.i(
        ' ${_factures.length} factures chargées pour le client $clientId avec tous détails',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur lors du chargement des factures: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère les factures associées à un planning_detail_id
  Future<List<Facture>> getFacturesByPlanningDetail(
    int planningDetailId, {
    bool useCache = true,
  }) async {
    try {
      final rows = await _db
          .query(SqlQueries.getFacturesByPlanningDetail, [planningDetailId], useCache)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e(
                'Timeout loading factures for planning_detail_id $planningDetailId',
              );
              throw TimeoutException('Database query timeout');
            },
          );
      final factures = rows.map((row) => Facture.fromMap(row)).toList();

      logger.i(
        ' ${factures.length} factures trouvées pour planning_detail_id $planningDetailId',
      );
      return factures;
    } catch (e) {
      logger.e(' Erreur lors du chargement des factures: $e');
      return [];
    }
  }

  /// Récupère l'historique des changements de prix d'une facture
  Future<List<Map<String, dynamic>>> getPriceHistory(int factureId) async {
    try {
      final rows = await _db
          .query(SqlQueries.getPriceHistory, [factureId])
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () {
              logger.e(
                'Timeout loading price history for facture_id $factureId',
              );
              throw TimeoutException('Database query timeout');
            },
          );
      logger.i(
        ' ${rows.length} changements de prix trouvés pour facture_id $factureId',
      );
      return rows;
    } catch (e) {
      logger.e(' Erreur lors du chargement de l\'historique des prix: $e');
      return [];
    }
  }

  /// Met à jour le prix d'une facture et recharge les données
  /// (La somme totale se mettra à jour automatiquement grâce à notifyListeners())
  /// SÉCURITÉ: Vérifie que l'utilisateur est administrateur
  Future<bool> updateFacturePrice(int factureId, int newPrice, {required bool isAdmin}) async {
    if (!isAdmin) {
      _errorMessage = 'Droits administrateur requis pour modifier un montant';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.execute(SqlQueries.updateFacturePrice, [newPrice, factureId]);

      // Mettre à jour dans la liste locale
      final index = _factures.indexWhere((f) => f.factureId == factureId);
      if (index != -1) {
        _factures[index] = _factures[index].copyWith(montant: newPrice);
      }

      logger.i(' Facture $factureId mise à jour: montant=$newPrice Ar');

      // Notifier les listeners pour mettre à jour la somme totale dans l'UI
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur lors de la mise à jour: $e');
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
      await _db.execute(SqlQueries.markFactureAsPaid, ['Payée', factureId]);

      // Mettre à jour dans la liste
      final index = _factures.indexWhere((f) => f.factureId == factureId);
      if (index != -1) {
        _factures[index] = _factures[index].copyWith(etat: 'Payée');
      }

      logger.i(' Facture $factureId marquée comme payée');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur lors du marquage: $e');
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
      // Envoyer null à la BD si vide, sinon la nouvelle valeur
      final refValue = newReference.isEmpty ? null : newReference;
      await _db.execute(SqlQueries.updateFactureReference, [refValue, factureId]);

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

      logger.i(' Référence facture $factureId mise à jour: $newReference');

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur lors de la mise à jour de la référence: $e');
      return false;
    }
  }

  /// Met à jour le montant d'une facture et applique la différence aux factures postérieures
  /// du même traitement. Crée aussi des entrées dans l'historique.
  /// SÉCURITÉ: Vérifie que l'utilisateur est administrateur
  Future<bool> majMontantEtHistorique(
    int factureId,
    int oldMontant,
    int newMontant, {
    required bool isAdmin,
  }) async {
    if (!isAdmin) {
      _errorMessage = 'Droits administrateur requis pour cette opération';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Étape 1: Récupérer la facture et sa date
      final factureRows = await _db.queryOne(SqlQueries.getFactureAndTreatmentInfo, params: [factureId]);
      if (factureRows == null) {
        throw Exception('Facture non trouvée');
      }

      final dateTraitement = factureRows['date_traitement'];
      final traitementId = factureRows['traitement_id'];

      if (dateTraitement == null || traitementId == null) {
        throw Exception('Données incomplètes pour la facture');
      }

      // Étape 2: Calculer la différence
      final prixDiff = newMontant - oldMontant;
      logger.i(
        ' Différence de prix: $prixDiff Ar (ancien: $oldMontant, nouveau: $newMontant)',
      );

      // Étape 3: Mouvements en base de données via une TRANSACTION
      await _db.transaction<void>((conn) async {
        // A. Mise à jour massive des prix (Performant)
        await conn.query(SqlQueries.massUpdateFutureFacturePrices, [
          prixDiff,
          traitementId,
          dateTraitement,
        ]);

        // B. Création de l'historique (On récupère les factures impactées pour les logs historiques)
        final otherFactures = await conn.query(SqlQueries.getOtherFacturesByTreatmentFromDate, [
          traitementId,
          dateTraitement,
        ]);

        final now = DateTime.now().toIso8601String();
        for (final row in otherFactures) {
          final fId = row['facture_id'] as int;
          final mAncien = row['montant'] as int;
          final mNouveau = mAncien + prixDiff;
          
          await conn.query(SqlQueries.createPriceHistoryEntry, [
            fId,
            mAncien,
            mNouveau,
            now,
          ]);
        }
      });

      // Étape 4: Mise à jour de la liste locale en mémoire (Instantané pour l'UI)
      final dtRef = DateTime.parse(dateTraitement.toString());
      
      for (int i = 0; i < _factures.length; i++) {
        final f = _factures[i];
        
        // On ne filtre QUE sur le même traitement et les dates postérieures
        if (f.traitementId == traitementId && 
            f.dateTraitement.compareTo(dtRef) >= 0 &&
            !f.isPaid) {
          
          _factures[i] = f.copyWith(montant: f.montant + prixDiff);
        }
      }

      logger.i(' Mise à jour locale terminée pour traitement $traitementId');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur lors de majMontantEtHistorique: $e');
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
      final id = await _db.insert(SqlQueries.createFacture, [
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
  /// Sécurise l'axe en le récupérant automatiquement si absent
  Future<int> createFactureComplete({
    required int planningDetailId,
    required String referenceFacture,
    required int montant,
    String? mode,
    required String etat,
    String? axe,
    required DateTime dateTraitement,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Vérifier si une facture existe déjà
      final existing =
          await _db.query(SqlQueries.checkFactureExistence, [planningDetailId]);

      if (existing.isNotEmpty) {
        logger.i(
          ' Facture existe déjà pour planning_detail_id=$planningDetailId',
        );
        return existing[0]['facture_id'] as int;
      }

      // 2. SÉCURISATION DE L'AXE: Si l'axe est absent, on le récupère du client
      String finalAxe = axe ?? 'Centre (C)';
      if (axe == null || axe.isEmpty || axe == 'Non défini') {
        try {
          final axeResult = await _db
              .queryOne(SqlQueries.getClientIdFromPlanningDetail, params: [planningDetailId]);
          if (axeResult != null) {
            // Note: getClientIdFromPlanningDetail ne renvoie que client_id.
            // On va utiliser une requête plus complète ou enchaîner.
            final clientInfo = await _db
                .queryOne(SqlQueries.getClientById, params: [axeResult['client_id']]);
            if (clientInfo != null && clientInfo['axe'] != null) {
              finalAxe = clientInfo['axe'] as String;
              logger.i(' Axe récupéré automatiquement du client: $finalAxe');
            }
          }
        } catch (e) {
          logger.w(' Impossible de récupérer l\'axe auto, utilisation du défaut: $e');
        }
      }

      // 3. Insertion
      final id = await _db.insert(SqlQueries.createFactureComplete, [
        planningDetailId,
        referenceFacture.isEmpty ? null : referenceFacture,
        montant,
        mode,
        dateTraitement.toIso8601String().split('T')[0],
        etat,
        finalAxe,
      ]);

      logger.i(' Facture créée ID: $id avec axe: $finalAxe');
      return id;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur lors de la création facture: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime une facture
  /// SÉCURITÉ: Vérifie que l'utilisateur est administrateur
  Future<bool> deleteFacture(int factureId, {required bool isAdmin}) async {
    if (!isAdmin) {
      _errorMessage = 'Droits administrateur requis pour supprimer une facture';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.execute(SqlQueries.deleteFacture, [factureId]);

      _factures.removeWhere((f) => f.factureId == factureId);

      logger.i('Facture $factureId supprimée');
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
      final rows = await _db.query(SqlQueries.getAllFacturesDetailed, [clientId]); // NOTE: This SQL in FactureRepository uses a different query than the one in SqlQueries for generateExcelExport. I should update SqlQueries to include the specific one or use a more generic one.

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

  ///  REPAIR FUNCTION: Régénère les factures pour un contrat
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

  ///  REPAIR FUNCTION: Régénère les factures pour un traitement spécifique
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
      logger.i(' REPAIR: Planning + Factures pour traitement $traitementId');
      
      // On regroupe tout dans une seule transaction pour éviter les données partielles
      return await _db.transaction((conn) async {
        // 1. Récupérer l'axe et le Planning
        final axeRes = await conn.query(SqlQueries.getClientAxeByTreatment, [traitementId]);
        if (axeRes.isEmpty) throw Exception('Traitement non trouvé');
        final axe = axeRes.first['axe'] as String;

        final planRes = await conn.query(SqlQueries.getPlanningByTreatment, [traitementId]);
        if (planRes.isEmpty) throw Exception('Planning non trouvé');
        final pRow = planRes.first;

        final planningId = pRow['planning_id'] as int;
        final dureeTraitement = pRow['duree_traitement'] as int;
        final redondance = pRow['redondance'] as int;

        // 2. Créer les PlanningDetails manquants
        final countRes = await conn.query(SqlQueries.countPlanningDetails, [planningId]);
        final existingCount = (countRes.first['count'] as int?) ?? 0;

        int planningDetailsCreated = 0;
        if (existingCount == 0) {
          final dateDebut = DateTime.parse(pRow['date_debut_planification'] as String);
          final planningDates = _generatePlanningDates(
            dateDebut: dateDebut,
            dureeTraitement: dureeTraitement,
            redondance: redondance,
          );

          for (final date in planningDates) {
            await conn.query(SqlQueries.insertPlanningDetail, [planningId, date.toIso8601String()]);
            planningDetailsCreated++;
          }
        }

        // 3. Créer les factures
        final pdRows = await conn.query(SqlQueries.getPlanningDetailsByPlanningIdOrdered, [planningId]);
        int facturesCreated = 0;
        int sequenceNumber = 1;

        for (final pd in pdRows) {
          final pdId = pd['planning_detail_id'] as int;
          final dateStr = pd['date_planification'] as String;

          final checkFac = await conn.query(SqlQueries.checkFactureExistence, [pdId]);
          if (checkFac.isNotEmpty && !deleteExisting) continue;

          final ref = '$referencePrefix-$sequenceNumber';
          await conn.query(SqlQueries.createFactureComplete, [
            pdId,
            ref,
            montant,
            null,
            dateStr,
            'À venir',
            axe,
          ]);

          facturesCreated++;
          sequenceNumber++;
        }

        logger.i('TRANSACTION REUSSIE: $planningDetailsCreated PD + $facturesCreated factures');
        return facturesCreated;
      });
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      logger.e(' $e');
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ///  Génère les dates de planning (utilise date_utils pour cohérence)
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
