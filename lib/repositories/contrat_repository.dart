import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class ContratRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = Logger();

  List<Contrat> _contrats = [];
  Contrat? _currentContrat;
  bool _isLoading = false;
  String? _errorMessage;

  List<Contrat> get contrats => _contrats;
  Contrat? get currentContrat => _currentContrat;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge tous les contrats
  Future<void> loadContrats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          contrat_id, client_id, reference_contrat, date_contrat, date_debut, date_fin, 
          statut_contrat, duree_contrat, duree, categorie
        FROM Contrat
        ORDER BY date_debut DESC
      ''';

      final rows = await _db.query(sql);
      _contrats = rows.map((row) => Contrat.fromMap(row)).toList();

      logger.i('${_contrats.length} contrats chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des contrats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge un contrat spécifique
  Future<void> loadContrat(int contratId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          contrat_id, client_id, reference_contrat, date_contrat, date_debut, date_fin, 
          statut_contrat, duree_contrat, duree, categorie
        FROM Contrat
        WHERE contrat_id = ?
      ''';

      final row = await _db.queryOne(sql, [contratId]);
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

      const sql = '''
        INSERT INTO Contrat (client_id, reference_contrat, date_contrat, date_debut, date_fin, statut_contrat, duree_contrat, duree, categorie)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      final id = await _db.insert(sql, [
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
        duree: duree,
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

      const sql = '''
        UPDATE Contrat 
        SET client_id = ?, reference_contrat = ?, date_contrat = ?, date_debut = ?, date_fin = ?, statut_contrat = ?, duree_contrat = ?, duree = ?, categorie = ?
        WHERE contrat_id = ?
      ''';

      await _db.execute(sql, [
        contrat.clientId,
        contrat.referenceContrat,
        contrat.dateContrat.toIso8601String(),
        contrat.dateDebut.toIso8601String(),
        contrat.dateFin?.toIso8601String(),
        contrat.statutContrat,
        dureeContrat,
        contrat.duree,
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
      const sql = 'DELETE FROM Contrat WHERE contrat_id = ?';

      await _db.execute(sql, [contratId]);

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
      const sql = '''
        SELECT 
          c.contrat_id, c.client_id, c.reference_contrat, c.date_contrat, c.date_debut, c.date_fin, c.statut_contrat, c.duree_contrat, c.duree, c.categorie
        FROM Contrat c
        JOIN Client cli ON c.client_id = cli.client_id
        WHERE cli.nom LIKE ? OR cli.prenom LIKE ?
        ORDER BY c.date_debut DESC
      ''';

      final searchTerm = '%$query%';
      final rows = await _db.query(sql, [searchTerm, searchTerm]);
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
      const sql = '''
        INSERT INTO Traitement (contrat_id, id_type_traitement)
        VALUES (?, ?)
      ''';

      final id = await _db.insert(sql, [contratId, typeTraitementId]);

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
      final updateContratSql = '''
        UPDATE Contrat 
        SET statut_contrat = 'Résilié', 
            date_abrogation = ?, 
            motif_abrogation = ?,
            date_fin = ?
        WHERE contrat_id = ?
      ''';

      await _db.execute(updateContratSql, [
        abrogationDate.toString().split(' ')[0], // Format YYYY-MM-DD
        motif,
        abrogationDate.toString().split(' ')[0], // Mettre à jour date_fin
        contratId,
      ]);

      logger.i('Contrat $contratId marqué comme Résilié à $abrogationDate');

      // 2. Trouver tous les traitements du contrat
      final treatementsSql = '''
        SELECT traitement_id FROM Traitement WHERE contrat_id = ?
      ''';
      final treatments = await _db.query(treatementsSql, [contratId]);

      // 3. Pour chaque traitement, marquer les plannings futurs comme 'Classé sans suite'
      for (final treatment in treatments) {
        final treatmentId = treatment['traitement_id'];

        // Récupérer tous les plannings futurs pour ce traitement
        final planningsSql = '''
          SELECT planning_id FROM Planning WHERE traitement_id = ? AND date_debut_planification > ?
        ''';
        final plannings = await _db.query(planningsSql, [
          treatmentId,
          abrogationDate.toString().split(' ')[0],
        ]);

        // Marquer chaque planning et ses détails comme 'Classé sans suite'
        for (final planning in plannings) {
          final planningId = planning['planning_id'];

          final updatePlanningDetailsSql = '''
            UPDATE PlanningDetails 
            SET statut = 'Classé sans suite'
            WHERE planning_id = ?
          ''';

          await _db.execute(updatePlanningDetailsSql, [planningId]);

          logger.i(
            'Planning $planningId marqué comme Classé sans suite pour traitement $treatmentId',
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
