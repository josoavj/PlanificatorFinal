import 'package:flutter/services.dart';

/// Formatteur pour les numéros de téléphone de Madagascar
class PhoneFormatter {
  /// Formate un numéro de 10 chiffres -> "03X XX XXX XX"
  static String format(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length > 10) clean = clean.substring(0, 10);
    
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      buffer.write(clean[i]);
      if ((i == 2 || i == 4 || i == 7) && i != clean.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  /// Joint une liste de numéros en une chaîne séparée par " / "
  static String join(List<String> phones) {
    return phones
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join(' / ');
  }

  /// Découpe une chaîne de numéros concaténés
  static List<String> split(String phoneString) {
    if (phoneString.isEmpty) return [];
    return phoneString.split(' / ').map((p) => p.trim()).toList();
  }
}

/// Formatteur pour le champ de texte téléphone (pendant la saisie)
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    final formatted = PhoneFormatter.format(text);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
