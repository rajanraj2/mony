import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/sms_rule.dart';
import '../providers/sms_providers.dart';

class SmsTemplateBuilderScreen extends ConsumerWidget {
  const SmsTemplateBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(smsRulesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bank Regex Rules & Templates')),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(child: Text('No active rules'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final r = rules[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: r.direction == 'expense' ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                  child: Icon(r.direction == 'expense' ? Icons.arrow_upward : Icons.arrow_downward,
                      color: r.direction == 'expense' ? Colors.red : Colors.green),
                ),
                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Sender: ${r.senderPattern}\nPattern: ${r.messagePattern}', maxLines: 2, overflow: TextOverflow.ellipsis),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(smsRepositoryProvider).deleteSmsRule(r.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRuleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final senderCtrl = TextEditingController();
    final patternCtrl = TextEditingController(
      text: r'(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:debited|spent).*?(?:at|to)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)\.',
    );
    String direction = 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Custom SMS Rule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Rule Name (e.g. Axis Bank Debit)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: senderCtrl,
                decoration: const InputDecoration(labelText: 'Sender Pattern (e.g. AXISBK)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: patternCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Regex Pattern (must include ?<amount> and ?<merchant>)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || senderCtrl.text.isEmpty || patternCtrl.text.isEmpty) return;
                  final rule = SmsRule(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    senderPattern: senderCtrl.text.trim(),
                    messagePattern: patternCtrl.text.trim(),
                    direction: direction,
                  );
                  await ref.read(smsRepositoryProvider).createSmsRule(rule);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text('Save Rule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
