import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/goal.dart' as domain;

part 'goal_dao.g.dart';

@DriftAccessor(tables: [GoalsTable, AccountsTable, TransactionsTable])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Stream<List<domain.Goal>> watchGoals() {
    return select(goalsTable).watch().asyncMap((rows) async {
      final list = <domain.Goal>[];
      for (final r in rows) {
        final currentAmount = await _calculateGoalBalance(r.id, r.linkedAccountId);
        list.add(_mapToDomain(r, currentAmount));
      }
      return list;
    });
  }

  Future<List<domain.Goal>> getGoals() async {
    final rows = await select(goalsTable).get();
    final list = <domain.Goal>[];
    for (final r in rows) {
      final currentAmount = await _calculateGoalBalance(r.id, r.linkedAccountId);
      list.add(_mapToDomain(r, currentAmount));
    }
    return list;
  }

  Future<domain.Goal?> getGoalById(String id) async {
    final r = await (select(goalsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (r == null) return null;
    final currentAmount = await _calculateGoalBalance(r.id, r.linkedAccountId);
    return _mapToDomain(r, currentAmount);
  }

  Future<void> insertGoal(domain.Goal g) {
    return into(goalsTable).insert(GoalsTableCompanion(
      id: Value(g.id),
      name: Value(g.name),
      targetAmount: Value(g.targetAmount),
      currencyCode: Value(g.currencyCode),
      linkedAccountId: Value(g.linkedAccountId),
      deadline: Value(g.deadline.millisecondsSinceEpoch),
      createdAt: Value(g.createdAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> updateGoal(domain.Goal g) {
    return update(goalsTable).replace(GoalsTableCompanion(
      id: Value(g.id),
      name: Value(g.name),
      targetAmount: Value(g.targetAmount),
      currencyCode: Value(g.currencyCode),
      linkedAccountId: Value(g.linkedAccountId),
      deadline: Value(g.deadline.millisecondsSinceEpoch),
      createdAt: Value(g.createdAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteGoal(String id) {
    return (delete(goalsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<double> _calculateGoalBalance(String goalId, String? linkedAccountId) async {
    // If goal is linked to an account, calculate the account's current balance
    if (linkedAccountId != null) {
      final acc = await (select(accountsTable)..where((a) => a.id.equals(linkedAccountId))).getSingleOrNull();
      if (acc != null) {
        final txns = await (select(transactionsTable)
              ..where((t) => t.accountId.equals(linkedAccountId) | t.transferAccountId.equals(linkedAccountId)))
            .get();
        double balance = acc.openingBalance;
        for (final t in txns) {
          if (t.accountId == linkedAccountId) {
            if (t.type == 'income') balance += t.amount;
            if (t.type == 'expense') balance -= t.amount;
            if (t.type == 'transfer') balance -= t.amount;
          }
          if (t.transferAccountId == linkedAccountId && t.type == 'transfer') {
            balance += t.amount;
          }
        }
        return balance.clamp(0.0, double.infinity);
      }
    }
    // Alternatively sum transactions explicitly labeled or referencing this goal
    final goalTxns = await (select(transactionsTable)..where((t) => t.labels.like('%goal:$goalId%'))).get();
    return goalTxns.fold(0.0, (sum, t) => sum + t.amount);
  }

  domain.Goal _mapToDomain(GoalsTableData r, double currentAmount) {
    return domain.Goal(
      id: r.id,
      name: r.name,
      targetAmount: r.targetAmount,
      currentAmount: currentAmount,
      currencyCode: r.currencyCode,
      linkedAccountId: r.linkedAccountId,
      deadline: DateTime.fromMillisecondsSinceEpoch(r.deadline),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    );
  }
}
