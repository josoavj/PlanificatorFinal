class Signalement {
  final int? id;
  final int planningDetailId;
  final String motif;
  final String type; // 'avancement' ou 'décalage'
  final DateTime? dateSignalement;

  Signalement({
    this.id,
    required this.planningDetailId,
    required this.motif,
    required this.type,
    this.dateSignalement,
  });

  // Serialization from JSON (MySQL result)
  factory Signalement.fromJson(Map<String, dynamic> json) {
    // Helper pour convertir Blob en String si nécessaire
    String toStr(dynamic val, [String def = '']) {
      if (val == null) return def;
      if (val is String) return val;
      if (val is List<int>) return String.fromCharCodes(val); // Blob conversion
      return val.toString();
    }

    return Signalement(
      id: json['id_signalement'] ?? json['signalement_id'],
      planningDetailId:
          json['planning_detail_id'] ?? json['id_planning_details'] ?? 0,
      motif: toStr(json['motif']),
      type: toStr(json['type'], 'décalage'),
      dateSignalement: json['date_signalement'] != null
          ? DateTime.parse(json['date_signalement'].toString())
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_signalement': id,
      'planning_detail_id': planningDetailId,
      'motif': motif,
      'type': type,
      'date_signalement': dateSignalement?.toIso8601String().split('T')[0],
    };
  }

  // Check if avancement (progress) vs décalage (delay)
  bool get isAvancement => type.toLowerCase() == 'avancement';
  bool get isDecalage => type.toLowerCase() == 'décalage';

  @override
  String toString() =>
      'Signalement(id: $id, planning_detail: $planningDetailId, type: $type, motif: $motif)';
}
