import 'package:intl/intl.dart';

class DateUtils {
  /// Décale la date au lundi si elle tombe un dimanche, puis vérifie les jours fériés
  static DateTime adjustIfWeekendAndHoliday(DateTime date) {
    // Étape 1: Décaler si dimanche
    DateTime adjusted = date;
    if (adjusted.weekday == 7) {
      // Dimanche → lundi
      adjusted = adjusted.add(const Duration(days: 1));
    }

    // Étape 2: Vérifier si jour férié et décaler jusqu'à trouver un jour ouvrable
    final holidays = getHolidaysForYear(adjusted.year);
    while (holidays.values.any(
      (h) =>
          h.year == adjusted.year &&
          h.month == adjusted.month &&
          h.day == adjusted.day,
    )) {
      adjusted = adjusted.add(const Duration(days: 1));
      // Vérifier à nouveau si dimanche après décalage
      if (adjusted.weekday == 7) {
        adjusted = adjusted.add(const Duration(days: 1));
      }
    }

    return adjusted;
  }

  /// Décale la date au lundi si elle tombe un dimanche (simple)
  static DateTime adjustIfWeekend(DateTime date) {
    if (date.weekday == 7) {
      // Dimanche
      return date.add(const Duration(days: 1));
    }
    return date;
  }

  /// Calcule la date de Pâques pour une année donnée
  /// Utilise l'algorithme de Butcher-Meeus
  static DateTime calculateEaster(int year) {
    int a = year % 19;
    int b = year ~/ 100;
    int c = year % 100;
    int d = b ~/ 4;
    int e = b % 4;
    int f = (b + 8) ~/ 25;
    int g = (b - f + 1) ~/ 3;
    int h = (19 * a + b - d - g + 15) % 30;
    int i = c ~/ 4;
    int k = c % 4;
    int l = (32 + 2 * e + 2 * i - h - k) % 7;
    int m = (a + 11 * h + 22 * l) ~/ 451;
    int month = (h + l - 7 * m + 114) ~/ 31;
    int day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Retourne tous les jours fériés à Madagascar pour une année donnée
  static Map<String, DateTime> getHolidaysForYear(int year) {
    final holidays = <String, DateTime>{
      // Jours fériés fixes à Madagascar
      "Jour de l'an": DateTime(year, 1, 1),
      "Fête nationale": DateTime(year, 6, 26), // Indépendance Madagascar
      "Assomption": DateTime(year, 8, 15),
      "Toussaint": DateTime(year, 11, 1),
      "Noël": DateTime(year, 12, 25),
    };

    // Calcul des jours fériés variables basés sur Pâques
    final easter = calculateEaster(year);
    holidays.addAll({
      "Pâques": easter,
      "Lundi de Pâques": easter.add(const Duration(days: 1)),
      "Ascension": easter.add(const Duration(days: 39)),
      "Lundi de Pentecôte": easter.add(const Duration(days: 50)),
    });

    return holidays;
  }

  /// Vérifie si une date est un jour férié
  static bool isHoliday(DateTime date) {
    final holidays = getHolidaysForYear(date.year);
    for (final holiday in holidays.values) {
      if (date.year == holiday.year &&
          date.month == holiday.month &&
          date.day == holiday.day) {
        return true;
      }
    }
    return false;
  }

  /// Retourne le nombre de jours ouvrables (hors weekends et jours fériés) entre deux dates
  static int getWorkingDaysBetween(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Vérifier si c'est un jour ouvrable (lun-ven) et pas un jour férié
      if (current.weekday >= 1 && current.weekday <= 5 && !isHoliday(current)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  /// Formatte une date en format lisible français
  static String formatDateFr(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy', 'fr_FR');
    return formatter.format(date);
  }

  /// Formatte une date en format court français (JJ/MM/YYYY)
  static String formatDateFrShort(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'fr_FR');
    return formatter.format(date);
  }

  /// Obtient le jour de la semaine en français
  static String getDayNameFr(DateTime date) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[date.weekday - 1];
  }

  /// Génère les dates de planning selon la fréquence
  /// fréquence = 0: Une seule fois → 1 date
  /// fréquence = 1: Chaque mois → 12 dates (0, 1, 2, ..., 11 mois)
  /// fréquence = 2: Tous les 2 mois → 6 dates (0, 2, 4, 6, 8, 10 mois)
  /// fréquence = 3: Tous les 3 mois → 4 dates (0, 3, 6, 9 mois)
  static List<DateTime> planningPerYear(DateTime startDate, int frequency) {
    final dates = <DateTime>[];

    // Cas spécial: une seule fois
    if (frequency == 0) {
      var singleDate = adjustIfWeekend(startDate);
      final holidays = getHolidaysForYear(singleDate.year);

      // Décaler si jour férié
      while (holidays.values.any(
        (h) =>
            h.year == singleDate.year &&
            h.month == singleDate.month &&
            h.day == singleDate.day,
      )) {
        singleDate = singleDate.add(const Duration(days: 1));
      }

      dates.add(singleDate);
    } else {
      // Cas normal: générer une date tous les N mois pendant 12 mois
      for (int i = 0; i < (12 ~/ frequency); i++) {
        var plannedDate = _addMonths(startDate, i * frequency);
        plannedDate = adjustIfWeekend(plannedDate);

        // Vérifier si jour férié et décaler si nécessaire
        final holidays = getHolidaysForYear(plannedDate.year);
        while (holidays.values.any(
          (h) =>
              h.year == plannedDate.year &&
              h.month == plannedDate.month &&
              h.day == plannedDate.day,
        )) {
          plannedDate = plannedDate.add(const Duration(days: 1));
        }

        dates.add(plannedDate);
      }
    }

    return dates;
  }

  /// Ajoute un nombre de mois à une date
  static DateTime _addMonths(DateTime date, int months) {
    final month = date.month - 1 + months;
    final year = date.year + (month ~/ 12);
    final newMonth = (month % 12) + 1;

    // Gérer le dernier jour du mois
    final daysInMonth = DateTime(year, newMonth + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;

    return DateTime(year, newMonth, day);
  }

  /// Génère les détails du planning en fonction de la redondance
  ///
  /// Paramètres:
  /// - dateDebut: Date de début du traitement
  /// - dureeTraitement: Durée totale du traitement en mois
  /// - redondance: Fréquence d'exécution en mois (1 = chaque mois, 2 = tous les 2 mois, etc.)
  ///              ⚠️ redondance = 0 = UNE SEULE FOIS (pas une récurrence)
  ///
  /// Retourne une liste de dates planifiées, en ajustant si nécessaire pour les weekends/jours fériés
  static List<DateTime> generatePlanningDates({
    required DateTime dateDebut,
    required int dureeTraitement,
    required int redondance,
  }) {
    final dates = <DateTime>[];

    // Vérifier les paramètres
    if (dureeTraitement <= 0) {
      return dates;
    }

    // ✅ CAS SPÉCIAL: redondance = 0 = UNE SEULE FOIS
    if (redondance == 0) {
      var singleDate = adjustIfWeekendAndHoliday(dateDebut);
      dates.add(singleDate);
      return dates;
    }

    if (redondance <= 0) {
      return dates;
    }

    // Calculer la date de fin basée sur la durée du traitement
    // Pour 12 mois: ajouter 11 mois (janvier + 11 = décembre)
    final dateFin = _addMonths(dateDebut, dureeTraitement - 1);

    // Générer les dates de planification selon la redondance
    DateTime currentDate = dateDebut;

    while (currentDate.isBefore(dateFin)) {
      // Ajuster si weekend (dimanche) ET/OU jour férié
      var plannedDate = adjustIfWeekendAndHoliday(currentDate);

      dates.add(plannedDate);

      // Passer à la prochaine date en fonction de la redondance
      currentDate = _addMonths(currentDate, redondance);
    }

    return dates;
  }
}
