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

  /// Charge les contrats d'un client
  Future<void> loadContratsForClient(int clientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          contrat_id, client_id, reference_contrat, date_contrat, date_debut, date_fin, 
          statut_contrat, duree_contrat, duree, categorie
        FROM Contrat
        WHERE client_id = ?
        ORDER BY date_debut DESC
      ''';

      final rows = await _db.query(sql, [clientId]);
      _contrats = rows.map((row) => Contrat.fromMap(row)).toList();

      logger.i('${_contrats.length} contrats chargés pour le client $clientId');
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
    required DateTime dateFin,
    required String statutContrat,
    required int duree,
    required String categorie,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Calculer la durée du contrat en mois
      final dureeContrat =
          dateFin.month -
          dateDebut.month +
          12 * (dateFin.year - dateDebut.year);

      const sql = '''
        INSERT INTO Contrat (client_id, reference_contrat, date_contrat, date_debut, date_fin, statut_contrat, duree_contrat, duree, categorie)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''';

      final id = await _db.insert(sql, [
        clientId,
        referenceContrat,
        dateContrat.toIso8601String(),
        dateDebut.toIso8601String(),
        dateFin.toIso8601String(),
        statutContrat,
        dureeContrat,
        duree,
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
        dureeContrat: dureeContrat,
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
      // Calculer la durée du contrat en mois
      final dureeContrat =
          contrat.dateFin.month -
          contrat.dateDebut.month +
          12 * (contrat.dateFin.year - contrat.dateDebut.year);

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
        contrat.dateFin.toIso8601String(),
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
        .where((c) => c.dateDebut.isBefore(now) && c.dateFin.isAfter(now))
        .toList();
  }

  /// Récupère la durée en mois d'un contrat
  int getContractDurationInMonths(Contrat contrat) {
    return contrat.dateFin.month -
        contrat.dateDebut.month +
        12 * (contrat.dateFin.year - contrat.dateDebut.year);
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
}
