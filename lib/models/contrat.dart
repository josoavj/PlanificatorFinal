/// Modèle Contrat
/// Représente un contrat associé à un client
class Contrat {
  final int contratId;
  final int clientId;
  final String referenceContrat;
  final DateTime dateContrat;
  final DateTime dateDebut;
  final DateTime? dateFin; // Nullable si durée indéterminée
  final String statutContrat; // 'Actif', 'Inactif', 'Terminé', 'Résilié'
  final int dureeContrat; // Durée totale en mois (si déterminée)
  final String dureeType; // 'Indeterminée' ou 'Déterminée' (ENUM en DB)
  final String categorie; // 'Nouveau' ou 'Renouvellement'
  final DateTime? dateAbrogation;
  final String? motifAbrogation;

  Contrat({
    required this.contratId,
    required this.clientId,
    required this.referenceContrat,
    required this.dateContrat,
    required this.dateDebut,
    this.dateFin,
    required this.statutContrat,
    required this.dureeContrat,
    required this.dureeType,
    required this.categorie,
    this.dateAbrogation,
    this.motifAbrogation,
  });

  factory Contrat.fromJson(Map<String, dynamic> json) {
    return Contrat(
      contratId: json['contrat_id'] as int,
      clientId: json['client_id'] as int,
      referenceContrat: json['reference_contrat'] as String,
      dateContrat: DateTime.parse(json['date_contrat'] as String),
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: (json['date_fin'] == null || json['date_fin'] == 'Indéterminée')
          ? null
          : DateTime.tryParse(json['date_fin'].toString()),
      statutContrat: json['statut_contrat'] as String? ?? 'Actif',
      dureeContrat: json['duree_contrat'] as int? ?? 0,
      dureeType: json['duree'] as String? ?? 'Déterminée',
      categorie: json['categorie'] as String? ?? '',
      dateAbrogation: json['date_abrogation'] != null
          ? DateTime.tryParse(json['date_abrogation'].toString())
          : null,
      motifAbrogation: json['motif_abrogation'] as String?,
    );
  }

  factory Contrat.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value == 'Indéterminée' || value == '') return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return Contrat(
      contratId: map['contrat_id'] as int? ?? 0,
      clientId: map['client_id'] as int? ?? 0,
      referenceContrat: map['reference_contrat'] as String? ?? '',
      dateContrat: parseDate(map['date_contrat']) ?? DateTime.now(),
      dateDebut: parseDate(map['date_debut']) ?? DateTime.now(),
      dateFin: parseDate(map['date_fin']),
      statutContrat: map['statut_contrat'] as String? ?? 'Actif',
      dureeContrat: map['duree_contrat'] as int? ?? 0,
      dureeType: map['duree'] as String? ?? 'Déterminée',
      categorie: map['categorie'] as String? ?? '',
      dateAbrogation: parseDate(map['date_abrogation']),
      motifAbrogation: map['motif_abrogation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'contrat_id': contratId,
    'client_id': clientId,
    'reference_contrat': referenceContrat,
    'date_contrat': dateContrat.toIso8601String(),
    'date_debut': dateDebut.toIso8601String(),
    'date_fin': dateFin?.toIso8601String() ?? 'Indéterminée',
    'statut_contrat': statutContrat,
    'duree_contrat': dureeContrat,
    'duree': dureeType,
    'categorie': categorie,
    'date_abrogation': dateAbrogation?.toIso8601String(),
    'motif_abrogation': motifAbrogation,
  };

  bool get isActive {
    final now = DateTime.now();
    return statutContrat == 'Actif' &&
        dateDebut.isBefore(now) &&
        (dateFin == null || dateFin!.isAfter(now));
  }

  Contrat copyWith({
    int? contratId,
    int? clientId,
    String? referenceContrat,
    DateTime? dateContrat,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? statutContrat,
    int? dureeContrat,
    String? dureeType,
    String? categorie,
    DateTime? dateAbrogation,
    String? motifAbrogation,
  }) {
    return Contrat(
      contratId: contratId ?? this.contratId,
      clientId: clientId ?? this.clientId,
      referenceContrat: referenceContrat ?? this.referenceContrat,
      dateContrat: dateContrat ?? this.dateContrat,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      statutContrat: statutContrat ?? this.statutContrat,
      dureeContrat: dureeContrat ?? this.dureeContrat,
      dureeType: dureeType ?? this.dureeType,
      categorie: categorie ?? this.categorie,
      dateAbrogation: dateAbrogation ?? this.dateAbrogation,
      motifAbrogation: motifAbrogation ?? this.motifAbrogation,
    );
  }

  @override
  String toString() => 'Contrat(id: $contratId, ref: $referenceContrat)';
}
