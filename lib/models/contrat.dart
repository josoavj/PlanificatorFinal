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
  final int dureeContrat; // Durée en mois
  final int? duree; // Durée restante en mois (null si indéterminée)
  final String categorie; // Catégorie du contrat
  final DateTime? dateAbrogation; // Date de résiliation/abrogation
  final String? motifAbrogation; // Raison de l'abrogation

  Contrat({
    required this.contratId,
    required this.clientId,
    required this.referenceContrat,
    required this.dateContrat,
    required this.dateDebut,
    this.dateFin,
    required this.statutContrat,
    required this.dureeContrat,
    this.duree,
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
      dateFin:
          (json['date_fin'] is String &&
              (json['date_fin'] as String).toLowerCase() == 'indéterminée')
          ? null
          : DateTime.parse(json['date_fin'] as String),
      statutContrat: json['statut_contrat'] as String? ?? 'Actif',
      dureeContrat: json['duree_contrat'] as int? ?? 0,
      duree:
          (json['duree'] is String &&
              (json['duree'] as String).toLowerCase() == 'indéterminée')
          ? null
          : json['duree'] as int?,
      categorie: json['categorie'] as String? ?? '',
      dateAbrogation:
          json['date_abrogation'] is String &&
              (json['date_abrogation'] as String).isNotEmpty
          ? DateTime.parse(json['date_abrogation'] as String)
          : null,
      motifAbrogation: json['motif_abrogation'] as String?,
    );
  }

  factory Contrat.fromMap(Map<String, dynamic> map) {
    // Fonction helper pour convertir des dates de différents formats
    DateTime? parseDate(dynamic value) {
      if (value is DateTime) {
        return value;
      } else if (value is String) {
        // Gérer les cas spéciaux comme "Indéterminée"
        if (value.toLowerCase() == 'indéterminée' || value.isEmpty) {
          return null;
        }
        return DateTime.parse(value);
      } else if (value is int) {
        // Si c'est un timestamp en millisecondes
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return null;
      }
    }

    int? parseDuree(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is String) {
        // Gérer les cas spéciaux comme "Indéterminée"
        if (value.toLowerCase() == 'indéterminée' || value.isEmpty) {
          return null;
        }
        return int.tryParse(value);
      } else {
        return null;
      }
    }

    return Contrat(
      contratId: map['contrat_id'] as int,
      clientId: map['client_id'] as int,
      referenceContrat: map['reference_contrat'] as String,
      dateContrat: parseDate(map['date_contrat']) ?? DateTime.now(),
      dateDebut: parseDate(map['date_debut']) ?? DateTime.now(),
      dateFin: parseDate(map['date_fin']),
      statutContrat: map['statut_contrat'] as String? ?? 'Actif',
      dureeContrat: parseDuree(map['duree_contrat']) ?? 0,
      duree: parseDuree(map['duree']),
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
    'duree': duree,
    'categorie': categorie,
    'date_abrogation': dateAbrogation?.toIso8601String(),
    'motif_abrogation': motifAbrogation,
  };

  /// Vérifie si le contrat est actif
  bool get isActive {
    final now = DateTime.now();
    // Si date_fin est null (indéterminée), on considère le contrat comme potentiellement actif
    return dateDebut.isBefore(now) &&
        (dateFin == null || dateFin!.isAfter(now)) &&
        statutContrat == 'Actif';
  }

  /// Copier avec quelques modifications
  Contrat copyWith({
    int? contratId,
    int? clientId,
    String? referenceContrat,
    DateTime? dateContrat,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? statutContrat,
    int? dureeContrat,
    int? duree,
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
      duree: duree ?? this.duree,
      categorie: categorie ?? this.categorie,
      dateAbrogation: dateAbrogation ?? this.dateAbrogation,
      motifAbrogation: motifAbrogation ?? this.motifAbrogation,
    );
  }

  @override
  String toString() =>
      'Contrat(id: $contratId, clientId: $clientId, duree: $dureeContrat mois)';
}
