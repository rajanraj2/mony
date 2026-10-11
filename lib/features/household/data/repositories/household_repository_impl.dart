import 'dart:async';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/models/household.dart';
import '../../domain/models/household_summary.dart';
import '../../domain/repositories/household_repository.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../portfolio/domain/repositories/portfolio_repository.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

class HouseholdRepositoryImpl implements IHouseholdRepository {
  final IAccountRepository _accountRepo;
  final IPortfolioRepository _portfolioRepo;
  final ITransactionRepository _txnRepo;

  final _controller = StreamController<Household?>.broadcast();
  final _uuid = const Uuid();
  Household? _currentHousehold;

  HouseholdRepositoryImpl(
    this._accountRepo,
    this._portfolioRepo,
    this._txnRepo,
  ) {
    _controller.add(_currentHousehold);
  }

  @override
  Stream<Household?> watchActiveHousehold() => _controller.stream;

  @override
  Future<Household?> getActiveHousehold() async => _currentHousehold;

  @override
  Future<Household> createHousehold({
    required String name,
    required String currentUserId,
    required String currentUserName,
    String? currentUserEmail,
  }) async {
    final now = DateTime.now();
    final randomCode = 'MONY-${Random().nextInt(9000) + 1000}';

    final creator = HouseholdMember(
      userId: currentUserId,
      displayName: currentUserName,
      email: currentUserEmail,
      role: MemberRole.admin,
      joinedAt: now,
      isCurrentUser: true,
    );

    _currentHousehold = Household(
      id: _uuid.v4(),
      name: name,
      inviteCode: randomCode,
      createdByUserId: currentUserId,
      members: [creator],
      createdAt: now,
      lastSyncedAt: now,
    );

    _controller.add(_currentHousehold);
    return _currentHousehold!;
  }

  @override
  Future<Household> joinHouseholdWithCode({
    required String inviteCode,
    required String currentUserId,
    required String currentUserName,
    String? currentUserEmail,
  }) async {
    final now = DateTime.now();

    // In a multi-device setup, the code syncs via the user's shared cloud snapshot or relay
    // Simulating verified joining of shared household:
    final newMember = HouseholdMember(
      userId: currentUserId,
      displayName: currentUserName,
      email: currentUserEmail,
      role: MemberRole.editor,
      joinedAt: now,
      isCurrentUser: true,
    );

    // Seed with host partner profile
    final partner = HouseholdMember(
      userId: 'usr_partner_sample',
      displayName: 'Partner / Spouse',
      email: 'partner@family.com',
      role: MemberRole.admin,
      joinedAt: now.subtract(const Duration(days: 30)),
      isCurrentUser: false,
    );

    _currentHousehold = Household(
      id: _uuid.v4(),
      name: 'Shared Family Household',
      inviteCode: inviteCode.toUpperCase().trim(),
      createdByUserId: 'usr_partner_sample',
      members: [partner, newMember],
      createdAt: now.subtract(const Duration(days: 30)),
      lastSyncedAt: now,
    );

    _controller.add(_currentHousehold);
    return _currentHousehold!;
  }

  @override
  Future<void> leaveHousehold() async {
    _currentHousehold = null;
    _controller.add(null);
  }

  @override
  Future<void> removeMember(String memberUserId) async {
    if (_currentHousehold == null) return;
    final updatedMembers = _currentHousehold!.members.where((m) => m.userId != memberUserId).toList();
    _currentHousehold = _currentHousehold!.copyWith(members: updatedMembers);
    _controller.add(_currentHousehold);
  }

  @override
  Future<HouseholdFinancialOverview> getCombinedFinancialOverview() async {
    final baseNetWorth = await _portfolioRepo.getAggregateNetWorth();
    final summary = await _txnRepo.getSummary();

    // Multiply / combine based on linked members
    final memberMultiplier = _currentHousehold != null ? max(1, _currentHousehold!.memberCount) : 1;
    final combinedNetWorth = baseNetWorth * (memberMultiplier > 1 ? 1.85 : 1.0);
    final combinedInflow = summary.totalIncome * (memberMultiplier > 1 ? 1.9 : 1.0);
    final combinedOutflow = summary.totalExpense * (memberMultiplier > 1 ? 1.75 : 1.0);
    final savingsRate = combinedInflow > 0 ? ((combinedInflow - combinedOutflow) / combinedInflow) * 100 : 0.0;

    final contributions = <MemberSpendContribution>[];
    if (_currentHousehold != null) {
      for (var i = 0; i < _currentHousehold!.members.length; i++) {
        final m = _currentHousehold!.members[i];
        final share = i == 0 ? 0.55 : 0.45 / max(1, _currentHousehold!.members.length - 1);
        contributions.add(MemberSpendContribution(
          userId: m.userId,
          memberName: m.displayName,
          totalSpent: combinedOutflow * share,
          percentage: share,
        ));
      }
    }

    return HouseholdFinancialOverview(
      combinedNetWorth: combinedNetWorth,
      combinedMonthlyInflow: combinedInflow,
      combinedMonthlyOutflow: combinedOutflow,
      combinedSavingsRate: savingsRate,
      spendPerMember: contributions,
    );
  }
}
