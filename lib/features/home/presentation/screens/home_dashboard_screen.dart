import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../settings/presentation/providers/home_tiles_provider.dart';
import '../../../../shared/widgets/mony_logo.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/providers.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../analytics/presentation/screens/calendar_heatmap_screen.dart';
import '../../../analytics/presentation/screens/reports_screen.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../budgets/presentation/screens/budget_screen.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../portfolio/presentation/screens/portfolio_screen.dart';
import '../../../sms/presentation/providers/sms_providers.dart';
import '../../../sms/presentation/screens/sms_approval_queue_screen.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/screens/search_screen.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';

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
      _DashboardView(
        isPrivacyMode: _isPrivacyMode,
        onTogglePrivacy: () => setState(() => _isPrivacyMode = !_isPrivacyMode),
      ),
      const TransactionListScreen(),
      const ReportsScreen(),
      const SearchScreen(),
      const PortfolioScreen(),
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
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Activity')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Reports')),
                NavigationRailDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: Text('Search')),
                NavigationRailDestination(icon: Icon(Icons.trending_up_outlined), selectedIcon: Icon(Icons.trending_up), label: Text('Portfolio')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.trending_up_outlined), selectedIcon: Icon(Icons.trending_up), label: 'Portfolio'),
        ],
      ),
    );
  }
}

class _DashboardView extends ConsumerStatefulWidget {
  final bool isPrivacyMode;
  final VoidCallback onTogglePrivacy;

  const _DashboardView({
    required this.isPrivacyMode,
    required this.onTogglePrivacy,
  });

  @override
  ConsumerState<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<_DashboardView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _showRollbackDialog(BuildContext context) async {
    final now = DateTime.now();
    DateTime targetDate = now.subtract(const Duration(days: 2));
    TimeOfDay targetTime = TimeOfDay.fromDateTime(targetDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: targetDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Select Rollback Target Date',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: targetTime,
      helpText: 'Select Rollback Exact Time',
    );
    if (pickedTime == null || !mounted) return;

    final targetTimestamp = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final repo = ref.read(transactionRepositoryProvider);
    final count = await repo.countTransactionsAfter(targetTimestamp);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Color(0xFFF97316)),
            SizedBox(width: 8),
            Text('Confirm Rollback'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roll back ledger to state at:', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMM d, yyyy • HH:mm').format(targetTimestamp),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$count transactions recorded after this timestamp will be permanently deleted.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFF87171), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Confirm & Roll Back'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final removed = await repo.rollbackToTimestamp(targetTimestamp);
      ref.invalidate(transactionListProvider);
      ref.invalidate(accountListProvider);
      ref.invalidate(transactionSummaryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            content: Text('Successfully rolled back $removed transactions to ${DateFormat("MMM d, HH:mm").format(targetTimestamp)}.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final netWorthAsync = ref.watch(aggregateNetWorthProvider);
    final summaryAsync = ref.watch(transactionSummaryProvider);
    final accountsAsync = ref.watch(accountListProvider);
    final pendingSmsAsync = ref.watch(pendingSmsListProvider);
    final tilesConfig = ref.watch(homeTilesConfigProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const MonyLogo(size: 28, showText: true, fontSize: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Transactions',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Time-Machine Rollback',
            onPressed: () => _showRollbackDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.sms_outlined),
            tooltip: 'SMS Capture Queue',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SmsApprovalQueueScreen()),
            ),
          ),
          IconButton(
            icon: Icon(widget.isPrivacyMode ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Toggle Privacy Mode',
            onPressed: widget.onTogglePrivacy,
          ),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFF48C6A).withOpacity(0.2),
                child: const Text(
                  'Z',
                  style: TextStyle(
                    color: Color(0xFFF48C6A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. ANIMATED AMBIENT GLOW ORBS IN BACKGROUND
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final val = _animController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + (val * 40),
                    right: -40 + (val * 30),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFF97316).withOpacity(0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 240 - (val * 50),
                    left: -80 + (val * 40),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80 + (val * 30),
                    right: -40,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF06B6D4).withOpacity(0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. MAIN SCROLLABLE CONTENT WITH GLASSMORPHISM
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionListProvider);
              ref.invalidate(accountListProvider);
              ref.invalidate(budgetProgressListProvider);
              ref.invalidate(pendingSmsListProvider);
              ref.invalidate(aggregateNetWorthProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
              children: [
                // Pending SMS Notification banner
                pendingSmsAsync.when(
                  data: (items) {
                    if (items.isEmpty) return const SizedBox.shrink();
                    return Card(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF59E0B),
                          child: Icon(Icons.sms, color: Colors.white, size: 20),
                        ),
                        title: Text('${items.length} Pending Bank SMS Transactions', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Tap to review and approve auto-captured SMS expenses'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SmsApprovalQueueScreen()),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // GREETING
                const Text(
                  'Good morning, Zorax',
                  style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // GLASSMORPHIC HERO NET WORTH CARD
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Net Worth (Cash + Assets)', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              Icon(
                                widget.isPrivacyMode ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white38,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          netWorthAsync.when(
                            data: (nw) => Text(
                              widget.isPrivacyMode ? '••••••••' : '₹${nw.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            loading: () => const Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 28)),
                            error: (_, __) => const Text('₹0.00', style: TextStyle(color: Colors.white, fontSize: 28)),
                          ),
                          const SizedBox(height: 18),
                          summaryAsync.when(
                            data: (s) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _HeroStatPill(
                                  label: 'Income',
                                  value: widget.isPrivacyMode ? '•••' : '₹${s.totalIncome.toStringAsFixed(0)}',
                                  color: const Color(0xFF4ADE80),
                                  icon: Icons.arrow_downward,
                                ),
                                _HeroStatPill(
                                  label: 'Expense',
                                  value: widget.isPrivacyMode ? '•••' : '₹${s.totalExpense.toStringAsFixed(0)}',
                                  color: const Color(0xFFF87171),
                                  icon: Icons.arrow_upward,
                                ),
                                _HeroStatPill(
                                  label: 'Savings',
                                  value: widget.isPrivacyMode ? '•••' : '${s.savingsRate.toStringAsFixed(1)}%',
                                  color: const Color(0xFF38BDF8),
                                  icon: Icons.savings_outlined,
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // MENU TILES SECTION (Controlled by Profile Settings)
                if (tilesConfig.hasAnyVisible) ...[
                  const Text(
                    'Overview & Quick Tools',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      if (tilesConfig.showQuickAnalytics)
                        _MenuTile(
                          title: 'Quick Analytics',
                          subtitle: 'Month Spending & Trends',
                          icon: Icons.bar_chart,
                          color: const Color(0xFFF97316),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                          ),
                        ),
                      if (tilesConfig.showQuickInsights)
                        _MenuTile(
                          title: 'Quick Insights',
                          subtitle: 'Savings Rate & Patterns',
                          icon: Icons.lightbulb_outline,
                          color: const Color(0xFFFBBF24),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReportsScreen()),
                          ),
                        ),
                      if (tilesConfig.showReports)
                        _MenuTile(
                          title: 'Reports & Breakdown',
                          subtitle: 'Category Shares & Filters',
                          icon: Icons.pie_chart_outline,
                          color: const Color(0xFF38BDF8),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReportsScreen()),
                          ),
                        ),
                      if (tilesConfig.showCalendarHeatmap)
                        _MenuTile(
                          title: 'Calendar Heatmap',
                          subtitle: 'Color-Coded Daily Spend',
                          icon: Icons.calendar_month,
                          color: const Color(0xFFA855F7),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CalendarHeatmapScreen()),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],

                // ACCOUNTS CAROUSEL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bank Accounts & Wallets', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TransactionListScreen()),
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                accountsAsync.when(
                  data: (accounts) => SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final a = accounts[i];
                        return Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(a.name, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Text(
                                widget.isPrivacyMode ? '••••••' : '₹${a.currentBalance.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        ),
        backgroundColor: const Color(0xFFF97316),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF8B949E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HeroStatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
