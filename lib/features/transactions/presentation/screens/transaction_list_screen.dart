import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_providers.dart';
import 'transaction_form_screen.dart';
import '../../../import/presentation/screens/csv_import_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final filter = ref.watch(transactionFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Time-Machine Rollback',
            onPressed: () => _showRollbackDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import & Reconcile Bank CSV',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CsvImportScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              hintText: 'Search merchant or notes...',
              leading: const Icon(Icons.search),
              trailing: filter.searchQuery != null
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(transactionFilterProvider.notifier).setSearchQuery(null),
                      )
                    ]
                  : null,
              onChanged: (val) => ref.read(transactionFilterProvider.notifier).setSearchQuery(val.isEmpty ? null : val),
            ),
          ),
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No transactions found', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap + to record or import a bank statement', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          // Group transactions by date
          final grouped = <DateTime, List<Transaction>>{};
          for (final t in transactions) {
            final day = DateTime(t.date.year, t.date.month, t.date.day);
            grouped.putIfAbsent(day, () => []).add(t);
          }

          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, dateIndex) {
              final date = dates[dateIndex];
              final dayTxns = grouped[date]!;
              final dayTotal = dayTxns.fold(0.0, (sum, t) {
                if (t.type == TransactionType.expense) return sum - t.amount;
                if (t.type == TransactionType.income) return sum + t.amount;
                return sum;
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDateHeader(date),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${dayTotal >= 0 ? '+' : ''}₹${dayTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: dayTotal >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Transaction Cards
                  ...dayTxns.map((t) => _TransactionTile(transaction: t)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Future<void> _showRollbackDialog(BuildContext context, WidgetRef ref) async {
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
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: targetTime,
      helpText: 'Select Rollback Exact Time',
    );
    if (pickedTime == null || !context.mounted) return;

    final targetTimestamp = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final repo = ref.read(transactionRepositoryProvider);
    final count = await repo.countTransactionsAfter(targetTimestamp);

    if (!context.mounted) return;

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
            Text(
              'Roll back ledger to state at:',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            content: Text('Successfully rolled back $removed transactions to ${DateFormat("MMM d, HH:mm").format(targetTimestamp)}.'),
          ),
        );
      }
    }
  }

  String _formatDateHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy').format(d);
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final isExpense = t.type == TransactionType.expense;
    final isIncome = t.type == TransactionType.income;

    return Dismissible(
      key: Key(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Transaction?'),
            content: Text('Are you sure you want to delete "${t.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(deleteTransactionUseCaseProvider).execute(t.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense
              ? Colors.red.withOpacity(0.1)
              : isIncome
                  ? Colors.green.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
          child: Icon(
            isExpense
                ? Icons.arrow_upward
                : isIncome
                    ? Icons.arrow_downward
                    : Icons.swap_horiz,
            color: isExpense
                ? Colors.red
                : isIncome
                    ? Colors.green
                    : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (t.labels.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.labels.first,
                  style: const TextStyle(fontSize: 10, color: Color(0xFFA78BFA), fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(
          [
            DateFormat('HH:mm').format(t.date),
            if (t.status == TransactionStatus.pending) '⏳ Pending',
            if (t.person != null) 'With ${t.person}',
            if (t.place != null) '@ ${t.place}',
            if (t.description != null) t.description,
          ].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${isExpense ? '-' : isIncome ? '+' : ''}₹${t.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isExpense
                ? Colors.red
                : isIncome
                    ? Colors.green
                    : Colors.blue,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TransactionFormScreen(initialTransaction: t)),
        ),
      ),
    );
  }
}
