class PasswordValidator {
  /// Vérifie si le mot de passe contient des informations personnelles (nom/prénom)
  static bool isPasswordPersonalInfo(
    String password,
    String nom,
    String prenom,
  ) {
    final passwordLower = password.toLowerCase();

    if (nom.isNotEmpty && passwordLower.contains(nom.toLowerCase())) {
      return true;
    }

    if (prenom.isNotEmpty && passwordLower.contains(prenom.toLowerCase())) {
      return true;
    }

    return false;
  }

  /// Valide un mot de passe - retourne le message d'erreur ou vide si OK
  static String validatePassword(
    String password,
    String confirmPassword,
    String nom,
    String prenom,
  ) {
    // Vérifier que les mots de passe correspondent
    if (password != confirmPassword) {
      return 'Les mots de passe ne correspondent pas. Veuillez réessayer.';
    }

    // Vérifier la longueur minimale
    if (password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }

    // Vérifier qu'il ne contient pas d'informations personnelles
    if (isPasswordPersonalInfo(password, nom, prenom)) {
      return 'Le mot de passe ne doit pas contenir votre nom ou prénom. Veuillez réessayer.';
    }

    // Vérifier la complexité (au moins 1 majuscule, 1 minuscule, 1 chiffre)
    if (!_hasComplexity(password)) {
      return 'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre.';
    }

    return ''; // Pas d'erreur
  }

  /// Vérifie la complexité d'un mot de passe
  static bool _hasComplexity(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));

    return hasUppercase && hasLowercase && hasDigit;
  }

  /// Donne un score de sécurité pour un mot de passe (0-100)
  static int getPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    if (password.contains(RegExp(r'[a-z]'))) score += 15;
    if (password.contains(RegExp(r'[A-Z]'))) score += 15;
    if (password.contains(RegExp(r'[0-9]'))) score += 15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 15;

    return score;
  }

  /// Obtient une description textuelle de la force du mot de passe
  static String getPasswordStrengthLabel(int score) {
    if (score < 30) return 'Très faible';
    if (score < 50) return 'Faible';
    if (score < 70) return 'Moyen';
    if (score < 85) return 'Fort';
    return 'Très fort';
  }
}
