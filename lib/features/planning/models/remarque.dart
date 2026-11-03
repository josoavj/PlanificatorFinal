class Remarque {
  final int? id;
  final int planningDetailId;
  final int? factureId;
  final String? contenu;
  final String? probleme;
  final String? action;
  final String? modePaiement; // 'Cheque', 'Espece', 'Virement', 'Mobile Money'
  final String? nomFacture;
  final String? datePayement;
  final String? etablissement;
  final String? numeroCheque;
  final bool estPayee;
  final DateTime? dateCreation;

  Remarque({
    this.id,
    required this.planningDetailId,
    this.factureId,
    this.contenu,
    this.probleme,
    this.action,
    this.modePaiement,
    this.nomFacture,
    this.datePayement,
    this.etablissement,
    this.numeroCheque,
    this.estPayee = false,
    this.dateCreation,
  });

  // Serialization from JSON (MySQL result)
  factory Remarque.fromJson(Map<String, dynamic> json) {
    // Helper pour convertir Blob en String si nécessaire
    String? toStr(dynamic val, [String? def]) {
      if (val == null) return def;
      if (val is String) return val;
      if (val is List<int>) return String.fromCharCodes(val); // Blob conversion
      return val.toString();
    }

    return Remarque(
      id: json['id_remarque'] ?? json['remarque_id'],
      planningDetailId:
          json['planning_detail_id'] ?? json['id_planning_details'] ?? 0,
      factureId: json['factur_id'] ?? json['facture_id'],
      contenu: toStr(json['contenu']) ?? toStr(json['remarque']),
      probleme: toStr(json['probleme']) ?? toStr(json['issue']),
      action: toStr(json['action']),
      modePaiement: toStr(json['mode_paiement']) ?? toStr(json['paiement']),
      nomFacture: toStr(json['nom_facture']) ?? toStr(json['numero_facture']),
      datePayement:
          toStr(json['date_payement']) ?? toStr(json['date_paiement']),
      etablissement: toStr(json['etablissement']) ?? toStr(json['bank']),
      numeroCheque: toStr(json['numero_cheque']) ?? toStr(json['cheque_num']),
      estPayee:
          (json['est_payee'] ?? json['is_paid'] ?? false) == true ||
          (json['est_payee'] ?? json['is_paid'] ?? false) == 1,
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'].toString())
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id_remarque': id,
      'planning_detail_id': planningDetailId,
      'factur_id': factureId,
      'contenu': contenu,
      'probleme': probleme,
      'action': action,
      'mode_paiement': modePaiement,
      'nom_facture': nomFacture,
      'date_payement': datePayement,
      'etablissement': etablissement,
      'numero_cheque': numeroCheque,
      'est_payee': estPayee ? 1 : 0,
      'date_creation': dateCreation?.toIso8601String(),
    };
  }

  // Check if complete (has required info)
  bool get isComplete => contenu != null && contenu!.isNotEmpty;

  @override
  String toString() =>
      'Remarque(id: $id, planning_detail: $planningDetailId, contenu: $contenu)';
}
