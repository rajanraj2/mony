import 'dart:async';
import '../../domain/models/user_account.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final _controller = StreamController<UserAccount>.broadcast();
  UserAccount _currentUser = UserAccount.guest;

  AuthRepositoryImpl() {
    _controller.add(_currentUser);
  }

  @override
  Stream<UserAccount> watchCurrentUser() => _controller.stream;

  @override
  Future<UserAccount> getCurrentUser() async => _currentUser;

  @override
  Future<UserAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Validate email format
    if (!email.contains('@') || password.length < 6) {
      throw ArgumentError('Invalid email format or password shorter than 6 characters');
    }

    _currentUser = UserAccount(
      id: 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: email.split('@').first,
      provider: AuthProviderType.email,
      lastSyncedAt: DateTime.now(),
      isCloudSyncEnabled: true,
    );
    _controller.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserAccount> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!email.contains('@') || password.length < 6) {
      throw ArgumentError('Invalid email format or password shorter than 6 characters');
    }

    _currentUser = UserAccount(
      id: 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      provider: AuthProviderType.email,
      lastSyncedAt: DateTime.now(),
      isCloudSyncEnabled: true,
    );
    _controller.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserAccount> signInWithGoogle() async {
    // In production this delegates to GoogleSignIn / OAuth token exchange
    // Here it creates a verified cloud-linked Google account profile
    _currentUser = const UserAccount(
      id: 'goog_1092837465',
      email: 'user@gmail.com',
      displayName: 'Google User',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-user',
      provider: AuthProviderType.google,
      isCloudSyncEnabled: true,
    ).copyWith(lastSyncedAt: DateTime.now());

    _controller.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = UserAccount.guest;
    _controller.add(_currentUser);
  }

  @override
  Future<DateTime?> triggerCloudSync() async {
    if (_currentUser.isGuest) {
      throw StateError('Cannot sync cloud database as a local guest. Please sign in.');
    }
    final now = DateTime.now();
    _currentUser = _currentUser.copyWith(lastSyncedAt: now);
    _controller.add(_currentUser);
    return now;
  }
}
