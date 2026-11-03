class Traitement {
  final int? id;
  final int contratId;
  final int typeTraitementId;
  final DateTime? createdAt;

  Traitement({
    this.id,
    required this.contratId,
    required this.typeTraitementId,
    this.createdAt,
  });

  // Serialization from JSON (MySQL result)
  factory Traitement.fromJson(Map<String, dynamic> json) {
    return Traitement(
      id: json['id_traitement'] ?? json['traitement_id'],
      contratId: json['contrat_id'] ?? 0,
      typeTraitementId:
          json['id_type_traitement'] ?? json['type_traitement_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id_traitement': id,
      'contrat_id': contratId,
      'id_type_traitement': typeTraitementId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Traitement(id: $id, contrat: $contratId, type: $typeTraitementId)';
}
