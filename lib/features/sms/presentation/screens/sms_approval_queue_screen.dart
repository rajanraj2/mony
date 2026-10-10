import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/providers.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/screens/transaction_form_screen.dart';
import '../../domain/models/pending_sms_transaction.dart';
import '../providers/sms_providers.dart';
import 'sms_template_builder_screen.dart';

class SmsApprovalQueueScreen extends ConsumerWidget {
  const SmsApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingSmsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Auto-Capture Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rule_folder_outlined),
            tooltip: 'Manage Bank Regex Rules',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SmsTemplateBuilderScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Simulate Incoming SMS',
            onPressed: () => _showSimulateSmsDialog(context, ref),
          ),
        ],
      ),
      body: pendingAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('Approval Queue Clean', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Incoming bank alerts will appear here for review', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => _showSimulateSmsDialog(context, ref),
                    icon: const Icon(Icons.sms),
                    label: const Text('Test Simulation'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) => _PendingSmsCard(item: items[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showSimulateSmsDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: 'Rs. 450.00 debited from HDFC Bank acct for Zomato on 10-Oct-26.',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulate Incoming Bank SMS'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Paste bank transaction SMS'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(smsRepositoryProvider).processIncomingSms(
                    sender: 'HDFCBK',
                    body: controller.text,
                  );
            },
            child: const Text('Simulate Capture'),
          ),
        ],
      ),
    );
  }
}

class _PendingSmsCard extends ConsumerWidget {
  final PendingSmsTransaction item;

  const _PendingSmsCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = item;
    final isExpense = t.direction == 'expense';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: t.duplicateFlag ? BorderSide(color: Colors.orange.shade400, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.duplicateFlag)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                child: const Text('⚠️ Potential Duplicate Detected',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    t.parsedName ?? 'Unknown Merchant',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}₹${(t.parsedAmount ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Received: ${DateFormat('MMM d, h:mm a').format(t.smsDate)} • ${t.parsedAccountHint ?? 'Bank Account'}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
              child: Text(t.rawSms, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => ref.read(smsRepositoryProvider).updatePendingStatus(t.id, PendingStatus.rejected),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () async {
                    // Convert to confirmed transaction
                    final accounts = await ref.read(accountRepositoryProvider).getAllAccounts();
                    final defaultAccount = accounts.isNotEmpty ? accounts.first.id : 'acc-primary-bank';

                    await ref.read(addTransactionUseCaseProvider).execute(
                          accountId: defaultAccount,
                          amount: t.parsedAmount ?? 0.0,
                          currencyCode: 'INR',
                          type: isExpense ? TransactionType.expense : TransactionType.income,
                          name: t.parsedName ?? 'Merchant',
                          date: t.smsDate,
                        );

                    await ref.read(smsRepositoryProvider).updatePendingStatus(t.id, PendingStatus.approved);
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
