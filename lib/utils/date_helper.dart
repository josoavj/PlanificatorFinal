/// Utilitaire pour conversion de dates cohérente
/// BD: YYYY-MM-DD
/// Affichage: DD/MM/YYYY

class DateHelper {
  /// Convertit une date de BD (YYYY-MM-DD ou DateTime) en format affichage (DD/MM/YYYY)
  static String format(dynamic value) {
    if (value == null) return 'N/A';

    DateTime dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      try {
        dt = DateTime.parse(value);
      } catch (e) {
        return value; // Retourner as-is si parsing échoue
      }
    } else {
      return value.toString();
    }

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  /// Convertit une date d'affichage (DD/MM/YYYY) en format BD (YYYY-MM-DD)
  static String reverseFormat(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final parts = dateString.split('/');
      if (parts.length != 3) return dateString;

      final day = parts[0];
      final month = parts[1];
      final year = parts[2];

      return '$year-$month-$day';
    } catch (e) {
      return dateString;
    }
  }

  /// Parse une date depuis n'importe quel format et retourne DateTime
  static DateTime? parseAny(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        // Essayer format BD (YYYY-MM-DD)
        if (value.contains('-') && !value.contains('/')) {
          return DateTime.parse(value);
        }
        // Essayer format affichage (DD/MM/YYYY)
        if (value.contains('/')) {
          final parts = value.split('/');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
        // Dernier recours
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Convertit une date BD vers DateTime, gère null et String/DateTime
  static DateTime toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Convertit une date DateTime vers format BD (YYYY-MM-DD)
  static String toDbFormat(DateTime? dt) {
    if (dt == null) return '';
    return dt.toIso8601String().split('T')[0];
  }
}
