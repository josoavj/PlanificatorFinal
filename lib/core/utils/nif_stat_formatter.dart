import 'package:flutter/services.dart';

/// Formatteur pour le NIF et le STAT de Madagascar
class NifStatFormatter {
  /// Formate un NIF (10 chiffres) -> "XXX XXX XXX X"
  static String formatNif(String nif) {
    String clean = nif.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 10) clean = clean.substring(0, 10);
    
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      buffer.write(clean[i]);
      if ((i == 2 || i == 5 || i == 8) && i != clean.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  /// Formate un STAT (17 chiffres) -> "XXXXX XX XXXX X XXXXX"
  static String formatStat(String stat) {
    String clean = stat.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 17) clean = clean.substring(0, 17);

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      buffer.write(clean[i]);
      if ((i == 4 || i == 6 || i == 10 || i == 11) && i != clean.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  /// Supprime tout ce qui n'est pas un chiffre
  static String clean(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}

/// Formatteur pour le champ de texte NIF (pendant la saisie)
class NifInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    final formatted = NifStatFormatter.formatNif(text);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatteur pour le champ de texte STAT (pendant la saisie)
class StatInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    final formatted = NifStatFormatter.formatStat(text);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
