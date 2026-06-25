import 'dart:async';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../core/sql_queries.dart';

class ContratRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'contrat_repository');

  List<Contrat> _contrats = [];
  Contrat? _currentContrat;
  bool _isLoading = false;
  String? _errorMessage;

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
  Future<void> deleteContrat(int contratId) async {
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
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors de la suppression: $e');
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
  /// Retourne l'ID du traitement créé, ou -1 en cas d'erreur
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
  Future<bool> abrogateContract({
    required int contratId,
    required DateTime abrogationDate,
    String? motif,
  }) async {
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
