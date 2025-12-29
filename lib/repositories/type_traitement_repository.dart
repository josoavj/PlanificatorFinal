import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class TypeTraitementRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = Logger();

  List<TypeTraitement> _traitements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TypeTraitement> get traitements => _traitements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge tous les types de traitement
  Future<void> loadAllTraitements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const sql = '''
        SELECT 
          id_type_traitement, categorieTraitement, typeTraitement
        FROM TypeTraitement
        ORDER BY typeTraitement ASC
      ''';

      final rows = await _db.query(sql);
      _traitements = rows.map((row) => TypeTraitement.fromJson(row)).toList();

      logger.i('${_traitements.length} types de traitement chargés');
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des types de traitement: $e');
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
