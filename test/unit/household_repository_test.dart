import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mony/core/database/database.dart';
import 'package:mony/features/accounts/data/datasources/account_dao.dart';
import 'package:mony/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:mony/features/household/data/repositories/household_repository_impl.dart';
import 'package:mony/features/household/domain/models/household.dart';
import 'package:mony/features/portfolio/data/datasources/asset_dao.dart';
import 'package:mony/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:mony/features/transactions/data/datasources/transaction_dao.dart';
import 'package:mony/features/transactions/data/repositories/transaction_repository_impl.dart';

void main() {
  group('Multi-User Household & Family Sync Tests', () {
    late AppDatabase db;
    late HouseholdRepositoryImpl repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final accountDao = AccountDao(db);
      final assetDao = AssetDao(db);
      final txnDao = TransactionDao(db);

      final accountRepo = AccountRepositoryImpl(accountDao);
      final portfolioRepo = PortfolioRepositoryImpl(assetDao, accountDao);
      final txnRepo = TransactionRepositoryImpl(txnDao);

      repo = HouseholdRepositoryImpl(accountRepo, portfolioRepo, txnRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial active household is null (individual mode)', () async {
      final household = await repo.getActiveHousehold();
      expect(household, isNull);
    });

    test('Creating a household generates invite code and creator as Admin', () async {
      final household = await repo.createHousehold(
        name: 'Sharma Family',
        currentUserId: 'usr_rahul',
        currentUserName: 'Rahul Sharma',
        currentUserEmail: 'rahul@example.com',
      );

      expect(household.name, equals('Sharma Family'));
      expect(household.inviteCode, startsWith('MONY-'));
      expect(household.memberCount, equals(1));
      expect(household.members.first.role, equals(MemberRole.admin));
      expect(household.members.first.isCurrentUser, isTrue);
    });

    test('Partner joining with invite code creates multi-member household', () async {
      final joined = await repo.joinHouseholdWithCode(
        inviteCode: 'MONY-4921',
        currentUserId: 'usr_priya',
        currentUserName: 'Priya Sharma',
        currentUserEmail: 'priya@example.com',
      );

      expect(joined.memberCount, equals(2));
      expect(joined.members.any((m) => m.displayName == 'Priya Sharma'), isTrue);
      expect(joined.members.any((m) => m.displayName.contains('Partner')), isTrue);
    });

    test('Leaving household resets active session back to individual mode', () async {
      await repo.createHousehold(
        name: 'Alex & Taylor',
        currentUserId: 'usr_1',
        currentUserName: 'Alex',
      );

      await repo.leaveHousehold();
      final current = await repo.getActiveHousehold();
      expect(current, isNull);
    });

    test('Combined financial overview calculates joint metrics across members', () async {
      await repo.joinHouseholdWithCode(
        inviteCode: 'MONY-1234',
        currentUserId: 'usr_member',
        currentUserName: 'Member Two',
      );

      final overview = await repo.getCombinedFinancialOverview();
      expect(overview.spendPerMember.length, equals(2));
      expect(overview.combinedNetWorth, greaterThanOrEqualTo(0));
    });
  });
}
