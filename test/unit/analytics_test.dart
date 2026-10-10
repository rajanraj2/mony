import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/analytics/domain/models/analytics_data.dart';

void main() {
  group('Analytics Data Model Tests', () {
    test('MonthlyTrendPoint savings rate calculates correctly', () {
      final point = MonthlyTrendPoint(
        year: 2026,
        month: 10,
        totalIncome: 100000,
        totalExpense: 60000,
        netSavings: 40000,
      );

      expect(point.savingsRate, equals(40.0));
      expect(point.label, equals('2026-10'));
    });

    test('MonthlyTrendPoint handles zero income without divide-by-zero error', () {
      final point = MonthlyTrendPoint(
        year: 2026,
        month: 10,
        totalIncome: 0,
        totalExpense: 15000,
        netSavings: -15000,
      );

      expect(point.savingsRate, equals(0.0));
    });

    test('CategorySpendShare percentage holds accurate share', () {
      final share = CategorySpendShare(
        categoryId: 'cat-food',
        categoryName: 'Food & Dining',
        categoryColor: 0xFFFF5722,
        totalSpent: 12500,
        percentage: 0.25,
      );

      expect(share.percentage, equals(0.25));
      expect(share.totalSpent, equals(12500.0));
    });
  });
}
