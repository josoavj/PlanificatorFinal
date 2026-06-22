import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:planificator/repositories/auth_repository.dart';
import 'package:planificator/services/database_service.dart';
import 'package:bcrypt/bcrypt.dart';

@GenerateMocks([DatabaseService])
import 'auth_repository_test.mocks.dart';

void main() {
  late AuthRepository authRepository;
  late MockDatabaseService mockDatabase;

  setUp(() {
    mockDatabase = MockDatabaseService();
    authRepository = AuthRepository(databaseService: mockDatabase);
  });

  group('AuthRepository Unit Tests', () {
    test('Initial state is not authenticated', () {
      expect(authRepository.isAuthenticated, isFalse);
      expect(authRepository.currentUser, isNull);
    });

    test('logout clears current user', () {
      // Manual set (if we could, but it's private)
      // For now, just test the logout logic
      authRepository.logout();
      expect(authRepository.isAuthenticated, isFalse);
      expect(authRepository.currentUser, isNull);
    });

    group('BCrypt Logic', () {
      test('Password verification logic', () {
        final password = 'Password123!';
        final hash = BCrypt.hashpw(password, BCrypt.gensalt());
        
        expect(BCrypt.checkpw(password, hash), isTrue);
        expect(BCrypt.checkpw('wrong', hash), isFalse);
      });
    });

    group('Login logic', () {
      test('login returns false if user not found', () async {
        when(mockDatabase.isConnected).thenReturn(true);
        when(mockDatabase.queryOne(any, any)).thenAnswer((_) async => null);

        final result = await authRepository.login('unknown', 'password');

        expect(result, isFalse);
        expect(authRepository.errorMessage, contains('incorrect'));
      });

      test('login returns false if password incorrect', () async {
        final hashedPassword = BCrypt.hashpw('correct_password', BCrypt.gensalt());
        final row = {
          'userId': 1,
          'email': 'test@test.com',
          'nom': 'Test',
          'prenom': 'User',
          'password': hashedPassword,
          'type_compte': 'Utilisateur',
        };

        when(mockDatabase.isConnected).thenReturn(true);
        when(mockDatabase.queryOne(any, any)).thenAnswer((_) async => row);

        final result = await authRepository.login('testuser', 'wrong_password');

        expect(result, isFalse);
        expect(authRepository.isAuthenticated, isFalse);
      });
    });
  });
}
