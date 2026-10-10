import '../models/analytics_data.dart';

abstract class IAnalyticsRepository {
  Future<List<CategorySpendShare>> getCategoryBreakdown({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? excludedCategoryIds,
  });

  Future<List<MonthlyTrendPoint>> getMonthlyTrends({int pastMonths = 6});

  Future<List<DayOfWeekSpendIntensity>> getDayOfWeekHeatmap({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<SpendingInsight>> generateInsights();

  Future<String> exportCsvReport({
    DateTime? startDate,
    DateTime? endDate,
  });
}
