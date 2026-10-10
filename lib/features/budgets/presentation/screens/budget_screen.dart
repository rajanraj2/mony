import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/budget.dart';
import '../providers/budget_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetProgressesAsync = ref.watch(budgetProgressListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Spending Limits'),
      ),
      body: budgetProgressesAsync.when(
        data: (progresses) {
          if (progresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No budgets configured', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Set spending limits for categories to stay in control', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          final totalBudgeted = progresses.fold(0.0, (sum, p) => sum + p.effectiveBudget);
          final totalSpent = progresses.fold(0.0, (sum, p) => sum + p.spent);
          final overallPercentage = totalBudgeted > 0 ? (totalSpent / totalBudgeted).clamp(0.0, 1.0) : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overall Budget Overview Card
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monthly Budget Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '${(overallPercentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: overallPercentage > 0.9 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: overallPercentage,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            overallPercentage > 0.9 ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Spent: ₹${totalSpent.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('Budget: ₹${totalBudgeted.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Individual Category Budgets
              ...progresses.map((p) => _BudgetCard(progress: p)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddBudgetBottomSheet(),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetProgress progress;

  const _BudgetCard({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = progress;
    final color = p.isOverBudget
        ? Colors.red
        : p.isNearLimit
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(p.categoryColor).withOpacity(0.15),
                  child: Icon(Icons.category, color: Color(p.categoryColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (p.rolloverAmount > 0)
                        Text('+₹${p.rolloverAmount.toStringAsFixed(0)} rollover added',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => ref.read(budgetRepositoryProvider).deleteBudget(p.budget.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (p.percentage).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${p.spent.toStringAsFixed(0)} of ₹${p.effectiveBudget.toStringAsFixed(0)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                Text(
                  p.isOverBudget
                      ? 'Over by ₹${p.overspent.toStringAsFixed(0)}'
                      : '₹${p.remaining.toStringAsFixed(0)} left',
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetBottomSheet extends ConsumerStatefulWidget {
  const _AddBudgetBottomSheet();

  @override
  ConsumerState<_AddBudgetBottomSheet> createState() => _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends ConsumerState<_AddBudgetBottomSheet> {
  final _amountController = TextEditingController();
  String? _selectedCategoryId;
  bool _rollover = false;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider).value ?? [];
    final expenseCategories = categories.where((c) => c.type.name == 'expense').toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set Spending Limit', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: expenseCategories.map((c) {
              return DropdownMenuItem(value: c.id, child: Text(c.name));
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly Limit Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Budget Rollover'),
            subtitle: const Text('Carry forward unused budget to next month'),
            value: _rollover,
            onChanged: (v) => setState(() => _rollover = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (_selectedCategoryId == null || amount == null || amount <= 0) return;

              final budget = Budget(
                id: const Uuid().v4(),
                categoryId: _selectedCategoryId!,
                amount: amount,
                period: BudgetPeriod.monthly,
                rollover: _rollover,
                createdAt: DateTime.now(),
              );

              await ref.read(budgetRepositoryProvider).createBudget(budget);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }
}
