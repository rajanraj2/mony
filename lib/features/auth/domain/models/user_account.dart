enum AuthProviderType {
  guest,
  email,
  google;
}

class UserAccount {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final AuthProviderType provider;
  final DateTime? lastSyncedAt;
  final bool isCloudSyncEnabled;

  const UserAccount({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
    this.lastSyncedAt,
    this.isCloudSyncEnabled = false,
  });

  bool get isGuest => provider == AuthProviderType.guest;

  UserAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProviderType? provider,
    DateTime? lastSyncedAt,
    bool? isCloudSyncEnabled,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isCloudSyncEnabled: isCloudSyncEnabled ?? this.isCloudSyncEnabled,
    );
  }

  static const guest = UserAccount(
    id: 'guest_local_user',
    displayName: 'Local Guest',
    provider: AuthProviderType.guest,
    isCloudSyncEnabled: false,
  );
}
