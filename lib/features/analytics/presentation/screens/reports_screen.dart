import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/domain/models/category.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

enum FilterMode {
  include,
  exclude;

  String get displayName => this == FilterMode.include ? 'Include Selected' : 'Exclude Selected';
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _selectedYear = DateTime.now().year; // null = all years
  int? _selectedMonth = DateTime.now().month; // null = all months
  FilterMode _filterMode = FilterMode.include;

  final Set<String> _selectedCategoryIds = {};
  final Set<String> _selectedBudgetIds = {};
  final Set<String> _selectedLabels = {};

  final List<String> _availableLabels = [
    '#essential',
    '#discretionary',
    '#work',
    '#personal',
    '#routine',
    '#subscription',
    '#groceries',
    '#family',
    '#cash',
    '#online',
  ];

  void _clearFilters() {
    setState(() {
      _selectedCategoryIds.clear();
      _selectedBudgetIds.clear();
      _selectedLabels.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final categories = ref.watch(categoryListProvider).value ?? [];
    final budgets = ref.watch(budgetListProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Category Analytics'),
        actions: [
          if (_selectedCategoryIds.isNotEmpty || _selectedBudgetIds.isNotEmpty || _selectedLabels.isNotEmpty)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Reset', style: TextStyle(color: Color(0xFFF87171))),
            ),
        ],
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          // 1. Filter by Year & Month
          var filtered = allTransactions.where((t) {
            if (_selectedYear != null && t.date.year != _selectedYear) return false;
            if (_selectedMonth != null && t.date.month != _selectedMonth) return false;
            return true;
          }).toList();

          // 2. Filter by Categories / Budgets / Labels with Include vs Exclude Mode
          final hasCategoryFilter = _selectedCategoryIds.isNotEmpty;
          final hasBudgetFilter = _selectedBudgetIds.isNotEmpty;
          final hasLabelFilter = _selectedLabels.isNotEmpty;

          if (hasCategoryFilter || hasBudgetFilter || hasLabelFilter) {
            filtered = filtered.where((t) {
              final matchCat = t.categoryId != null && _selectedCategoryIds.contains(t.categoryId);
              // Transaction matches budget if budget is linked or its category is covered by selected budget
              final matchBudget = budgets.any((b) => _selectedBudgetIds.contains(b.id) && b.categoryId == t.categoryId);
              final matchLabel = t.labels.any((l) => _selectedLabels.contains(l));

              final matchesAnyFilter = matchCat || matchBudget || matchLabel;

              if (_filterMode == FilterMode.include) {
                return matchesAnyFilter;
              } else {
                // Exclude mode: drop transactions that match excluded criteria
                return !matchesAnyFilter;
              }
            }).toList();
          }

          // Compute report totals
          double totalExpense = 0;
          double totalIncome = 0;
          final catSpendMap = <String, double>{};
          final catCountMap = <String, int>{};

          for (final t in filtered) {
            if (t.type == TransactionType.expense) {
              totalExpense += t.amount;
              final catId = t.categoryId ?? 'uncategorized';
              catSpendMap[catId] = (catSpendMap[catId] ?? 0.0) + t.amount;
              catCountMap[catId] = (catCountMap[catId] ?? 0) + 1;
            } else if (t.type == TransactionType.income) {
              totalIncome += t.amount;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Year & Month Selectors
              _buildDateFilters(),
              const SizedBox(height: 14),

              // 2. Include / Exclude Mode Switcher
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Mode:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        SegmentedButton<FilterMode>(
                          segments: const [
                            ButtonSegment(
                              value: FilterMode.include,
                              label: Text('Include'),
                              icon: Icon(Icons.check_circle_outline, size: 16),
                            ),
                            ButtonSegment(
                              value: FilterMode.exclude,
                              label: Text('Exclude'),
                              icon: Icon(Icons.remove_circle_outline, size: 16),
                            ),
                          ],
                          selected: {_filterMode},
                          onSelectionChanged: (set) => setState(() => _filterMode = set.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _filterMode == FilterMode.include
                          ? 'Showing only transactions matching selected categories, budgets, or labels.'
                          : 'Excluding selected categories, budgets, and labels from calculations.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Category Filter Chips
              _buildFilterSection(
                title: 'Categories',
                items: categories.map((c) => _ChipItem(id: c.id, label: c.name, color: Color(c.color))).toList(),
                selectedIds: _selectedCategoryIds,
                onToggle: (id) => setState(() {
                  if (_selectedCategoryIds.contains(id)) {
                    _selectedCategoryIds.remove(id);
                  } else {
                    _selectedCategoryIds.add(id);
                  }
                }),
              ),
              const SizedBox(height: 12),

              // 4. Budgets Filter Chips
              if (budgets.isNotEmpty) ...[
                _buildFilterSection(
                  title: 'Budgets',
                  items: budgets.map((b) {
                    final cat = categories.where((c) => c.id == b.categoryId).firstOrNull;
                    final name = cat != null ? '${cat.name} (₹${b.amount.toStringAsFixed(0)})' : 'Budget ₹${b.amount.toStringAsFixed(0)}';
                    return _ChipItem(id: b.id, label: name, color: const Color(0xFF0284C7));
                  }).toList(),
                  selectedIds: _selectedBudgetIds,
                  onToggle: (id) => setState(() {
                    if (_selectedBudgetIds.contains(id)) {
                      _selectedBudgetIds.remove(id);
                    } else {
                      _selectedBudgetIds.add(id);
                    }
                  }),
                ),
                const SizedBox(height: 12),
              ],

              // 5. Labels & Tags Filter Chips
              _buildFilterSection(
                title: 'Labels & Tags',
                items: _availableLabels.map((l) => _ChipItem(id: l, label: l, color: const Color(0xFF8B5CF6))).toList(),
                selectedIds: _selectedLabels,
                onToggle: (id) => setState(() {
                  if (_selectedLabels.contains(id)) {
                    _selectedLabels.remove(id);
                  } else {
                    _selectedLabels.add(id);
                  }
                }),
              ),
              const SizedBox(height: 18),

              // 6. Report Overview Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Report Total Spending', style: TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
                        Text(
                          '₹${totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFF30363D)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Income', style: TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                            Text('₹${totalIncome.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Matching Txns', style: TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                            Text('${filtered.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Savings Rate', style: TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
                            Text(
                              totalIncome > 0 ? '${(((totalIncome - totalExpense) / totalIncome) * 100).toStringAsFixed(1)}%' : '0%',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 7. Category Share Breakdown
              const Text('Category Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),

              if (catSpendMap.isEmpty)
                Card(
                  color: const Color(0xFF161B22),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No expense data matching current filters')),
                  ),
                )
              else
                Card(
                  color: const Color(0xFF161B22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: catSpendMap.entries.map((entry) {
                        final catId = entry.key;
                        final amount = entry.value;
                        final count = catCountMap[catId] ?? 0;
                        final pct = totalExpense > 0 ? (amount / totalExpense) : 0.0;
                        final cat = categories.where((c) => c.id == catId).firstOrNull;
                        final name = cat?.name ?? 'Other / General';
                        final color = cat != null ? Color(cat.color) : const Color(0xFF94A3B8);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(radius: 6, backgroundColor: color),
                                      const SizedBox(width: 8),
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                                      const SizedBox(width: 6),
                                      Text('($count txns)', style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E))),
                                    ],
                                  ),
                                  Text(
                                    '₹${amount.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFF0D1117),
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year Pills
        Row(
          children: [
            const Text('Year:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(width: 8),
            _buildChoiceChip('All', _selectedYear == null, () => setState(() => _selectedYear = null)),
            const SizedBox(width: 6),
            _buildChoiceChip('2026', _selectedYear == 2026, () => setState(() => _selectedYear = 2026)),
            const SizedBox(width: 6),
            _buildChoiceChip('2025', _selectedYear == 2025, () => setState(() => _selectedYear = 2025)),
          ],
        ),
        const SizedBox(height: 10),

        // Month Carousel
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChoiceChip('All Months', _selectedMonth == null, () => setState(() => _selectedMonth = null)),
              const SizedBox(width: 6),
              ...List.generate(12, (i) {
                final m = i + 1;
                final monthName = DateFormat('MMM').format(DateTime(2026, m, 1));
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _buildChoiceChip(monthName, _selectedMonth == m, () => setState(() => _selectedMonth = m)),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFF97316),
      backgroundColor: const Color(0xFF1E242E),
      showCheckmark: false,
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<_ChipItem> items,
    required Set<String> selectedIds,
    required Function(String) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final isSelected = selectedIds.contains(item.id);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  selectedColor: item.color,
                  backgroundColor: const Color(0xFF1E242E),
                  checkmarkColor: Colors.white,
                  onSelected: (_) => onToggle(item.id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ChipItem {
  final String id;
  final String label;
  final Color color;

  const _ChipItem({required this.id, required this.label, required this.color});
}
