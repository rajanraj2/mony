class CategorySpendShare {
  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final double totalSpent;
  final double percentage; // 0.0 to 1.0

  const CategorySpendShare({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.totalSpent,
    required this.percentage,
  });
}

class MonthlyTrendPoint {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netSavings;

  const MonthlyTrendPoint({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
  });

  double get savingsRate =>
      totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome).clamp(0.0, 1.0) * 100 : 0.0;
  
  String get label => '$year-${month.toString().padLeft(2, '0')}';
}

class DayOfWeekSpendIntensity {
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String dayName;
  final double totalSpent;
  final int transactionCount;

  const DayOfWeekSpendIntensity({
    required this.dayOfWeek,
    required this.dayName,
    required this.totalSpent,
    required this.transactionCount,
  });
}

class SpendingInsight {
  final String id;
  final String title;
  final String description;
  final String type; // pattern, spike, anomaly, forecast
  final int severity; // 1 = info, 2 = warning, 3 = alert

  const SpendingInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.severity = 1,
  });
}
