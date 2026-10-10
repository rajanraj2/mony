import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/analytics_data.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final trendsAsync = ref.watch(monthlyTrendsProvider);
    final heatmapAsync = ref.watch(dayOfWeekHeatmapProvider);
    final insightsAsync = ref.watch(spendingInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics & Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV Report',
            onPressed: () async {
              final csv = await ref.read(analyticsRepositoryProvider).exportCsvReport();
              await Share.share(csv, subject: 'Mony Financial Report.csv');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryBreakdownProvider);
          ref.invalidate(monthlyTrendsProvider);
          ref.invalidate(dayOfWeekHeatmapProvider);
          ref.invalidate(spendingInsightsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Smart Insights Section
            insightsAsync.when(
              data: (insights) {
                if (insights.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Automated Pattern Insights', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...insights.map((ins) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: ins.severity == 2
                              ? Colors.orange.shade50
                              : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          child: ListTile(
                            leading: Icon(
                              ins.severity == 2 ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
                              color: ins.severity == 2 ? Colors.orange.shade800 : Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(ins.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(ins.description),
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Category Breakdown Chart (Horizontal Bar Visualizer)
            Text('Spending by Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            breakdownAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No expense data available for breakdown')),
                    ),
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: categories.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 6,
                                        backgroundColor: Color(c.categoryColor),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(c.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Text(
                                    '₹${c.totalSpent.toStringAsFixed(0)} (${(c.percentage * 100).toStringAsFixed(1)}%)',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: c.percentage,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation(Color(c.categoryColor)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 20),

            // Monthly Trend Chart (Income vs Expense Bars)
            Text('6-Month Income vs Expense Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            trendsAsync.when(
              data: (trends) {
                if (trends.isEmpty) {
                  return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No trend data yet'))));
                }
                final maxVal = trends.fold(0.0, (m, t) => [m, t.totalIncome, t.totalExpense].reduce((a, b) => a > b ? a : b));

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: trends.map((t) {
                        final incRatio = maxVal > 0 ? (t.totalIncome / maxVal) : 0.0;
                        final expRatio = maxVal > 0 ? (t.totalExpense / maxVal) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(width: 65, child: Text(t.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Income Bar
                                    FractionallySizedBox(
                                      widthFactor: incRatio.clamp(0.02, 1.0),
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Expense Bar
                                    FractionallySizedBox(
                                      widthFactor: expRatio.clamp(0.02, 1.0),
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${t.savingsRate.toStringAsFixed(0)}% saved', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 20),

            // Day of Week Heatmap
            Text('Day-of-Week Spending Heatmap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            heatmapAsync.when(
              data: (days) {
                final maxSpend = days.fold(0.0, (m, d) => d.totalSpent > m ? d.totalSpent : m);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: days.map((d) {
                        final intensity = maxSpend > 0 ? (d.totalSpent / maxSpend) : 0.0;
                        return Column(
                          children: [
                            Text(d.dayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              width: 32,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity((intensity * 0.85) + 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '₹${(d.totalSpent / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${d.transactionCount} txns', style: TextStyle(color: Colors.grey.shade600, fontSize: 9)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
