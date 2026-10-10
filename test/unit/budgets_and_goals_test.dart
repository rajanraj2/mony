import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/budgets/domain/models/budget.dart';
import 'package:mony/features/goals/domain/models/goal.dart';

void main() {
  group('BudgetProgress calculation tests', () {
    test('calculates remaining and percentage correctly', () {
      final b = Budget(
        id: 'b1',
        categoryId: 'cat-food',
        amount: 10000,
        period: BudgetPeriod.monthly,
        createdAt: DateTime.now(),
      );
      final p = BudgetProgress(
        budget: b,
        categoryName: 'Food',
        categoryColor: 0xFF000000,
        categoryIcon: 'food',
        spent: 6000,
      );

      expect(p.effectiveBudget, equals(10000.0));
      expect(p.remaining, equals(4000.0));
      expect(p.percentage, equals(0.6));
      expect(p.isOverBudget, isFalse);
      expect(p.isNearLimit, isFalse);
    });

    test('flags near limit at 80% and over budget above 100%', () {
      final b = Budget(
        id: 'b2',
        categoryId: 'cat-shopping',
        amount: 5000,
        period: BudgetPeriod.monthly,
        createdAt: DateTime.now(),
      );
      final pNear = BudgetProgress(
        budget: b,
        categoryName: 'Shopping',
        categoryColor: 0xFF000000,
        categoryIcon: 'shop',
        spent: 4200, // 84%
      );
      expect(pNear.isNearLimit, isTrue);
      expect(pNear.isOverBudget, isFalse);

      final pOver = BudgetProgress(
        budget: b,
        categoryName: 'Shopping',
        categoryColor: 0xFF000000,
        categoryIcon: 'shop',
        spent: 5500, // 110%
      );
      expect(pOver.isOverBudget, isTrue);
      expect(pOver.overspent, equals(500.0));
      expect(pOver.remaining, equals(0.0));
    });

    test('budget rollover adds unused funds to effective budget', () {
      final b = Budget(
        id: 'b3',
        categoryId: 'cat-utilities',
        amount: 4000,
        period: BudgetPeriod.monthly,
        rollover: true,
        createdAt: DateTime.now(),
      );
      final p = BudgetProgress(
        budget: b,
        categoryName: 'Utilities',
        categoryColor: 0xFF000000,
        categoryIcon: 'bolt',
        spent: 3000,
        rolloverAmount: 1200, // rolled over from last month
      );

      expect(p.effectiveBudget, equals(5200.0));
      expect(p.remaining, equals(2200.0));
    });
  });

  group('Savings Goal calculations', () {
    test('calculates progress percentage and days remaining', () {
      final deadline = DateTime.now().add(const Duration(days: 90));
      final g = Goal(
        id: 'g1',
        name: 'Japan Vacation',
        targetAmount: 200000,
        currentAmount: 150000,
        currencyCode: 'INR',
        deadline: deadline,
        createdAt: DateTime.now(),
      );

      expect(g.progressPercentage, equals(0.75));
      expect(g.isReached, isFalse);
      expect(g.daysRemaining, greaterThanOrEqualTo(89));
      expect(g.requiredMonthlyContribution, greaterThan(0));
    });

    test('flags goal reached when currentAmount meets target', () {
      final g = Goal(
        id: 'g2',
        name: 'Emergency Fund',
        targetAmount: 100000,
        currentAmount: 100000,
        currencyCode: 'INR',
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );

      expect(g.isReached, isTrue);
      expect(g.progressPercentage, equals(1.0));
      expect(g.requiredMonthlyContribution, equals(0.0));
    });
  });
}
