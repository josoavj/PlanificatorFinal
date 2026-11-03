/// Utilitaires pour la validation des emails
library;

class EmailValidator {
  /// Vérifie si un email a un format valide
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Vérifie plusieurs critères d'un email (pattern strict)
  static bool isValidEmailStrict(String email) {
    if (email.isEmpty) return false;

    // Vérification simple
    if (!email.contains('@') || !email.contains('.')) {
      return false;
    }

    final parts = email.split('@');
    if (parts.length != 2) return false;

    final domainParts = parts[1].split('.');
    return domainParts.length >= 2 && domainParts.every((p) => p.isNotEmpty);
  }

  /// Nettoie et normalise une adresse email
  static String normalizeEmail(String email) {
    return email.toLowerCase().trim();
  }
}
