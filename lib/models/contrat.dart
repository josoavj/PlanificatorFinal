/// Modèle Contrat
/// Représente un contrat associé à un client
class Contrat {
  final int contratId;
  final int clientId;
  final String referenceContrat;
  final DateTime dateContrat;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statutContrat; // 'Actif', 'Inactif', 'Terminé'
  final int dureeContrat; // Durée en mois
  final int duree; // Durée restante en mois
  final String categorie; // Catégorie du contrat

  Contrat({
    required this.contratId,
    required this.clientId,
    required this.referenceContrat,
    required this.dateContrat,
    required this.dateDebut,
    required this.dateFin,
    required this.statutContrat,
    required this.dureeContrat,
    required this.duree,
    required this.categorie,
  });

  factory Contrat.fromJson(Map<String, dynamic> json) {
    return Contrat(
      contratId: json['contrat_id'] as int,
      clientId: json['client_id'] as int,
      referenceContrat: json['reference_contrat'] as String,
      dateContrat: DateTime.parse(json['date_contrat'] as String),
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      statutContrat: json['statut_contrat'] as String? ?? 'Actif',
      dureeContrat: json['duree_contrat'] as int? ?? 0,
      duree: json['duree'] as int? ?? 0,
      categorie: json['categorie'] as String? ?? '',
    );
  }

  factory Contrat.fromMap(Map<String, dynamic> map) {
    // Fonction helper pour convertir des dates de différents formats
    DateTime _parseDate(dynamic value) {
      if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        // Si c'est un timestamp en millisecondes
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        throw Exception('Format de date invalide: $value');
      }
    }

    return Contrat(
      contratId: map['contrat_id'] as int,
      clientId: map['client_id'] as int,
      referenceContrat: map['reference_contrat'] as String,
      dateContrat: _parseDate(map['date_contrat']),
      dateDebut: _parseDate(map['date_debut']),
      dateFin: _parseDate(map['date_fin']),
      statutContrat: map['statut_contrat'] as String? ?? 'Actif',
      dureeContrat: map['duree_contrat'] as int? ?? 0,
      duree: map['duree'] as int? ?? 0,
      categorie: map['categorie'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'contrat_id': contratId,
    'client_id': clientId,
    'reference_contrat': referenceContrat,
    'date_contrat': dateContrat.toIso8601String(),
    'date_debut': dateDebut.toIso8601String(),
    'date_fin': dateFin.toIso8601String(),
    'statut_contrat': statutContrat,
    'duree_contrat': dureeContrat,
    'duree': duree,
    'categorie': categorie,
  };

  /// Vérifie si le contrat est actif
  bool get isActive {
    final now = DateTime.now();
    return dateDebut.isBefore(now) &&
        dateFin.isAfter(now) &&
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
    );
  }

  @override
  String toString() =>
      'Contrat(id: $contratId, clientId: $clientId, duree: $dureeContrat mois)';
}
