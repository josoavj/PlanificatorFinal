/// Utilitaires pour la manipulation des nombres (prix, montants)
class NumberFormatter {
  /// Parse un montant en ignorant les espaces et caractères non-numériques
  /// Retourne TOUJOURS un montant positif (les montants négatifs ne sont pas autorisés)
  /// Exemple: "50 000" → 50000, "-50 000" → 50000
  /// Utile pour les saisies utilisateur avec séparateurs
  static int parseMontant(String input) {
    if (input.isEmpty) {
      throw FormatException('Montant vide');
    }

    // Supprimer tous les espaces
    final cleaned = input.replaceAll(' ', '').trim();

    // Garder SEULEMENT les chiffres (pas de signes négatifs)
    // Les montants doivent TOUJOURS être positifs
    final numeric = cleaned.replaceAll(RegExp(r'[^\d]'), '');

    if (numeric.isEmpty) {
      throw FormatException('Aucun chiffre trouvé dans: $input');
    }

    return int.parse(numeric);
  }

  /// Formate un montant avec séparateurs d'espaces
  /// Exemple: 50000 → "50 000"
  static String formatMontant(int montant) {
    final str = montant.toString();
    final isNegative = montant < 0;
    final absStr = isNegative ? str.substring(1) : str;

    // Ajouter les espaces tous les 3 chiffres depuis la droite
    final reversed = absStr.split('').reversed.toList();
    final parts = <String>[];

    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        parts.add(' ');
      }
      parts.add(reversed[i]);
    }

    final formatted = parts.reversed.join('');
    return isNegative ? '-$formatted' : formatted;
  }

  /// Valide qu'une string peut être parsée en montant
  static bool isValidMontant(String input) {
    try {
      parseMontant(input);
      return true;
    } catch (e) {
      return false;
    }
  }
}
