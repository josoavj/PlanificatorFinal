class TypeTraitement {
  final int? id;
  final String categorie;
  final String type;
  final DateTime? createdAt;
  final bool actif;

  TypeTraitement({
    this.id,
    required this.categorie,
    required this.type,
    this.createdAt,
    this.actif = true,
  });

  // Serialization from JSON (MySQL result)
  factory TypeTraitement.fromJson(Map<String, dynamic> json) {
    return TypeTraitement(
      id: json['id_type_traitement'] ?? json['type_traitement_id'],
      categorie: json['categorieTraitement'] ?? json['categorie'] ?? '',
      type: json['typeTraitement'] ?? json['type'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
      actif: json['actif'] is bool
          ? json['actif'] as bool
          : (json['actif'] as num?)?.toInt() != 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_type_traitement': id,
      'categorieTraitement': categorie,
      'typeTraitement': type,
      'created_at': createdAt?.toIso8601String(),
      'actif': actif ? 1 : 0,
    };
  }

  // Display name (e.g., "Dératisation (PC)")
  String get displayName => '$type ($categorie)';

  @override
  String toString() => 'TypeTraitement(id: $id, $categorie - $type)';
}
