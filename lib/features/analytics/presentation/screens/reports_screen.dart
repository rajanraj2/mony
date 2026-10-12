import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/domain/models/category.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

enum ActiveFilterTab {
  include,
  exclude;

  String get displayName => this == ActiveFilterTab.include ? 'Include (+)' : 'Exclude (−)';
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _selectedYear = DateTime.now().year; // null = all years
  int? _selectedMonth = DateTime.now().month; // null = all months
  ActiveFilterTab _activeTab = ActiveFilterTab.include;

  // Simultaneous Include and Exclude Sets
  final Set<String> _includedCategoryIds = {};
  final Set<String> _excludedCategoryIds = {};
  final Set<String> _includedBudgetIds = {};
  final Set<String> _excludedBudgetIds = {};
  final Set<String> _includedLabels = {};
  final Set<String> _excludedLabels = {};

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

  void _clearAllFilters() {
    setState(() {
      _includedCategoryIds.clear();
      _excludedCategoryIds.clear();
      _includedBudgetIds.clear();
      _excludedBudgetIds.clear();
      _includedLabels.clear();
      _excludedLabels.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final categories = ref.watch(categoryListProvider).value ?? [];
    final budgets = ref.watch(budgetListProvider).value ?? [];

    final hasIncluded = _includedCategoryIds.isNotEmpty ||
        _includedBudgetIds.isNotEmpty ||
        _includedLabels.isNotEmpty;
    final hasExcluded = _excludedCategoryIds.isNotEmpty ||
        _excludedBudgetIds.isNotEmpty ||
        _excludedLabels.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Category Analytics'),
        actions: [
          if (hasIncluded || hasExcluded)
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Reset All', style: TextStyle(color: Color(0xFFF87171))),
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

          // 2. SIMULTANEOUS INCLUDE AND EXCLUDE COMBINED FILTERING
          if (hasIncluded || hasExcluded) {
            filtered = filtered.where((t) {
              // A. EXCLUDE RULES: If it matches ANY excluded category, budget, or label, REJECT immediately!
              final matchesExcludedCat = t.categoryId != null && _excludedCategoryIds.contains(t.categoryId);
              final matchesExcludedBudget = budgets.any(
                  (b) => _excludedBudgetIds.contains(b.id) && b.categoryId == t.categoryId);
              final matchesExcludedLabel = t.labels.any((l) => _excludedLabels.contains(l));

              if (matchesExcludedCat || matchesExcludedBudget || matchesExcludedLabel) {
                return false;
              }

              // B. INCLUDE RULES: If inclusion filters are active, it MUST match at least one!
              if (hasIncluded) {
                final matchesIncludedCat = t.categoryId != null && _includedCategoryIds.contains(t.categoryId);
                final matchesIncludedBudget = budgets.any(
                    (b) => _includedBudgetIds.contains(b.id) && b.categoryId == t.categoryId);
                final matchesIncludedLabel = t.labels.any((l) => _includedLabels.contains(l));

                return matchesIncludedCat || matchesIncludedBudget || matchesIncludedLabel;
              }

              return true;
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

              // 2. Simultaneous Include & Exclude Filter Selector
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C2623)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Combined Filtering Engine:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        SegmentedButton<ActiveFilterTab>(
                          segments: const [
                            ButtonSegment(
                              value: ActiveFilterTab.include,
                              label: Text('Include (+)'),
                              icon: Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF4ADE80)),
                            ),
                            ButtonSegment(
                              value: ActiveFilterTab.exclude,
                              label: Text('Exclude (−)'),
                              icon: Icon(Icons.remove_circle_outline, size: 14, color: Color(0xFFF87171)),
                            ),
                          ],
                          selected: {_activeTab},
                          onSelectionChanged: (set) => setState(() => _activeTab = set.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Active Filter Summary Badge
                    Row(
                      children: [
                        _buildStatusPill(
                          label: 'Included (${_includedCategoryIds.length + _includedBudgetIds.length + _includedLabels.length})',
                          color: const Color(0xFF4ADE80),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusPill(
                          label: 'Excluded (${_excludedCategoryIds.length + _excludedBudgetIds.length + _excludedLabels.length})',
                          color: const Color(0xFFF87171),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _activeTab == ActiveFilterTab.include
                          ? 'Select categories, budgets, and labels to INCLUDE in the report:'
                          : 'Select categories, budgets, and labels to EXCLUDE from the report:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == ActiveFilterTab.include
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFF87171),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Category Chips for the Active Tab
                    _buildInteractiveChipsRow(
                      title: 'Categories',
                      items: categories.map((c) => _ChipItem(id: c.id, label: c.name, color: Color(c.color))).toList(),
                      isIncluded: (id) => _includedCategoryIds.contains(id),
                      isExcluded: (id) => _excludedCategoryIds.contains(id),
                      onToggle: (id) => _toggleCategory(id),
                    ),
                    const SizedBox(height: 10),

                    // Budgets Chips for the Active Tab
                    if (budgets.isNotEmpty) ...[
                      _buildInteractiveChipsRow(
                        title: 'Budgets',
                        items: budgets.map((b) {
                          final cat = categories.where((c) => c.id == b.categoryId).firstOrNull;
                          final name = cat != null
                              ? '${cat.name} (₹${b.amount.toStringAsFixed(0)})'
                              : 'Budget ₹${b.amount.toStringAsFixed(0)}';
                          return _ChipItem(id: b.id, label: name, color: const Color(0xFF0284C7));
                        }).toList(),
                        isIncluded: (id) => _includedBudgetIds.contains(id),
                        isExcluded: (id) => _excludedBudgetIds.contains(id),
                        onToggle: (id) => _toggleBudget(id),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Labels Chips for the Active Tab
                    _buildInteractiveChipsRow(
                      title: 'Labels & Hashtags',
                      items: _availableLabels
                          .map((l) => _ChipItem(id: l, label: l, color: const Color(0xFF8B5CF6)))
                          .toList(),
                      isIncluded: (id) => _includedLabels.contains(id),
                      isExcluded: (id) => _excludedLabels.contains(id),
                      onToggle: (id) => _toggleLabel(id),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Report Overview Summary Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2C2623)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Report Total Spending', style: TextStyle(color: Color(0xFF8B949E), fontSize: 13)),
                        Text(
                          '₹${totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFF2C2623)),
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

              // 4. Category Share Breakdown
              const Text('Category Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),

              if (catSpendMap.isEmpty)
                Card(
                  color: const Color(0xFF1E1A18),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No expense data matching current combined filters')),
                  ),
                )
              else
                Card(
                  color: const Color(0xFF1E1A18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF2C2623)),
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
                                  backgroundColor: const Color(0xFF131110),
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

  void _toggleCategory(String id) {
    setState(() {
      if (_activeTab == ActiveFilterTab.include) {
        if (_includedCategoryIds.contains(id)) {
          _includedCategoryIds.remove(id);
        } else {
          _includedCategoryIds.add(id);
          _excludedCategoryIds.remove(id);
        }
      } else {
        if (_excludedCategoryIds.contains(id)) {
          _excludedCategoryIds.remove(id);
        } else {
          _excludedCategoryIds.add(id);
          _includedCategoryIds.remove(id);
        }
      }
    });
  }

  void _toggleBudget(String id) {
    setState(() {
      if (_activeTab == ActiveFilterTab.include) {
        if (_includedBudgetIds.contains(id)) {
          _includedBudgetIds.remove(id);
        } else {
          _includedBudgetIds.add(id);
          _excludedBudgetIds.remove(id);
        }
      } else {
        if (_excludedBudgetIds.contains(id)) {
          _excludedBudgetIds.remove(id);
        } else {
          _excludedBudgetIds.add(id);
          _includedBudgetIds.remove(id);
        }
      }
    });
  }

  void _toggleLabel(String label) {
    setState(() {
      if (_activeTab == ActiveFilterTab.include) {
        if (_includedLabels.contains(label)) {
          _includedLabels.remove(label);
        } else {
          _includedLabels.add(label);
          _excludedLabels.remove(label);
        }
      } else {
        if (_excludedLabels.contains(label)) {
          _excludedLabels.remove(label);
        } else {
          _excludedLabels.add(label);
          _includedLabels.remove(label);
        }
      }
    });
  }

  Widget _buildStatusPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
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
      selectedColor: const Color(0xFFF48C6A),
      backgroundColor: const Color(0xFF1E1A18),
      showCheckmark: false,
    );
  }

  Widget _buildInteractiveChipsRow({
    required String title,
    required List<_ChipItem> items,
    required bool Function(String id) isIncluded,
    required bool Function(String id) isExcluded,
    required Function(String id) onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60)),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final inc = isIncluded(item.id);
              final exc = isExcluded(item.id);

              Color chipColor = const Color(0xFF26211E);
              Color textColor = Colors.white70;
              String prefix = '';

              if (inc) {
                chipColor = const Color(0xFF4ADE80).withOpacity(0.25);
                textColor = const Color(0xFF4ADE80);
                prefix = '+ ';
              } else if (exc) {
                chipColor = const Color(0xFFF87171).withOpacity(0.25);
                textColor = const Color(0xFFF87171);
                prefix = '− ';
              }

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: inc || exc,
                  label: Text(
                    '$prefix${item.label}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: (inc || exc) ? FontWeight.bold : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                  selectedColor: chipColor,
                  backgroundColor: const Color(0xFF26211E),
                  checkmarkColor: inc ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                  showCheckmark: inc || exc,
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
