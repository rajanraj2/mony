import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/goal.dart';
import '../providers/goal_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals & Milestones'),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No goals created yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Set a goal (e.g. Vacation, Emergency Fund, House Downpayment)', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, i) => _GoalCard(goal: goals[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddGoalBottomSheet(),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = goal;
    final pct = g.progressPercentage;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    g.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                if (g.isReached)
                  const Chip(
                    label: Text('🎉 Reached!'),
                    backgroundColor: Colors.greenAccent,
                  )
                else
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  g.isReached ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved: ₹${g.currentAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Target: ₹${g.targetAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: ${DateFormat('MMM yyyy').format(g.deadline)} (${g.daysRemaining} days left)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (!g.isReached && g.requiredMonthlyContribution > 0)
                  Text(
                    '₹${g.requiredMonthlyContribution.toStringAsFixed(0)}/mo needed',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalBottomSheet extends ConsumerStatefulWidget {
  const _AddGoalBottomSheet();

  @override
  ConsumerState<_AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState extends ConsumerState<_AddGoalBottomSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 180)); // 6 months default
  String? _selectedAccountId;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountListProvider).value ?? [];

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
          Text('Create Savings Goal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Goal Name (e.g. Vacation, House)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target Amount', prefixText: '₹ ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedAccountId,
            decoration: const InputDecoration(labelText: 'Link to Savings Account (optional)', border: OutlineInputBorder()),
            items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
            onChanged: (val) => setState(() => _selectedAccountId = val),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month),
            title: const Text('Target Deadline'),
            subtitle: Text(DateFormat('MMMM yyyy').format(_deadline)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deadline,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final amount = double.tryParse(_amountController.text);
              if (name.isEmpty || amount == null || amount <= 0) return;

              final goal = Goal(
                id: const Uuid().v4(),
                name: name,
                targetAmount: amount,
                currencyCode: 'INR',
                linkedAccountId: _selectedAccountId,
                deadline: _deadline,
                createdAt: DateTime.now(),
              );

              await ref.read(goalRepositoryProvider).createGoal(goal);
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }
}
