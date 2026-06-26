import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/utils/date_utils.dart' as date_utils;

void main() {
  group('DateUtils - Madagascar Holidays & Adjustments', () {
    test('isHoliday identifie correctement les jours fériés fixes', () {
      final christmas = DateTime(2024, 12, 25);
      final nationalDay = DateTime(2024, 6, 26);
      final randomDay = DateTime(2024, 7, 15);

      expect(date_utils.DateUtils.isHoliday(christmas), isTrue);
      expect(date_utils.DateUtils.isHoliday(nationalDay), isTrue);
      expect(date_utils.DateUtils.isHoliday(randomDay), isFalse);
    });

    test('adjustIfWeekend déplace un dimanche au lundi suivant', () {
      // 19 Mai 2024 est un dimanche
      final sunday = DateTime(2024, 5, 19);
      final adjusted = date_utils.DateUtils.adjustIfWeekend(sunday);

      expect(adjusted.weekday, equals(DateTime.monday));
      expect(adjusted.day, equals(20));
    });

    test('adjustIfWeekendAndHoliday gère les collisions complexes', () {
      // Si une date tombe un dimanche et que le lundi est férié
      // Exemple théorique : dimanche 25 juin (le 26 juin est férié à Mada)
      final sunday25 = DateTime(2023, 6, 25); 
      final adjusted = date_utils.DateUtils.adjustIfWeekendAndHoliday(sunday25);

      // Devrait être décalé au 27 juin (car 25=Dimanche, 26=Férié)
      expect(adjusted.day, equals(27));
      expect(adjusted.month, equals(6));
    });
  });

  group('DateUtils - Planning Generation', () {
    test('generatePlanningDates génère le bon nombre de dates pour un contrat mensuel', () {
      final start = DateTime(2024, 1, 1);
      final dates = date_utils.DateUtils.generatePlanningDates(
        dateDebut: start,
        dureeTraitement: 12,
        redondance: 1,
      );

      expect(dates.length, equals(12));
      expect(dates.first.month, equals(1));
      expect(dates.last.month, equals(12));
    });

    test('generatePlanningDates respecte la redondance trimestrielle', () {
      final start = DateTime(2024, 1, 1);
      final dates = date_utils.DateUtils.generatePlanningDates(
        dateDebut: start,
        dureeTraitement: 12,
        redondance: 3,
      );

      // Janvier, Avril, Juillet, Octobre
      expect(dates.length, equals(4));
      expect(dates[1].month, equals(4));
    });

    test('generatePlanningDates avec redondance 0 (Une seule fois)', () {
      final start = DateTime(2024, 1, 1);
      final dates = date_utils.DateUtils.generatePlanningDates(
        dateDebut: start,
        dureeTraitement: 12,
        redondance: 0,
      );

      expect(dates.length, equals(1));
    });
  });
}
