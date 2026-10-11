import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/auth/domain/models/user_account.dart';
import 'package:mony/features/auth/data/repositories/auth_repository_impl.dart';

void main() {
  group('Auth & Account State Tests', () {
    late AuthRepositoryImpl repo;

    setUp(() {
      repo = AuthRepositoryImpl();
    });

    test('Initial user defaults to Guest mode without cloud sync', () async {
      final user = await repo.getCurrentUser();
      expect(user.isGuest, isTrue);
      expect(user.isCloudSyncEnabled, isFalse);
      expect(user.displayName, equals('Local Guest'));
    });

    test('Sign in with Email validates format and activates cloud sync flag', () async {
      final user = await repo.signInWithEmail(
        email: 'alex.finance@example.com',
        password: 'securePassword123',
      );

      expect(user.isGuest, isFalse);
      expect(user.email, equals('alex.finance@example.com'));
      expect(user.provider, equals(AuthProviderType.email));
      expect(user.isCloudSyncEnabled, isTrue);
      expect(user.lastSyncedAt, isNotNull);
    });

    test('Sign in with Google establishes linked cloud user account', () async {
      final user = await repo.signInWithGoogle();

      expect(user.isGuest, isFalse);
      expect(user.provider, equals(AuthProviderType.google));
      expect(user.isCloudSyncEnabled, isTrue);
      expect(user.lastSyncedAt, isNotNull);
    });

    test('Guest cannot trigger cloud sync without signing in', () async {
      expect(() => repo.triggerCloudSync(), throwsStateError);
    });

    test('Sign out resets state back to Guest mode safely', () async {
      await repo.signInWithGoogle();
      await repo.signOut();

      final user = await repo.getCurrentUser();
      expect(user.isGuest, isTrue);
      expect(user.isCloudSyncEnabled, isFalse);
    });
  });
}
