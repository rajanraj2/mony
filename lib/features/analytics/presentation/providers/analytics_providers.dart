import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/analytics_data.dart';

final categoryBreakdownProvider = FutureProvider<List<CategorySpendShare>>((ref) {
  return ref.watch(analyticsRepositoryProvider).getCategoryBreakdown();
});

final monthlyTrendsProvider = FutureProvider<List<MonthlyTrendPoint>>((ref) {
  return ref.watch(analyticsRepositoryProvider).getMonthlyTrends(pastMonths: 6);
});

final dayOfWeekHeatmapProvider = FutureProvider<List<DayOfWeekSpendIntensity>>((ref) {
  return ref.watch(analyticsRepositoryProvider).getDayOfWeekHeatmap();
});

final spendingInsightsProvider = FutureProvider<List<SpendingInsight>>((ref) {
  return ref.watch(analyticsRepositoryProvider).generateInsights();
});
