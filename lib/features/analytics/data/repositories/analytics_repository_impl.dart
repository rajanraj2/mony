import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final AppDatabase _db;

  AnalyticsRepositoryImpl(this._db);

  @override
  Future<List<CategorySpendShare>> getCategoryBreakdown({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? excludedCategoryIds,
  }) async {
    final query = _db.select(_db.transactionsTable)
      ..where((t) => t.type.equals('expense'));

    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate.millisecondsSinceEpoch));
    }
    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate.millisecondsSinceEpoch));
    }

    final txns = await query.get();
    final categories = await _db.select(_db.categoriesTable).get();
    final catMap = {for (var c in categories) c.id: c};

    final spendMap = <String, double>{};
    double grandTotal = 0.0;

    for (final t in txns) {
      final catId = t.categoryId ?? 'uncategorized';
      if (excludedCategoryIds != null && excludedCategoryIds.contains(catId)) {
        continue;
      }
      final current = spendMap[catId] ?? 0.0;
      spendMap[catId] = current + t.amount;
      grandTotal += t.amount;
    }

    final result = <CategorySpendShare>[];
    spendMap.forEach((catId, total) {
      final cat = catMap[catId];
      result.add(CategorySpendShare(
        categoryId: catId,
        categoryName: cat?.name ?? 'Uncategorized',
        categoryColor: cat?.color ?? 0xFF9E9E9E,
        totalSpent: total,
        percentage: grandTotal > 0 ? (total / grandTotal) : 0.0,
      ));
    });

    result.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return result;
  }

  @override
  Future<List<MonthlyTrendPoint>> getMonthlyTrends({int pastMonths = 6}) async {
    final now = DateTime.now();
    final results = <MonthlyTrendPoint>[];

    for (var i = pastMonths - 1; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthStart = targetDate.millisecondsSinceEpoch;
      final monthEnd = DateTime(targetDate.year, targetDate.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;

      final txns = await (_db.select(_db.transactionsTable)
            ..where((t) => t.date.isBiggerOrEqualValue(monthStart) & t.date.isSmallerOrEqualValue(monthEnd)))
          .get();

      double income = 0;
      double expense = 0;
      for (final t in txns) {
        if (t.type == 'income') income += t.amount;
        if (t.type == 'expense') expense += t.amount;
      }

      results.add(MonthlyTrendPoint(
        year: targetDate.year,
        month: targetDate.month,
        totalIncome: income,
        totalExpense: expense,
        netSavings: income - expense,
      ));
    }
    return results;
  }

  @override
  Future<List<DayOfWeekSpendIntensity>> getDayOfWeekHeatmap({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = _db.select(_db.transactionsTable)..where((t) => t.type.equals('expense'));
    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate.millisecondsSinceEpoch));
    }
    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate.millisecondsSinceEpoch));
    }

    final txns = await query.get();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final totals = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);

    for (final t in txns) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.date);
      final dayIndex = dt.weekday - 1; // 1..7 -> 0..6
      totals[dayIndex] += t.amount;
      counts[dayIndex]++;
    }

    return List.generate(7, (i) {
      return DayOfWeekSpendIntensity(
        dayOfWeek: i + 1,
        dayName: days[i],
        totalSpent: totals[i],
        transactionCount: counts[i],
      );
    });
  }

  @override
  Future<List<SpendingInsight>> generateInsights() async {
    final insights = <SpendingInsight>[];
    final heatmap = await getDayOfWeekHeatmap();
    final trends = await getMonthlyTrends(pastMonths: 2);

    // Heuristic 1: Weekend spike detection
    final weekendSpend = heatmap[5].totalSpent + heatmap[6].totalSpent;
    final weekdaySpend = heatmap.sublist(0, 5).fold(0.0, (s, d) => s + d.totalSpent);
    if (weekdaySpend > 0 && weekendSpend > (weekdaySpend * 0.4)) {
      insights.add(const SpendingInsight(
        id: 'weekend_spike',
        title: 'Weekend Spending Spike',
        description: 'You spend over 40% of your weekly budget on Saturdays and Sundays.',
        type: 'spike',
        severity: 2,
      ));
    }

    // Heuristic 2: Month-over-month expense increase
    if (trends.length >= 2) {
      final prev = trends[0].totalExpense;
      final curr = trends[1].totalExpense;
      if (prev > 0 && curr > prev * 1.25) {
        insights.add(SpendingInsight(
          id: 'mom_increase',
          title: 'Expenses Trending Higher',
          description: 'Your spending is currently 25% higher than the previous month.',
          type: 'pattern',
          severity: 2,
        ));
      } else if (curr < prev && curr > 0) {
        insights.add(const SpendingInsight(
          id: 'mom_decrease',
          title: 'Great Expense Discipline!',
          description: 'You are spending less compared to last month. Keep it up!',
          type: 'pattern',
          severity: 1,
        ));
      }
    }

    // Heuristic 3: Top spending day
    final topDay = heatmap.reduce((a, b) => a.totalSpent > b.totalSpent ? a : b);
    if (topDay.totalSpent > 0) {
      insights.add(SpendingInsight(
        id: 'top_day',
        title: 'Heaviest Spend Day: ${topDay.dayName}',
        description: 'You spend the most on ${topDay.dayName}s with ₹${topDay.totalSpent.toStringAsFixed(0)} logged.',
        type: 'pattern',
        severity: 1,
      ));
    }

    return insights;
  }

  @override
  Future<String> exportCsvReport({DateTime? startDate, DateTime? endDate}) async {
    final query = _db.select(_db.transactionsTable)..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(startDate.millisecondsSinceEpoch));
    }
    if (endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(endDate.millisecondsSinceEpoch));
    }

    final txns = await query.get();
    final categories = await _db.select(_db.categoriesTable).get();
    final catMap = {for (var c in categories) c.id: c.name};

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Date,Type,Amount,Currency,Name,Category,Status,Notes');

    for (final t in txns) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(t.date));
      final catName = t.categoryId != null ? (catMap[t.categoryId] ?? '') : '';
      final note = (t.description ?? '').replaceAll('"', '""');
      buffer.writeln(
        '$dateStr,${t.type},${t.amount},${t.currencyCode},"${t.name}","$catName",${t.status},"$note"',
      );
    }

    return buffer.toString();
  }
}
