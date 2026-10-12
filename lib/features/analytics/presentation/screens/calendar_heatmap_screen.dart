import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';

class CalendarHeatmapScreen extends ConsumerStatefulWidget {
  const CalendarHeatmapScreen({super.key});

  @override
  ConsumerState<CalendarHeatmapScreen> createState() => _CalendarHeatmapScreenState();
}

class _CalendarHeatmapScreenState extends ConsumerState<CalendarHeatmapScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final txnsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Heatmap'),
      ),
      body: txnsAsync.when(
        data: (transactions) {
          // Filter transactions for this month and group by day
          final monthTxns = transactions.where((t) {
            return t.date.year == _currentMonth.year && t.date.month == _currentMonth.month;
          }).toList();

          final dayData = <int, _DayAggregates>{};
          for (final t in monthTxns) {
            final day = t.date.day;
            final agg = dayData.putIfAbsent(day, () => _DayAggregates());
            if (t.type == TransactionType.expense) {
              agg.expense += t.amount;
            } else if (t.type == TransactionType.income) {
              agg.income += t.amount;
            }
            agg.txns.add(t);
          }

          final selectedDayAgg = dayData[_selectedDate.day] ?? _DayAggregates();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Month Navigator Header
              Card(
                elevation: 0,
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white70),
                        onPressed: _prevMonth,
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white70),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Calendar Grid Card
              Card(
                elevation: 0,
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Weekday Headers
                      Row(
                        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B949E),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 20, color: Color(0xFF30363D)),

                      // Days Matrix
                      _buildDaysGrid(dayData),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Selected Day Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_downward, color: Color(0xFF4ADE80), size: 14),
                              SizedBox(width: 4),
                              Text('Income', style: TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${selectedDayAgg.income.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4ADE80)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_upward, color: Color(0xFFF87171), size: 14),
                              SizedBox(width: 4),
                              Text('Expense', style: TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${selectedDayAgg.expense.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFF87171)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF38BDF8), size: 14),
                              SizedBox(width: 4),
                              Text('Net', style: TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${(selectedDayAgg.income - selectedDayAgg.expense).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: (selectedDayAgg.income - selectedDayAgg.expense) >= 0
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFFF87171),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Selected Day Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${selectedDayAgg.txns.length} Transactions',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 5. Selected Day Transactions List
              if (selectedDayAgg.txns.isEmpty)
                Card(
                  color: const Color(0xFF161B22),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No transactions recorded on this day.',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                ...selectedDayAgg.txns.map((t) {
                  final isExp = t.type == TransactionType.expense;
                  return Card(
                    color: const Color(0xFF161B22),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isExp
                            ? const Color(0xFFEF4444).withOpacity(0.15)
                            : const Color(0xFF22C55E).withOpacity(0.15),
                        child: Icon(
                          isExp ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isExp ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                          size: 18,
                        ),
                      ),
                      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(t.date)}${t.labels.isNotEmpty ? ' • ${t.labels.join(" ")}' : ''}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
                      ),
                      trailing: Text(
                        '${isExp ? '-' : '+'}₹${t.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isExp ? const Color(0xFFF87171) : const Color(0xFF4ADE80),
                        ),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TransactionFormScreen(initialTransaction: t)),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDaysGrid(Map<int, _DayAggregates> dayData) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = _currentMonth.weekday; // 1 = Mon, 7 = Sun
    final leadingBlanks = firstWeekday - 1;

    final cells = <Widget>[];

    // Leading blanks
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Days 1..daysInMonth
    for (int day = 1; day <= daysInMonth; day++) {
      final isSelected = _selectedDate.year == _currentMonth.year &&
          _selectedDate.month == _currentMonth.month &&
          _selectedDate.day == day;

      final agg = dayData[day];
      final hasExpense = agg != null && agg.expense > 0;
      final hasIncome = agg != null && agg.income > 0;

      Color badgeColor = Colors.transparent;
      String badgeText = '';

      if (hasIncome && (!hasExpense || agg.income > agg.expense)) {
        badgeColor = const Color(0xFF4ADE80);
        badgeText = '+${_formatCompactCurrency(agg.income)}';
      } else if (hasExpense) {
        badgeColor = const Color(0xFFF87171);
        badgeText = '-${_formatCompactCurrency(agg.expense)}';
      }

      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected ? const Color(0xFFF97316).withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                color: isSelected ? const Color(0xFFF97316) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                if (badgeText.isNotEmpty)
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const SizedBox(height: 11),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 0.9,
      children: cells,
    );
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}

class _DayAggregates {
  double income = 0;
  double expense = 0;
  final List<Transaction> txns = [];
}
