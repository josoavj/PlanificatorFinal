/// Requêtes SQL liées à ce domaine fonctionnel.
class CatalogueQueries {
  static const String getAllTypeTraitements = '''SELECT tt.*
      FROM TypeTraitement tt
      INNER JOIN TypeTraitementCategorie tc
        ON tc.nom = tt.categorieTraitement AND tc.actif = TRUE
      WHERE tt.actif = TRUE
      ORDER BY tt.id_type_traitement''';

  static const String getAllTypeTraitementsForAdmin =
      'SELECT * FROM TypeTraitement ORDER BY id_type_traitement';

  static const String getAllTraitementCategories =
      'SELECT * FROM TypeTraitementCategorie WHERE actif = TRUE ORDER BY nom';

  static const String getAllTraitementCategoriesForAdmin =
      'SELECT * FROM TypeTraitementCategorie ORDER BY nom';

  static const String createTraitementCategory =
      'INSERT INTO TypeTraitementCategorie (nom) VALUES (?)';

  static const String createTypeTraitement =
      'INSERT INTO TypeTraitement (categorieTraitement, typeTraitement) VALUES (?, ?)';

  static const String setTypeTraitementVisibility =
      'UPDATE TypeTraitement SET actif = ? WHERE id_type_traitement = ?';

  static const String setCategoryVisibility =
      'UPDATE TypeTraitementCategorie SET actif = ? WHERE id_categorie = ?';

  static const String setTreatmentsVisibilityByCategory =
      'UPDATE TypeTraitement SET actif = ? WHERE categorieTraitement = ?';
}
