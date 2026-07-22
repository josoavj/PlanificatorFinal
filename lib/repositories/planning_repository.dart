import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/index.dart';
import '../core/sql_queries.dart';

class PlanningRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'planning_repository');

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> savePlanningComplete({
    required int traitementId,
    required DateTime debut,
    required int moisDebut,
    required int? moisFin,
    required int redondance, // 0='une seule fois', 1='1 mois', 2='2 mois', etc.
    required DateTime dateFinContrat,
    required List<DateTime>
    planningDates, // Dates générées par planning_per_year
    required double montant,
    required String axeClient,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utilisation d'une TRANSACTION pour garantir l'atomicité
      return await _db.transaction((conn) async {
        // 1. Créer le planning dans la BD
        final planning = await conn.query(SqlQueries.createPlanning, [
          traitementId,
          debut.toIso8601String().split('T')[0],
          moisDebut,
          moisFin ?? 0,
          12,
          redondance,
          dateFinContrat.toIso8601String().split('T')[0],
        ]);

        if (planning.isEmpty) {
          throw Exception('Erreur création planning');
        }

        int planningId = planning.first['planning_id'] ?? 0;
        if (planningId == 0) throw Exception('Planning ID non défini');

        logger.i(' Planning créé: ID $planningId');

        // 2. Créer planning_details pour chaque date
        int facturesCreated = 0;

        for (final planningDate in planningDates) {
          // Créer planning_detail
          final details = await conn.query(SqlQueries.insertPlanningDetailWithStatut, [
            planningId,
            planningDate.toIso8601String().split('T')[0],
            'À venir',
          ]);

          int detailId = details.first['planning_detail_id'] ?? 0;
          if (detailId == 0) {
            logger.w(' Impossible de créer planning_detail pour $planningDate');
            continue;
          }

          // 3. Créer facture pour chaque détail
          await conn.query(SqlQueries.createFacture, [
            detailId,
            montant.toInt(),
            planningDate.toIso8601String().split('T')[0],
            'Non payé',
            axeClient,
          ]);

          facturesCreated++;
        }

        logger.i(' Planning complet créé avec succès: $facturesCreated factures');
        return true;
      });
    } catch (e) {
      _errorMessage = e.toString();
      logger.e(' Erreur savePlanningComplete: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer un planning pour un traitement
  Future<int> createPlanning({
    required int traitementId,
    required DateTime dateDebutPlanification,
    required int moisDebut,
    required int dureeTraitement,
    required int redondance,
  }) async {
    try {
      final existing = await _db.query(SqlQueries.checkPlanningExistence, [traitementId]);

      if (existing.isNotEmpty) {
        logger.i(
          ' Planning existe déjà pour traitement_id=$traitementId, ID=${existing[0]['planning_id']}',
        );
        return existing[0]['planning_id'] as int;
      }

      final month = dateDebutPlanification.month - 1 + (dureeTraitement - 1);
      final year = dateDebutPlanification.year + (month ~/ 12);
      final newMonth = (month % 12) + 1;
      final daysInMonth = DateTime(year, newMonth + 1, 0).day;
      final day = dateDebutPlanification.day > daysInMonth
          ? daysInMonth
          : dateDebutPlanification.day;
      final dateFinPlanification = DateTime(year, newMonth, day);

      final planningId = await _db.insert(SqlQueries.createPlanning, [
        traitementId,
        dateDebutPlanification.toIso8601String().split('T')[0],
        moisDebut,
        moisDebut + dureeTraitement - 1, // moisFin
        dureeTraitement,
        redondance,
        dateFinPlanification.toIso8601String().split('T')[0],
      ]);

      logger.i(' Planning créé: ID $planningId pour traitement $traitementId');
      return planningId;
    } catch (e) {
      logger.e(' Erreur création planning: $e');
      return -1;
    }
  }

  static int extractRedondanceFromFrequency(String frequence) {
    if (frequence.toLowerCase() == 'une seule fois') {
      return 0;
    }
    try {
      final parts = frequence.split(' ');
      if (parts.isNotEmpty) {
        return int.parse(parts[0]);
      }
    } catch (e) {
      Logger().e(' Erreur parsing frequency: $e');
    }
    return 1; // Défaut: 1 mois
  }

  static int cleanMontant(String montantStr) {
    return int.parse(montantStr.replaceAll(' ', '').replaceAll('Ar', ''));
  }
}
