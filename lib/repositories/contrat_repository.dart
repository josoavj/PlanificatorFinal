import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../core/sql_queries.dart';
import '../utils/date_utils.dart' as date_utils;

class ContratRepository extends ChangeNotifier {
  final DatabaseService _db;
  final logger = createLoggerWithFileOutput(name: 'contrat_repository');

  List<Contrat> _contrats = [];
  Contrat? _currentContrat;
  bool _isLoading = false;
  String? _errorMessage;

  // Constructeur avec injection optionnelle
  ContratRepository({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService();

  // Pagination
  static const int paginationSize = 30;
  int _currentPage = 0;
  bool _hasMoreContrats = true;

  List<Contrat> get contrats => _contrats;
  Contrat? get currentContrat => _currentContrat;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMoreContrats => _hasMoreContrats;

  /// Charge les contrats par page (pagination)
  Future<void> loadContratsPage(int page) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = page * paginationSize;

      final rows = await _db
          .query(SqlQueries.getContratsPaginated, [paginationSize, offset])
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              logger.e('Timeout loading contrats page $page');
              throw TimeoutException('Database query timeout');
            },
          );
      final pageContrats = rows.map((row) => Contrat.fromMap(row)).toList();

      if (page == 0) {
        _contrats = pageContrats;
      } else {
        _contrats.addAll(pageContrats);
      }

      _hasMoreContrats = pageContrats.length == paginationSize;
      _currentPage = page;

      logger.i(
        'Page $page: ${pageContrats.length} contrats chargés (total: ${_contrats.length})',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur pagination contrats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge la page suivante
  Future<void> loadNextPage() async {
    await loadContratsPage(_currentPage + 1);
  }

  /// Charge tous les contrats (wrapper pour compatibilité)
  Future<void> loadContrats() async {
    await loadContratsPage(0);
  }

  /// Charge un contrat spécifique
  Future<void> loadContrat(int contratId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final row = await _db
          .queryOne(SqlQueries.getContratById, [contratId])
          .timeout(
            const Duration(seconds: 25),
            onTimeout: () {
              logger.e('Timeout loading contrat $contratId');
              throw TimeoutException('Database query timeout');
            },
          );
      if (row != null) {
        _currentContrat = Contrat.fromMap(row);
        logger.i('Contrat $contratId chargé');
      } else {
        _errorMessage = 'Contrat non trouvé';
      }
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement du contrat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crée un nouveau contrat
  Future<int> createContrat({
    required int clientId,
    required String referenceContrat,
    required DateTime dateContrat,
    required DateTime dateDebut,
    DateTime? dateFin,
    required String statutContrat,
    int? duree,
    required String categorie,
    required String dureeStatus,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Calculer la durée du contrat en mois si dateFin est défini
      int? dureeContrat;
      if (dateFin != null) {
        dureeContrat =
            dateFin.month -
            dateDebut.month +
            12 * (dateFin.year - dateDebut.year);
      }

      final id = await _db.insert(SqlQueries.createContrat, [
        clientId,
        referenceContrat,
        dateContrat.toIso8601String(),
        dateDebut.toIso8601String(),
        dateFin?.toIso8601String(),
        statutContrat,
        dureeContrat,
        dureeStatus,
        categorie,
      ]);

      // Ajouter le nouveau contrat à la liste
      final newContrat = Contrat(
        contratId: id,
        clientId: clientId,
        referenceContrat: referenceContrat,
        dateContrat: dateContrat,
        dateDebut: dateDebut,
        dateFin: dateFin,
        statutContrat: statutContrat,
        dureeContrat: dureeContrat ?? 0,
        dureeType: dureeStatus,
        categorie: categorie,
      );
      _contrats.add(newContrat);

      logger.i('Contrat créé avec l\'ID: $id');
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

  /// Sauvegarde complète d'un contrat (Client, Contrat, Traitements, Plannings, Factures)
  /// dans une seule TRANSACTION SQL pour garantir l'intégrité des données.
  /// SÉCURITÉ: Atomique (Tout ou rien)
  /// PERFORMANCE: Optimisé pour Desktop (requêtes groupées)
  Future<bool> saveFullContratTransaction({
    required Client client,
    required String referenceContrat,
    required DateTime dateContrat,
    required DateTime dateDebut,
    DateTime? dateFin,
    required String statutContrat,
    required int duree,
    required String categorieContrat,
    required String dureeStatus,
    required List<int> selectedTreatmentIds,
    required Map<int, Map<String, dynamic>> treatmentConfigs,
    bool groupInvoicesByDate = false, // Nouveau : option de regroupement
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _db.transaction((conn) async {
        // 1. CRÉER LE CLIENT
        final clientResults = await conn.query(SqlQueries.createClient, [
          client.nom,
          client.prenom,
          client.email,
          client.telephone,
          client.adresse,
          client.categorie,
          client.nif,
          client.stat,
          client.axe,
          DateTime.now().toIso8601String().split('T')[0],
        ]);
        final clientId = clientResults.insertId ?? 0;
        logger.i('Transaction: Client créé ID $clientId');

        // 2. CRÉER LE CONTRAT
        int? dureeContrat;
        if (dateFin != null) {
          dureeContrat = dateFin.month - dateDebut.month + 12 * (dateFin.year - dateDebut.year);
        }

        final contratResults = await conn.query(SqlQueries.createContrat, [
          clientId,
          referenceContrat,
          dateContrat.toIso8601String(),
          dateDebut.toIso8601String(),
          dateFin?.toIso8601String(),
          statutContrat,
          dureeContrat,
          dureeStatus,
          categorieContrat,
        ]);
        final contratId = contratResults.insertId ?? 0;
        logger.i('Transaction: Contrat créé ID $contratId');

        // 3. COLLECTER TOUTES LES DATES DE PLANNING POUR TOUS LES SERVICES
        // Structure : { '2026-08-01': [ {tId: 1, montant: 50000}, {tId: 2, montant: 30000} ] }
        final Map<String, List<Map<String, dynamic>>> groupedPassages = {};

        for (final tId in selectedTreatmentIds) {
          final config = treatmentConfigs[tId] ?? {};
          final int redondance = config['redondance'] ?? 1;
          final String debutStr = config['debut'] ?? DateFormat('dd/MM/yyyy').format(dateDebut);
          final treatmentStartDate = DateFormat('dd/MM/yyyy').parse(debutStr);
          final int montant = int.tryParse(config['montant'].toString().replaceAll(' ', '')) ?? 0;

          final dates = date_utils.DateUtils.generatePlanningDates(
            dateDebut: treatmentStartDate, 
            dureeTraitement: duree, 
            redondance: redondance,
          );

          for (final d in dates) {
            final dateStr = d.toIso8601String().split('T')[0];
            groupedPassages.putIfAbsent(dateStr, () => []).add({
              'treatmentId': tId,
              'montant': montant,
            });
          }
        }

        // 4. CRÉER LES TRAITEMENTS ET PLANNINGS POUR CHAQUE SERVICE
        final Map<int, int> planningIdsByTreatment = {};
        for (final tId in selectedTreatmentIds) {
          final config = treatmentConfigs[tId] ?? {};
          
          final traitResults = await conn.query(SqlQueries.createTraitement, [contratId, tId]);
          final traitId = traitResults.insertId ?? 0;
          
          final String debutStr = config['debut'] ?? DateFormat('dd/MM/yyyy').format(dateDebut);
          final treatmentStartDate = DateFormat('dd/MM/yyyy').parse(debutStr);
          
          final endMonth = treatmentStartDate.month - 1 + (duree - 1);
          final endYear = treatmentStartDate.year + (endMonth ~/ 12);
          final endNewMonth = (endMonth % 12) + 1;
          final daysInMonth = DateTime(endYear, endNewMonth + 1, 0).day;
          final day = treatmentStartDate.day > daysInMonth ? treatmentStartDate.day : treatmentStartDate.day;
          final dateFinPlanification = DateTime(endYear, endNewMonth, day);

          final planResults = await conn.query(SqlQueries.createPlanning, [
            traitId,
            treatmentStartDate.toIso8601String().split('T')[0],
            treatmentStartDate.month,
            treatmentStartDate.month + duree - 1,
            duree,
            config['redondance'] ?? 1,
            dateFinPlanification.toIso8601String().split('T')[0],
          ]);
          
          planningIdsByTreatment[tId] = planResults.insertId ?? 0;
        }

        // 5. CRÉER LES PASSAGES ET LES FACTURES (GROUPÉES OU NON)
        for (final entry in groupedPassages.entries) {
          final String dateStr = entry.key;
          final List<Map<String, dynamic>> services = entry.value;

          if (groupInvoicesByDate) {
            // MODE GROUPÉ : Une seule facture pour tous les services de ce jour
            final int totalMontant = services.fold(0, (sum, s) => sum + (s['montant'] as int));
            
            final factResults = await conn.query(SqlQueries.createFactureComplete, [
              null, // planning_detail_id
              null, // reference
              totalMontant,
              null, // mode
              dateStr,
              'À venir',
              client.axe,
            ]);
            final factureId = factResults.insertId ?? 0;

            for (final s in services) {
              await conn.query(SqlQueries.insertPlanningDetailWithStatut, [
                planningIdsByTreatment[s['treatmentId']],
                dateStr,
                'À venir',
                factureId,
              ]);
            }
          } else {
            // MODE CLASSIQUE : Une facture par service
            for (final s in services) {
              final factResults = await conn.query(SqlQueries.createFactureComplete, [
                null,
                null,
                s['montant'],
                null,
                dateStr,
                'À venir',
                client.axe,
              ]);
              final fId = factResults.insertId ?? 0;

              await conn.query(SqlQueries.insertPlanningDetailWithStatut, [
                planningIdsByTreatment[s['treatmentId']],
                dateStr,
                'À venir',
                fId,
              ]);
            }
          }
        }

        return true;
      });
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('ERREUR Transaction Contrat: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour un contrat
  Future<void> updateContrat(Contrat contrat) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Calculer la durée du contrat en mois si dateFin est défini
      int? dureeContrat;
      if (contrat.dateFin != null) {
        dureeContrat =
            contrat.dateFin!.month -
            contrat.dateDebut.month +
            12 * (contrat.dateFin!.year - contrat.dateDebut.year);
      }

      await _db.execute(SqlQueries.updateContrat, [
        contrat.clientId,
        contrat.referenceContrat,
        contrat.dateContrat.toIso8601String(),
        contrat.dateDebut.toIso8601String(),
        contrat.dateFin?.toIso8601String(),
        contrat.statutContrat,
        dureeContrat,
        contrat.dureeType,
        contrat.categorie,
        contrat.contratId,
      ]);

      // Mettre à jour dans la liste
      final index = _contrats.indexWhere(
        (c) => c.contratId == contrat.contratId,
      );
      if (index != -1) {
        _contrats[index] = contrat;
      }

      if (_currentContrat?.contratId == contrat.contratId) {
        _currentContrat = contrat;
      }

      logger.i('Contrat ${contrat.contratId} mis à jour');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la mise à jour: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime un contrat
  /// SÉCURITÉ: Vérifie que l'utilisateur est administrateur
  Future<bool> deleteContrat(int contratId, {required bool isAdmin}) async {
    if (!isAdmin) {
      _errorMessage = 'Droits administrateur requis pour supprimer un contrat';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.execute(SqlQueries.deleteContrat, [contratId]);

      _contrats.removeWhere((c) => c.contratId == contratId);

      if (_currentContrat?.contratId == contratId) {
        _currentContrat = null;
      }

      logger.i('Contrat $contratId supprimé');
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

  /// Récupère les contrats actifs
  List<Contrat> getActiveContrats() {
    final now = DateTime.now();
    return _contrats
        .where(
          (c) =>
              c.dateDebut.isBefore(now) &&
              (c.dateFin == null || c.dateFin!.isAfter(now)),
        )
        .toList();
  }

  /// Récupère la durée en mois d'un contrat
  int getContractDurationInMonths(Contrat contrat) {
    if (contrat.dateFin == null) {
      return 0; // Contrat indéterminé
    }
    return contrat.dateFin!.month -
        contrat.dateDebut.month +
        12 * (contrat.dateFin!.year - contrat.dateDebut.year);
  }

  /// Recherche des contrats
  Future<void> searchContrats(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchTerm = '%$query%';
      final rows = await _db.query(SqlQueries.searchContrats, [searchTerm, searchTerm]);
      _contrats = rows.map((row) => Contrat.fromMap(row)).toList();

      logger.i(
        '${_contrats.length} contrats trouvés pour la recherche: $query',
      );
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la recherche: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Créer un enregistrement Traitement dans la base de données
  /// Retourne l'ID du traitement créé, ou -1 en cas d' erreur
  Future<int> createTraitement({
    required int contratId,
    required int typeTraitementId,
  }) async {
    try {
      final id = await _db.insert(SqlQueries.createTraitement, [contratId, typeTraitementId]);

      logger.i('Traitement créé avec l\'ID: $id pour contrat $contratId');
      return id;
    } catch (e) {
      logger.e('Erreur lors de la création du traitement: $e');
      return -1;
    }
  }

  /// Abroge/résilie un contrat et marque tous les plannings futurs comme 'Classé sans suite'
  /// Retourne true si l'abrogation s'est bien passée
  /// SÉCURITÉ: Vérifie que l'utilisateur est administrateur
  Future<bool> abrogateContract({
    required int contratId,
    required DateTime abrogationDate,
    String? motif,
    required bool isAdmin,
  }) async {
    if (!isAdmin) {
      _errorMessage = 'Droits administrateur requis pour résilier un contrat';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Mettre à jour le contrat avec la date d'abrogation
      await _db.execute(SqlQueries.abrogateContrat, [
        abrogationDate.toString().split(' ')[0], // Format YYYY-MM-DD
        motif,
        abrogationDate.toString().split(' ')[0], // Mettre à jour date_fin
        contratId,
      ]);

      logger.i('Contrat $contratId marqué comme Résilié à $abrogationDate');

      // 2. Trouver tous les traitements du contrat
      final treatments = await _db.query(SqlQueries.getTreatmentsByContrat, [contratId]);

      // 3. Pour chaque traitement, marquer les plannings futurs comme 'Classé sans suite'
      for (final treatment in treatments) {
        final treatmentId = treatment['traitement_id'];

        // Récupérer tous les plannings futurs pour ce traitement
        final plannings = await _db.query(SqlQueries.getFuturePlanningsByTreatment, [
          treatmentId,
          abrogationDate.toString().split(' ')[0],
        ]);

        // Supprimer chaque planning et ses détails futurs
        for (final planning in plannings) {
          final planningId = planning['planning_id'];

          await _db.execute(SqlQueries.deleteFuturePlanningDetailsByPlanning, [planningId]);

          logger.i(
            'Détails futurs du planning $planningId supprimés pour traitement $treatmentId',
          );
        }
      }

      // 4. Mettre à jour la liste locale et l'affichage
      if (_currentContrat?.contratId == contratId) {
        _currentContrat = _currentContrat?.copyWith(
          statutContrat: 'Résilié',
          dateFin: abrogationDate,
        );
      }

      _contrats = _contrats.map((c) {
        if (c.contratId == contratId) {
          return c.copyWith(statutContrat: 'Résilié', dateFin: abrogationDate);
        }
        return c;
      }).toList();

      logger.i('Abrogation du contrat $contratId complétée avec succès');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de l\'abrogation du contrat: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
