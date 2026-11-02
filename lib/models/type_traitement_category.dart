class TypeTraitementCategory {
  const TypeTraitementCategory({
    required this.id,
    required this.name,
    this.actif = true,
  });

  final int id;
  final String name;
  final bool actif;

  factory TypeTraitementCategory.fromJson(Map<String, dynamic> json) {
    return TypeTraitementCategory(
      id: (json['id_categorie'] as num).toInt(),
      name: json['nom'] as String,
      actif: json['actif'] is bool
          ? json['actif'] as bool
          : (json['actif'] as num?)?.toInt() != 0,
    );
  }
}
