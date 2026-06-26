import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/utils/number_formatter.dart';

void main() {
  group('NumberFormatter - Parsing', () {
    test('parseMontant gère les espaces comme séparateurs de milliers', () {
      expect(NumberFormatter.parseMontant('1 500 000'), equals(1500000));
      expect(NumberFormatter.parseMontant('50 000'), equals(50000));
    });

    test('parseMontant ignore les suffixes monétaires', () {
      expect(NumberFormatter.parseMontant('50 000 Ar'), equals(50000));
      expect(NumberFormatter.parseMontant('25000MGA'), equals(25000));
    });

    test('parseMontant retourne toujours un nombre positif (sécurité)', () {
      expect(NumberFormatter.parseMontant('-50 000'), equals(50000));
    });

    test('parseMontant retourne 0 pour les entrées invalides', () {
      expect(NumberFormatter.parseMontant(''), equals(0));
      expect(NumberFormatter.parseMontant('abc'), equals(0));
    });
  });

  group('NumberFormatter - Formatting', () {
    test('formatMontant ajoute des espaces tous les 3 chiffres', () {
      expect(NumberFormatter.formatMontant(1500000), equals('1 500 000'));
      expect(NumberFormatter.formatMontant(50000), equals('50 000'));
      expect(NumberFormatter.formatMontant(500), equals('500'));
    });

    test('formatMontant gère le zéro', () {
      expect(NumberFormatter.formatMontant(0), equals('0'));
    });
  });

  group('NumberFormatter - Validation', () {
    test('isValidMontant valide les chaînes numériques avec espaces', () {
      expect(NumberFormatter.isValidMontant('1 500 000'), isTrue);
      expect(NumberFormatter.isValidMontant('50000'), isTrue);
      expect(NumberFormatter.isValidMontant('Gratuit'), isFalse); // Retournera 0 mais n'est pas "valide" conceptuellement
    });
  });
}
