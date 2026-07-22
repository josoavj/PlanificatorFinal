import 'dart:convert';
import 'dart:typed_data';

/// Modèle Facture
/// Représente une facture pour un traitement
class Facture {
  final int factureId;
  final int? planningDetailsId; // Modifié : NULL si facture groupée
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

    // Helper pour convertir proprement les BLOB (Uint8List) en String
    String? dbString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List<int>) return utf8.decode(value);
      return value.toString();
    }

    // Helper pour convertir proprement les entiers
    int? dbInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return int.tryParse(value.toString());
    }

    return Facture(
      factureId: dbInt(json['facture_id']) ?? 0,
      planningDetailsId: dbInt(json['planning_detail_id']),
      referenceFacture: dbString(json['reference_facture']),
      montant: dbInt(json['montant']) ?? 0,
      mode: dbString(json['mode']),
      etablissementPayeur: dbString(json['etablissement_payeur']),
      dateCheque: json['date_cheque'] != null
          ? DateTime.tryParse(json['date_cheque'].toString())
          : null,
      numeroCheque: dbString(json['numero_cheque']),
      dateTraitement: parsedDateTraitement,
      etat: dbString(json['etat']) ?? 'Non payé',
      axe: dbString(json['axe']) ?? 'Centre (C)',
    );
  }

  factory Facture.fromMap(Map<String, dynamic> map) {
    // Gérer dateTraitement de manière robuste
    DateTime parsedDateTraitement;
    try {
      final dateValue = map['date_traitement'];
      if (dateValue is DateTime) {
        parsedDateTraitement = dateValue;
      } else if (dateValue is String && dateValue.isNotEmpty) {
        parsedDateTraitement = DateTime.parse(dateValue);
      } else {
        parsedDateTraitement = DateTime.now();
      }
    } catch (e) {
      parsedDateTraitement = DateTime.now();
    }

    // Helper pour convertir proprement les BLOB (Uint8List) en String
    String? dbString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List<int>) return utf8.decode(value);
      return value.toString();
    }

    // Helper pour convertir proprement les entiers
    int? dbInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return int.tryParse(value.toString());
    }

    return Facture(
      factureId: dbInt(map['facture_id']) ?? 0,
      planningDetailsId: dbInt(map['planning_detail_id']),
      referenceFacture: dbString(map['reference_facture']),
      montant: dbInt(map['montant']) ?? 0,
      mode: dbString(map['mode']),
      etablissementPayeur: dbString(map['etablissement_payeur']),
      dateCheque: map['date_cheque'] != null
          ? DateTime.tryParse(map['date_cheque'].toString())
          : null,
      numeroCheque: dbString(map['numero_cheque']),
      dateTraitement: parsedDateTraitement,
      etat: dbString(map['etat']) ?? 'Non payé',
      axe: dbString(map['axe']) ?? 'Centre (C)',
      clientId: dbInt(map['client_id']),
      clientNom: dbString(map['clientNom']),
      clientPrenom: dbString(map['clientPrenom']),
      clientCategorie: dbString(map['clientCategorie']),
      typeTreatment: dbString(map['typeTreatment']),
      datePlanification: map['datePlanification'] != null
          ? DateTime.tryParse(map['datePlanification'].toString())
          : null,
      etatPlanning: dbString(map['etatPlanning']),
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
