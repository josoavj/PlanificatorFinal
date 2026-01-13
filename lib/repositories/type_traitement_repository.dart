import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../services/logging_service.dart';

class TypeTraitementRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'type_traitement_repository');

  List<TypeTraitement> _traitements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TypeTraitement> get traitements => _traitements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialise la liste prédéfinie des traitements
  void _initializeTreatments() {
    _traitements = [
      TypeTraitement(id: 1, categorie: 'PC', type: 'Dératisation (PC)'),
      TypeTraitement(id: 2, categorie: 'PC', type: 'Désinfection (PC)'),
      TypeTraitement(id: 3, categorie: 'PC', type: 'Désinsectisation (PC)'),
      TypeTraitement(id: 4, categorie: 'PC', type: 'Fumigation (PC)'),
      TypeTraitement(id: 5, categorie: 'NI', type: 'Nettoyage industriel (NI)'),
      TypeTraitement(id: 6, categorie: 'AT', type: 'Anti termites (AT)'),
      TypeTraitement(id: 7, categorie: 'RO', type: 'Ramassage ordures (RO)'),
    ];
  }

  /// Charge les types de traitement depuis la base de données
  Future<void> loadAllTraitements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Charger depuis la BD
      final query = 'SELECT * FROM TypeTraitement ORDER BY id_type_traitement';
      final results = await _db.query(query);

      if (results.isEmpty) {
        // Si aucun résultat, initialiser la liste prédéfinie (fallback)
        logger.w(
          'Aucun type de traitement en BD, utilisation de la liste prédéfinie',
        );
        _initializeTreatments();
      } else {
        _traitements = results
            .map((row) => TypeTraitement.fromJson(row))
            .toList();
        logger.i(
          '${_traitements.length} types de traitement chargés depuis la BD',
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des types de traitement: $e');
      // Fallback: initialiser la liste prédéfinie en cas d'erreur
      _initializeTreatments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupère un type de traitement par son ID
  TypeTraitement? getTraitementById(int id) {
    try {
      return _traitements.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère le nom du traitement par son ID
  String getTraitementName(int id) {
    final traitement = getTraitementById(id);
    return traitement?.type ?? 'Traitement inconnu';
  }
}
