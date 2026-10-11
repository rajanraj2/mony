import '../models/user_account.dart';

abstract class IAuthRepository {
  Stream<UserAccount> watchCurrentUser();
  Future<UserAccount> getCurrentUser();

  Future<UserAccount> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserAccount> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserAccount> signInWithGoogle();

  Future<void> signOut();

  Future<DateTime?> triggerCloudSync();
}
