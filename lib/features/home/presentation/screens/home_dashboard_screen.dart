import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';
import '../../../budgets/presentation/screens/budget_screen.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../sms/presentation/screens/sms_approval_queue_screen.dart';
import '../../../sms/presentation/providers/sms_providers.dart';
import '../../../portfolio/presentation/screens/portfolio_screen.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../planning/presentation/screens/wealth_planning_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _currentIndex = 0;
  bool _isPrivacyMode = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;

    final screens = [
      _DashboardView(isPrivacyMode: _isPrivacyMode, onTogglePrivacy: () => setState(() => _isPrivacyMode = !_isPrivacyMode)),
      const TransactionListScreen(),
      const BudgetScreen(),
      const PortfolioScreen(),
      const WealthPlanningScreen(),
      const AnalyticsScreen(),
    ];

    if (isDesktop || isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: isDesktop,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Transactions')),
                NavigationRailDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: Text('Budgets')),
                NavigationRailDestination(icon: Icon(Icons.trending_up_outlined), selectedIcon: Icon(Icons.trending_up), label: Text('Portfolio')),
                NavigationRailDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology), label: Text('Planning')),
                NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Analytics')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    // Phone: BottomNavigationBar
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Budgets'),
          NavigationDestination(icon: Icon(Icons.trending_up_outlined), selectedIcon: Icon(Icons.trending_up), label: 'Portfolio'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology), label: 'Planning'),
        ],
      ),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  final bool isPrivacyMode;
  final VoidCallback onTogglePrivacy;

  const _DashboardView({required this.isPrivacyMode, required this.onTogglePrivacy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(aggregateNetWorthProvider);
    final summaryAsync = ref.watch(transactionSummaryProvider);
    final accountsAsync = ref.watch(accountListProvider);
    final recentTxnsAsync = ref.watch(transactionListProvider);
    final budgetsAsync = ref.watch(budgetProgressListProvider);
    final pendingSmsAsync = ref.watch(pendingSmsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Mony', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sms_outlined),
            tooltip: 'SMS Capture Queue',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SmsApprovalQueueScreen()),
            ),
          ),
          IconButton(
            icon: Icon(isPrivacyMode ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Toggle Privacy Mode',
            onPressed: onTogglePrivacy,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionListProvider);
          ref.invalidate(accountListProvider);
          ref.invalidate(budgetProgressListProvider);
          ref.invalidate(pendingSmsListProvider);
          ref.invalidate(aggregateNetWorthProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // SMS Review Banner if pending entries exist
            pendingSmsAsync.when(
              data: (items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Card(
                  color: Colors.amber.shade50,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.sms, color: Colors.white)),
                    title: Text('${items.length} Pending Bank Transactions', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Tap to review and approve auto-captured SMS expenses'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SmsApprovalQueueScreen()),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Aggregate Net Worth Hero Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Net Worth (Cash + Assets)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    netWorthAsync.when(
                      data: (nw) => Text(
                        isPrivacyMode ? '••••••' : '₹${nw.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      loading: () => const Text('Loading...', style: TextStyle(color: Colors.white)),
                      error: (_, __) => const Text('₹0.00', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    summaryAsync.when(
                      data: (s) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatChip(label: 'Income', amount: isPrivacyMode ? '•••' : '₹${s.totalIncome.toStringAsFixed(0)}', color: Colors.greenAccent),
                          _StatChip(label: 'Expense', amount: isPrivacyMode ? '•••' : '₹${s.totalExpense.toStringAsFixed(0)}', color: Colors.redAccent),
                          _StatChip(label: 'Savings', amount: isPrivacyMode ? '•••' : '${s.savingsRate.toStringAsFixed(1)}%', color: Colors.white),
                        ],
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Budget Widget on Home Screen
            budgetsAsync.when(
              data: (progresses) {
                if (progresses.isEmpty) return const SizedBox.shrink();
                final totalBudgeted = progresses.fold(0.0, (sum, p) => sum + p.effectiveBudget);
                final totalSpent = progresses.fold(0.0, (sum, p) => sum + p.spent);
                final overallPct = totalBudgeted > 0 ? (totalSpent / totalBudgeted).clamp(0.0, 1.0) : 0.0;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monthly Budget Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${(overallPct * 100).toStringAsFixed(0)}%',
                                style: TextStyle(color: overallPct > 0.9 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: overallPct,
                            minHeight: 8,
                            valueColor: AlwaysStoppedAnimation(overallPct > 0.9 ? Colors.red : Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalSpent.toStringAsFixed(0)} of ₹${totalBudgeted.toStringAsFixed(0)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),

            // Accounts Overview Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Accounts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            accountsAsync.when(
              data: (accounts) => SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final a = accounts[i];
                    return Card(
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                            const SizedBox(height: 4),
                            Text(
                              isPrivacyMode ? '••••' : '₹${a.currentBalance.toStringAsFixed(2)}',
                              style: TextStyle(color: a.currentBalance >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 20),

            // Recent Transactions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            recentTxnsAsync.when(
              data: (txns) {
                final preview = txns.take(5).toList();
                if (preview.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No transactions yet. Tap + to begin.')),
                    ),
                  );
                }
                return Card(
                  child: Column(
                    children: preview.map((t) {
                      final isExp = t.type == TransactionType.expense;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExp ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          child: Icon(isExp ? Icons.arrow_upward : Icons.arrow_downward, color: isExp ? Colors.red : Colors.green),
                        ),
                        title: Text(t.name),
                        subtitle: Text(DateFormat('MMM d').format(t.date)),
                        trailing: Text(
                          isPrivacyMode ? '••••' : '${isExp ? '-' : '+'}₹${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isExp ? Colors.red : Colors.green),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _StatChip({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
