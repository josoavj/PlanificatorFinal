/// Modèle Facture
/// Représente une facture pour un traitement
class Facture {
  final int factureId;
  final int planningDetailsId;
  final String? referenceFacture;
  final int montant; // Montant en Ar (entier)
  final String? mode; // 'Chèque', 'Espèce', 'Mobile Money', 'Virement'
  final String? etablissementPayeur;
  final DateTime? dateCheque;
  final String? numeroCheque;
  final DateTime dateTraitement;
  final String etat; // 'Payé', 'Non payé', 'À venir'
  final String axe; // 'Nord (N)', 'Sud (S)', etc.

  // Données jointes pour affichage
  final int? clientId;
  final String? clientNom;
  final String? clientPrenom;
  final String? clientCategorie;
  final String? typeTreatment;
  final DateTime? datePlanification;
  final String? etatPlanning;

  Facture({
    required this.factureId,
    required this.planningDetailsId,
    this.referenceFacture,
    required this.montant,
    this.mode,
    this.etablissementPayeur,
    this.dateCheque,
    this.numeroCheque,
    required this.dateTraitement,
    required this.etat,
    required this.axe,
    this.clientId,
    this.clientNom,
    this.clientPrenom,
    this.clientCategorie,
    this.typeTreatment,
    this.datePlanification,
    this.etatPlanning,
  });

  factory Facture.fromJson(Map<String, dynamic> json) {
    // Gérer dateTraitement qui peut être DateTime ou String
    DateTime parsedDateTraitement;
    final dateValue = json['date_traitement'];
    if (dateValue is DateTime) {
      parsedDateTraitement = dateValue;
    } else if (dateValue is String) {
      parsedDateTraitement = DateTime.parse(dateValue);
    } else {
      parsedDateTraitement = DateTime.now();
    }

    return Facture(
      factureId: json['facture_id'] as int,
      planningDetailsId: json['planning_detail_id'] as int,
      referenceFacture: json['reference_facture'] as String?,
      montant: json['montant'] as int,
      mode: json['mode'] as String?,
      etablissementPayeur: json['etablissement_payeur'] as String?,
      dateCheque: json['date_cheque'] != null
          ? DateTime.tryParse(json['date_cheque'].toString())
          : null,
      numeroCheque: json['numero_cheque'] as String?,
      dateTraitement: parsedDateTraitement,
      etat: json['etat'] as String? ?? 'Non payé',
      axe: json['axe'] as String,
    );
  }

  factory Facture.fromMap(Map<String, dynamic> map) {
    // Gérer dateTraitement qui peut être DateTime ou String
    DateTime parsedDateTraitement;
    final dateValue = map['date_traitement'];
    if (dateValue is DateTime) {
      parsedDateTraitement = dateValue;
    } else if (dateValue is String) {
      parsedDateTraitement = DateTime.parse(dateValue);
    } else {
      parsedDateTraitement = DateTime.now();
    }

    return Facture(
      factureId: map['facture_id'] as int,
      planningDetailsId: map['planning_detail_id'] as int,
      referenceFacture: map['reference_facture'] as String?,
      montant: map['montant'] as int,
      mode: map['mode'] as String?,
      etablissementPayeur: map['etablissement_payeur'] as String?,
      dateCheque: map['date_cheque'] != null
          ? DateTime.tryParse(map['date_cheque'].toString())
          : null,
      numeroCheque: map['numero_cheque'] as String?,
      dateTraitement: parsedDateTraitement,
      etat: map['etat'] as String? ?? 'Non payé',
      axe: map['axe'] as String,
      clientId: map['client_id'] as int?,
      clientNom: map['clientNom'] as String?,
      clientPrenom: map['clientPrenom'] as String?,
      clientCategorie: map['clientCategorie'] as String?,
      typeTreatment: map['typeTreatment'] as String?,
      datePlanification: map['datePlanification'] != null
          ? DateTime.tryParse(map['datePlanification'].toString())
          : null,
      etatPlanning: map['etatPlanning'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'facture_id': factureId,
    'planning_detail_id': planningDetailsId,
    'reference_facture': referenceFacture,
    'montant': montant,
    'mode': mode,
    'etablissement_payeur': etablissementPayeur,
    'date_cheque': dateCheque?.toIso8601String(),
    'numero_cheque': numeroCheque,
    'date_traitement': dateTraitement.toIso8601String(),
    'etat': etat,
    'axe': axe,
  };

  /// Format montant avec séparateur de milliers
  String get montantFormatted {
    final formatter = _NumberFormatter();
    return '${formatter.format(montant)} Ar';
  }

  /// Nom complet du client
  /// Pour Société et Organisation: affiche seulement le nom
  /// Pour les autres catégories: affiche prénom et nom
  String get clientFullName {
    if (clientCategorie == 'Société' || clientCategorie == 'Organisation') {
      return clientNom ?? 'N/A';
    }
    if (clientNom != null || clientPrenom != null) {
      return '${clientNom ?? ''} ${clientPrenom ?? ''}'.trim();
    }
    return 'N/A';
  }

  /// Est payée ?
  bool get isPaid => etat == 'Payé' || etat == 'Payée';

  Facture copyWith({
    int? factureId,
    int? planningDetailsId,
    String? referenceFacture,
    int? montant,
    String? mode,
    String? etablissementPayeur,
    DateTime? dateCheque,
    String? numeroCheque,
    DateTime? dateTraitement,
    String? etat,
    String? axe,
    int? clientId,
    String? clientNom,
    String? clientPrenom,
    String? clientCategorie,
    String? typeTreatment,
    DateTime? datePlanification,
    String? etatPlanning,
  }) {
    return Facture(
      factureId: factureId ?? this.factureId,
      planningDetailsId: planningDetailsId ?? this.planningDetailsId,
      referenceFacture: referenceFacture ?? this.referenceFacture,
      montant: montant ?? this.montant,
      mode: mode ?? this.mode,
      etablissementPayeur: etablissementPayeur ?? this.etablissementPayeur,
      dateCheque: dateCheque ?? this.dateCheque,
      numeroCheque: numeroCheque ?? this.numeroCheque,
      dateTraitement: dateTraitement ?? this.dateTraitement,
      etat: etat ?? this.etat,
      axe: axe ?? this.axe,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      clientPrenom: clientPrenom ?? this.clientPrenom,
      typeTreatment: typeTreatment ?? this.typeTreatment,
      datePlanification: datePlanification ?? this.datePlanification,
      etatPlanning: etatPlanning ?? this.etatPlanning,
    );
  }

  @override
  String toString() =>
      'Facture(id: $factureId, montant: $montantFormatted, client: $clientFullName)';
}

/// Utilitaire pour formatter les nombres
class _NumberFormatter {
  String format(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ' ',
    );
  }
}
