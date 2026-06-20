import 'dart:async';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/excel_utils.dart';
import '../utils/date_helper.dart';
import '../utils/date_utils.dart' as date_utils;
import '../core/sql_queries.dart';

class FactureRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'facture_repository');

  List<Facture> _factures = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Facture> get factures => _factures;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  /// Charge toutes les factures avec tous les détails jointes
  Future<void> loadAllFactures() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Requête optimisée: utilise INNER JOIN pour les liens critiques
      // et LEFT JOIN pour les données optionnelles
      final rows = await _db
          .query(SqlQueries.getAllFacturesDetailed)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              logger.e('Timeout loading all factures');
              throw TimeoutException('Database query timeout');
            },
          );
      _factures = rows.map((row) => Facture.fromMap(row)).toList();

      logger.i(' ${_factures.length} factures chargées avec tous détails');
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
    int planningDetailId,
  ) async {
    try {
      final rows = await _db
          .query(SqlQueries.getFacturesByPlanningDetail, [planningDetailId])
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
  Future<bool> updateFacturePrice(int factureId, int newPrice) async {
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
      final factureRows = await _db.query(SqlQueries.getFactureAndTreatmentInfo, [factureId]);
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
        ' Différence de prix: $prixDiff Ar (ancien: $oldMontant, nouveau: $newMontant)',
      );

      // Étape 3: Récupérer toutes les factures du même traitement avec date >= dateActuelle
      final otherFactures = await _db.query(SqlQueries.getOtherFacturesByTreatmentFromDate, [
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

        //  LOGIQUE: Si la facture est déjà payée, ne pas modifier le montant
        if (etat == 'Payé' || etat == 'Payée') {
          logger.i(' Facture $fId est payée, montant inchangé (état: $etat)');
          continue; // Passer à la prochaine facture
        }

        final nouveauMontant = ancienMontant + prixDiff;

        // Mettre à jour le montant
        await _db.execute(SqlQueries.updateFacturePrice, [nouveauMontant, fId]);

        // Créer une entrée historique
        await _db.execute(SqlQueries.createPriceHistoryEntry, [
          fId,
          ancienMontant,
          nouveauMontant,
          now.toIso8601String(),
        ]);

        logger.i(
          ' Facture $fId mise à jour: $ancienMontant → $nouveauMontant Ar',
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
          //  LOGIQUE: Ne pas modifier les factures payées
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
        ' $updatedCount facture(s) mises à jour avec la différence de $prixDiff Ar',
      );

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
  Future<int> createFactureComplete({
    required int planningDetailId,
    required String referenceFacture,
    required int montant,
    String? mode, //  Mode peut être null (à définir plus tard)
    required String etat,
    String? axe, //  Axe peut être null (à définir plus tard)
    required DateTime dateTraitement,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      //  Vérifier si une facture existe déjà pour ce planning detail
      final existing = await _db.query(SqlQueries.checkFactureExistence, [planningDetailId]);

      if (existing.isNotEmpty) {
        logger.i(
          ' Facture existe déjà pour planning_detail_id=$planningDetailId, ID=${existing[0]['facture_id']}',
        );
        return existing[0]['facture_id'] as int;
      }

      final id = await _db.insert(SqlQueries.createFactureComplete, [
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
      await _db.execute(SqlQueries.deleteFacture, [factureId]);

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
      logger.i('   💰 Montant: $montant Ar');
      logger.i('   📑 Référence: $referencePrefix');

      // 1. Récupérer l'axe et le Planning
      final axeResult = await _db.query(SqlQueries.getClientAxeByTreatment, [traitementId]);
      if (axeResult.isEmpty) throw Exception('Traitement non trouvé');
      final axe = axeResult[0]['axe'] as String;

      final planningResult = await _db.query(SqlQueries.getPlanningByTreatment, [traitementId]);
      if (planningResult.isEmpty) throw Exception('Planning non trouvé');

      final planningId = planningResult[0]['planning_id'] as int;
      final dureeTraitement = planningResult[0]['duree_traitement'] as int;
      final redondance = planningResult[0]['redondance'] as int;
      logger.i(
        '   📅 Planning: ID=$planningId, Durée=$dureeTraitement, Redondance=$redondance',
      );

      // 2. Créer les PlanningDetails manquants
      final countResult = await _db.query(SqlQueries.countPlanningDetails, [planningId]);
      final existingCount = (countResult[0]['count'] as int?) ?? 0;

      int planningDetailsCreated = 0;
      if (existingCount == 0) {
        final dateDebut = DateTime.parse(
          planningResult[0]['date_debut_planification'] as String,
        );
        logger.i('    Génération des dates...');

        final planningDates = _generatePlanningDates(
          dateDebut: dateDebut,
          dureeTraitement: dureeTraitement,
          redondance: redondance,
        );

        logger.i('    ${planningDates.length} dates générées');

        for (final date in planningDates) {
          try {
            await _db.execute(SqlQueries.insertPlanningDetail, [planningId, date.toIso8601String()]);
            planningDetailsCreated++;
            logger.i(
              '    PlanningDetail créé: ${date.toIso8601String()} (ID Planning=$planningId)',
            );
          } catch (e) {
            logger.e('    Erreur création PlanningDetail: $e');
          }
        }
        logger.i('   🎉 $planningDetailsCreated Planning Details créés');
      } else {
        logger.i('   ℹ️ $existingCount Planning Details existent déjà');
      }

      // 3. Créer les factures
      final planningDetails = await _db.query(SqlQueries.getPlanningDetailsByPlanningIdOrdered, [planningId]);
      logger.i('    Total Planning Details trouvés: ${planningDetails.length}');

      if (planningDetails.isEmpty) {
        logger.w('    Aucun PlanningDetail trouvé! Vérifiez la création.');
        return 0;
      }

      int facturesCreated = 0;
      int sequenceNumber = 1;

      for (final pd in planningDetails) {
        final pdId = pd['planning_detail_id'] as int;
        final dateStr = pd['date_planification'] as String;

        final existing = await _db.query(SqlQueries.checkFactureExistence, [pdId]);

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
          logger.i('    Facture créée: $ref (PD#$pdId)');
        }
        sequenceNumber++;
      }

      logger.i(
        '🎉 TERMINÉ: $planningDetailsCreated PD + $facturesCreated factures',
      );
      return facturesCreated;
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
