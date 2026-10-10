import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/budget.dart' as domain;

part 'budget_dao.g.dart';

@DriftAccessor(tables: [BudgetsTable, CategoriesTable, TransactionsTable])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Stream<List<domain.Budget>> watchBudgets() {
    return select(budgetsTable).watch().map((rows) => rows.map(_mapToDomain).toList());
  }

  Future<List<domain.Budget>> getBudgets() {
    return select(budgetsTable).get().then((rows) => rows.map(_mapToDomain).toList());
  }

  Future<domain.Budget?> getBudgetById(String id) {
    return (select(budgetsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull()
        .then((r) => r != null ? _mapToDomain(r) : null);
  }

  Future<domain.Budget?> getBudgetByCategoryId(String categoryId) {
    return (select(budgetsTable)..where((t) => t.categoryId.equals(categoryId)))
        .getSingleOrNull()
        .then((r) => r != null ? _mapToDomain(r) : null);
  }

  Future<void> insertBudget(domain.Budget b) {
    return into(budgetsTable).insert(BudgetsTableCompanion(
      id: Value(b.id),
      categoryId: Value(b.categoryId),
      amount: Value(b.amount),
      period: Value(b.period.name),
      periodStart: Value(b.periodStart?.millisecondsSinceEpoch),
      periodEnd: Value(b.periodEnd?.millisecondsSinceEpoch),
      rollover: Value(b.rollover ? 1 : 0),
      createdAt: Value(b.createdAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> updateBudget(domain.Budget b) {
    return update(budgetsTable).replace(BudgetsTableCompanion(
      id: Value(b.id),
      categoryId: Value(b.categoryId),
      amount: Value(b.amount),
      period: Value(b.period.name),
      periodStart: Value(b.periodStart?.millisecondsSinceEpoch),
      periodEnd: Value(b.periodEnd?.millisecondsSinceEpoch),
      rollover: Value(b.rollover ? 1 : 0),
      createdAt: Value(b.createdAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteBudget(String id) {
    return (delete(budgetsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Calculates real-time progress for all active budgets
  Stream<List<domain.BudgetProgress>> watchBudgetProgresses() {
    return select(budgetsTable).watch().asyncMap((budgetRows) async {
      final list = <domain.BudgetProgress>[];
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;

      for (final b in budgetRows) {
        final cat = await (select(categoriesTable)..where((c) => c.id.equals(b.categoryId))).getSingleOrNull();
        if (cat == null) continue;

        // Sum expenses for this category in current month
        final txns = await (select(transactionsTable)
              ..where((t) =>
                  t.categoryId.equals(b.categoryId) &
                  t.type.equals('expense') &
                  t.date.isBiggerOrEqualValue(startOfMonth) &
                  t.date.isSmallerOrEqualValue(endOfMonth)))
            .get();

        final spent = txns.fold(0.0, (sum, t) => sum + t.amount);

        // Rollover logic: if rollover enabled, calculate unspent budget from previous month
        double rolloverAmount = 0.0;
        if (b.rollover == 1) {
          final prevMonthStart = DateTime(now.year, now.month - 1, 1).millisecondsSinceEpoch;
          final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59).millisecondsSinceEpoch;
          final prevTxns = await (select(transactionsTable)
                ..where((t) =>
                    t.categoryId.equals(b.categoryId) &
                    t.type.equals('expense') &
                    t.date.isBiggerOrEqualValue(prevMonthStart) &
                    t.date.isSmallerOrEqualValue(prevMonthEnd)))
              .get();
          final prevSpent = prevTxns.fold(0.0, (sum, t) => sum + t.amount);
          if (prevSpent < b.amount) {
            rolloverAmount = b.amount - prevSpent;
          }
        }

        list.add(domain.BudgetProgress(
          budget: _mapToDomain(b),
          categoryName: cat.name,
          categoryColor: cat.color,
          categoryIcon: cat.icon,
          spent: spent,
          rolloverAmount: rolloverAmount,
        ));
      }
      return list;
    });
  }

  domain.Budget _mapToDomain(BudgetsTableData r) {
    return domain.Budget(
      id: r.id,
      categoryId: r.categoryId,
      amount: r.amount,
      period: domain.BudgetPeriod.fromString(r.period),
      periodStart: r.periodStart != null ? DateTime.fromMillisecondsSinceEpoch(r.periodStart!) : null,
      periodEnd: r.periodEnd != null ? DateTime.fromMillisecondsSinceEpoch(r.periodEnd!) : null,
      rollover: r.rollover == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    );
  }
}
