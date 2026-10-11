enum MemberRole {
  admin,  // Can add/remove members, view all accounts & investments
  editor, // Can log transactions, add accounts, and split expenses
  viewer; // Read-only access to household spending and budgets

  String get displayName {
    switch (this) {
      case MemberRole.admin:
        return 'Household Admin';
      case MemberRole.editor:
        return 'Editor / Member';
      case MemberRole.viewer:
        return 'Viewer (Read-Only)';
    }
  }
}

class HouseholdMember {
  final String userId;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final MemberRole role;
  final DateTime joinedAt;
  final bool isCurrentUser;

  const HouseholdMember({
    required this.userId,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.role,
    required this.joinedAt,
    this.isCurrentUser = false,
  });

  HouseholdMember copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? photoUrl,
    MemberRole? role,
    DateTime? joinedAt,
    bool? isCurrentUser,
  }) {
    return HouseholdMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}

class Household {
  final String id;
  final String name; // e.g. "Sharma Family" or "Alex & Taylor"
  final String inviteCode; // 6-digit link code (e.g. "MONY-8491")
  final String createdByUserId;
  final List<HouseholdMember> members;
  final DateTime createdAt;
  final DateTime? lastSyncedAt;

  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdByUserId,
    required this.members,
    required this.createdAt,
    this.lastSyncedAt,
  });

  int get memberCount => members.length;

  HouseholdMember? get currentMember =>
      members.cast<HouseholdMember?>().firstWhere((m) => m?.isCurrentUser == true, orElse: () => null);

  bool get isUserAdmin => currentMember?.role == MemberRole.admin;

  Household copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdByUserId,
    List<HouseholdMember>? members,
    DateTime? createdAt,
    DateTime? lastSyncedAt,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
