import 'package:logger/logger.dart';

class ScheduleGenerator {
  static int extractRedondanceFromFrequency(String frequence) {
    if (frequence.toLowerCase() == 'une seule fois') {
      return 0;
    }
    try {
      final parts = frequence.split(' ');
      if (parts.isNotEmpty) {
        return int.parse(parts[0]);
      }
    } catch (e) {
      Logger().e(' Erreur parsing frequency: $e');
    }
    return 1; // Défaut: 1 mois
  }

  static int cleanMontant(String montantStr) {
    return int.parse(montantStr.replaceAll(' ', '').replaceAll('Ar', ''));
  }
}
