import 'package:flutter/material.dart';
import 'package:planificator/core/database/database_service.dart';
import 'package:planificator/core/logging/logging_service.dart';
import 'package:planificator/features/catalogue/models/type_traitement.dart';
import 'package:planificator/features/catalogue/models/type_traitement_category.dart';
import '../../../../../core/database/sql/sql_queries.dart';

class TypeTraitementRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'type_traitement_repository');

  List<TypeTraitement> _traitements = [];
  List<TypeTraitementCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TypeTraitement> get traitements => _traitements;
  List<TypeTraitementCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge les types de traitement depuis la base de données
  Future<void> loadAllTraitements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Charger depuis la BD
      final results = await _db.query(SqlQueries.getAllTypeTraitements);

      if (results.isEmpty) {
        logger.w('Aucun type de traitement visible dans la base de données');
        _traitements = [];
      } else {
        _traitements = results
            .map((row) => TypeTraitement.fromJson(row))
            .toList();
        logger.i(
          '${_traitements.length} types de traitement chargés depuis la BD',
        );
      }

      await loadCategories();
    } catch (e) {
      _errorMessage = e.toString();
      logger.e('Erreur lors du chargement des types de traitement: $e');
      _traitements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    final results = await _db.query(SqlQueries.getAllTraitementCategories);
    _categories = results
        .map(TypeTraitementCategory.fromJson)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> createCategory(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Le nom de la catégorie est obligatoire.');
    }

    await _db.execute(SqlQueries.createTraitementCategory, [normalized]);
    await loadCategories();
  }

  Future<void> loadCatalogForAdmin() async {
    final results = await _db.query(
      SqlQueries.getAllTypeTraitementsForAdmin,
      null,
      false,
    );
    final categories = await _db.query(
      SqlQueries.getAllTraitementCategoriesForAdmin,
      null,
      false,
    );
    _traitements = results.map(TypeTraitement.fromJson).toList();
    _categories = categories
        .map(TypeTraitementCategory.fromJson)
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> setCategoryVisibility(
    TypeTraitementCategory category,
    bool visible,
  ) async {
    await _db.execute(SqlQueries.setCategoryVisibility, [
      visible ? 1 : 0,
      category.id,
    ]);
    await _db.execute(SqlQueries.setTreatmentsVisibilityByCategory, [
      visible ? 1 : 0,
      category.name,
    ]);
    await loadCatalogForAdmin();
  }

  Future<void> setTreatmentVisibility(
    TypeTraitement treatment,
    bool visible,
  ) async {
    await _db.execute(SqlQueries.setTypeTraitementVisibility, [
      visible ? 1 : 0,
      treatment.id,
    ]);
    await loadCatalogForAdmin();
  }

  Future<void> createTreatment({
    required String category,
    required String name,
  }) async {
    final normalizedCategory = category.trim();
    final normalizedName = name.trim();
    if (normalizedCategory.isEmpty || normalizedName.isEmpty) {
      throw ArgumentError('La catégorie et le traitement sont obligatoires.');
    }
    await _db.execute(SqlQueries.createTypeTraitement, [
      normalizedCategory,
      normalizedName,
    ]);
    await loadAllTraitements();
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
