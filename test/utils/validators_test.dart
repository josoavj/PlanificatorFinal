import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/utils/password_validator.dart';
import 'package:planificator/utils/email_validator.dart';

void main() {
  group('PasswordValidator', () {
    group('isPasswordPersonalInfo', () {
      test('détecte le nom dans le mot de passe (insensible à la casse)', () {
        final result = PasswordValidator.isPasswordPersonalInfo(
          'dupont123',
          'Dupont',
          'Jean',
        );
        expect(result, isTrue);
      });

      test('détecte le prénom dans le mot de passe', () {
        final result = PasswordValidator.isPasswordPersonalInfo(
          'Jean@2024',
          'Dupont',
          'Jean',
        );
        expect(result, isTrue);
      });

      test('retourne false si ni nom ni prénom présent', () {
        final result = PasswordValidator.isPasswordPersonalInfo(
          'SecurePass@123',
          'Dupont',
          'Jean',
        );
        expect(result, isFalse);
      });

      test('accepte les noms/prénoms vides', () {
        final result = PasswordValidator.isPasswordPersonalInfo(
          'SecurePass@123',
          '',
          '',
        );
        expect(result, isFalse);
      });
    });

    group('validatePassword', () {
      test('rejette les mots de passe non appariés', () {
        final result = PasswordValidator.validatePassword(
          'Test@1234',
          'Test@5678',
          'Dupont',
          'Jean',
        );
        expect(result, contains('ne correspondent pas'));
      });

      test('rejette les mots de passe trop courts', () {
        final result = PasswordValidator.validatePassword(
          'Short1',
          'Short1',
          'Dupont',
          'Jean',
        );
        expect(result, contains('8 caractères'));
      });

      test('rejette si le mot de passe contient le nom', () {
        final result = PasswordValidator.validatePassword(
          'Dupont@1234',
          'Dupont@1234',
          'Dupont',
          'Jean',
        );
        expect(result, contains('nom ou prénom'));
      });

      test('rejette les mots de passe sans complexité', () {
        final result = PasswordValidator.validatePassword(
          'onlysmallletters',
          'onlysmallletters',
          'Dupont',
          'Jean',
        );
        expect(result, contains('majuscule'));
      });

      test('accepte un mot de passe valide et sécurisé', () {
        final result = PasswordValidator.validatePassword(
          'SecureP@ss123',
          'SecureP@ss123',
          'Dupont',
          'Jean',
        );
        expect(result, isEmpty);
      });

      test('valide un mot de passe avec caractères spéciaux', () {
        final result = PasswordValidator.validatePassword(
          r'MyP@ssw0rd!#$',
          r'MyP@ssw0rd!#$',
          'Dupont',
          'Jean',
        );
        expect(result, isEmpty);
      });
    });

    group('getPasswordStrength', () {
      test('donne un score bas pour les mots de passe faibles', () {
        final score = PasswordValidator.getPasswordStrength('Abc123');
        expect(score, lessThan(50));
      });

      test('donne un score élevé pour les mots de passe forts', () {
        final score = PasswordValidator.getPasswordStrength(
          'MyStr0ng!P@ssw0rd',
        );
        expect(score, greaterThanOrEqualTo(70));
      });

      test('donne un score très élevé pour les mots de passe très forts', () {
        final score = PasswordValidator.getPasswordStrength(
          r'VeryLongAndComplex!P@ssw0rd#123$%',
        );
        expect(score, greaterThanOrEqualTo(85));
      });
    });

    group('getPasswordStrengthLabel', () {
      test('retourne "Très faible" pour score < 30', () {
        final label = PasswordValidator.getPasswordStrengthLabel(20);
        expect(label, equals('Très faible'));
      });

      test('retourne "Faible" pour score 30-49', () {
        final label = PasswordValidator.getPasswordStrengthLabel(40);
        expect(label, equals('Faible'));
      });

      test('retourne "Moyen" pour score 50-69', () {
        final label = PasswordValidator.getPasswordStrengthLabel(60);
        expect(label, equals('Moyen'));
      });

      test('retourne "Fort" pour score 70-84', () {
        final label = PasswordValidator.getPasswordStrengthLabel(75);
        expect(label, equals('Fort'));
      });

      test('retourne "Très fort" pour score >= 85', () {
        final label = PasswordValidator.getPasswordStrengthLabel(90);
        expect(label, equals('Très fort'));
      });
    });
  });

  group('EmailValidator', () {
    group('isValidEmail', () {
      test('accepte les emails valides simples', () {
        expect(EmailValidator.isValidEmail('user@example.com'), isTrue);
      });

      test('accepte les emails avec sous-domaine', () {
        expect(EmailValidator.isValidEmail('user@mail.example.co.uk'), isTrue);
      });

      test('rejette les emails sans @', () {
        expect(EmailValidator.isValidEmail('userexample.com'), isFalse);
      });

      test('rejette les emails sans domaine', () {
        expect(EmailValidator.isValidEmail('user@'), isFalse);
      });

      test('rejette les emails sans point dans le domaine', () {
        expect(EmailValidator.isValidEmail('user@example'), isFalse);
      });

      test('rejette les emails vides', () {
        expect(EmailValidator.isValidEmail(''), isFalse);
      });
    });

    group('isValidEmailStrict', () {
      test('accepte les emails valides', () {
        expect(EmailValidator.isValidEmailStrict('user@example.com'), isTrue);
      });

      test('rejette les emails malformés', () {
        expect(EmailValidator.isValidEmailStrict('user@.com'), isFalse);
      });

      test('rejette les emails avec plusieurs @', () {
        expect(EmailValidator.isValidEmailStrict('user@@example.com'), isFalse);
      });
    });

    group('normalizeEmail', () {
      test('convertit en minuscules', () {
        final normalized = EmailValidator.normalizeEmail('USER@EXAMPLE.COM');
        expect(normalized, equals('user@example.com'));
      });

      test('supprime les espaces', () {
        final normalized = EmailValidator.normalizeEmail(
          '  user@example.com  ',
        );
        expect(normalized, equals('user@example.com'));
      });

      test('normalise complètement les emails', () {
        final normalized = EmailValidator.normalizeEmail(
          '  USER@EXAMPLE.COM  ',
        );
        expect(normalized, equals('user@example.com'));
      });
    });
  });
}
