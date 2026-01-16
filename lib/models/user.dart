/// Modèle User
/// Représente un utilisateur connecté
class User {
  final int userId;
  final String email;
  final String nom;
  final String prenom;
  final bool isAdmin;
  final String token;
  final DateTime? createdAt;

  User({
    required this.userId,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.isAdmin,
    this.token = '',
    this.createdAt,
  });

  /// Nom complet
  String get fullName => '$nom $prenom';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      email: json['email'] as String,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      isAdmin: (json['is_admin'] as int?) == 1,
      token: json['token'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'] as int,
      email: map['email'] as String,
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      isAdmin:
          (map['isAdmin'] as int?) == 1 || (map['isAdmin'] as bool?) == true,
      token: map['password'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Aide à parser les dates qui peuvent être String ou DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'email': email,
    'nom': nom,
    'prenom': prenom,
    'is_admin': isAdmin ? 1 : 0,
    'token': token,
  };

  User copyWith({
    int? userId,
    String? email,
    String? nom,
    String? prenom,
    bool? isAdmin,
    String? token,
    DateTime? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      isAdmin: isAdmin ?? this.isAdmin,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'User(id: $userId, email: $email, fullName: $fullName)';
}
