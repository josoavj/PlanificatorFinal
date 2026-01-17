/// Modèle Client
/// Représente un client dans le système Planificator
class Client {
  final int clientId;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String adresse;
  final String categorie;
  final String nif;
  final String stat;
  final String axe;
  final DateTime dateAjout;
  final int treatmentCount;

  Client({
    required this.clientId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.categorie,
    required this.nif,
    required this.stat,
    required this.axe,
    required this.dateAjout,
    this.treatmentCount = 0,
  });

  /// Nom complet du client
  /// Pour Société et Organisation: affiche seulement le nom
  /// Pour les autres catégories: affiche nom et prénom
  String get fullName {
    if (categorie == 'Société' || categorie == 'Organisation') {
      return nom;
    }
    return '$nom $prenom'.trim();
  }

  /// Récupère le label pour le prénom selon la catégorie
  /// Retourne "Responsable" pour Société/Organisation, "Prénom" sinon
  String get prenomLabel {
    if (categorie == 'Société' || categorie == 'Organisation') {
      return 'Responsable';
    }
    return 'Prénom';
  }

  /// Factory constructor pour créer un Client à partir d'une Map (base de données)
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      clientId: map['client_id'] as int,
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telephone: map['telephone'] as String? ?? '',
      adresse: map['adresse'] as String? ?? '',
      categorie: map['categorie'] as String? ?? '',
      nif: map['nif'] as String? ?? '',
      stat: map['stat'] as String? ?? '',
      axe: map['axe'] as String? ?? '',
      dateAjout: map['date_ajout'] is String
          ? DateTime.parse(map['date_ajout'] as String)
          : DateTime.now(),
      treatmentCount: map['treatment_count'] as int? ?? 0,
    );
  }

  /// Factory constructor pour créer un Client à partir d'une Map (JSON)
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      clientId: json['client_id'] as int,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      categorie: json['categorie'] as String? ?? '',
      nif: json['nif'] as String? ?? '',
      stat: json['stat'] as String? ?? '',
      axe: json['axe'] as String? ?? '',
      dateAjout: json['date_ajout'] is String
          ? DateTime.parse(json['date_ajout'] as String)
          : DateTime.now(),
      treatmentCount: json['treatment_count'] as int? ?? 0,
    );
  }

  /// Convertir en Map (JSON)
  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'telephone': telephone,
    'adresse': adresse,
    'categorie': categorie,
    'nif': nif,
    'stat': stat,
    'axe': axe,
    'date_ajout': dateAjout.toIso8601String(),
    'treatment_count': treatmentCount,
  };

  /// Copier avec quelques modifications
  Client copyWith({
    int? clientId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? adresse,
    String? categorie,
    String? nif,
    String? stat,
    String? axe,
    DateTime? dateAjout,
    int? treatmentCount,
  }) {
    return Client(
      clientId: clientId ?? this.clientId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      categorie: categorie ?? this.categorie,
      nif: nif ?? this.nif,
      stat: stat ?? this.stat,
      axe: axe ?? this.axe,
      dateAjout: dateAjout ?? this.dateAjout,
      treatmentCount: treatmentCount ?? this.treatmentCount,
    );
  }

  @override
  String toString() => 'Client(id: $clientId, nom: $fullName)';
}
