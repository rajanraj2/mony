import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/providers.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/models/reconciliation_item.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  final _csvController = TextEditingController(
    text: '''Date,Name,Amount,Type\n2026-10-10,Amazon India,1499.00,expense\n2026-10-10,Zomato Food,450.00,expense\n2026-10-09,Monthly Salary,75000.00,income\n2026-10-08,Uber Ride,320.00,expense''',
  );

  String? _selectedAccountId;
  ReconciliationResult? _result;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountListProvider).value ?? [];
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bank CSV Import & Reconciliation')),
      body: _result == null ? _buildInputStep(accounts) : _buildDiffStep(),
    );
  }

  Widget _buildInputStep(List accounts) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Upload or Paste Bank Statement CSV',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          'Mony will match records against your ledger, identify conflicts, and prevent duplicate entries.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedAccountId,
          decoration: const InputDecoration(labelText: 'Target Account', border: OutlineInputBorder()),
          items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
          onChanged: (v) => setState(() => _selectedAccountId = v),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _csvController,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'CSV Content (Header: Date, Name, Amount, Type)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isProcessing ? null : _processAndReconcile,
          icon: _isProcessing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.compare_arrows),
          label: const Text('Run Reconciliation Diff Engine'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ],
    );
  }

  Future<void> _processAndReconcile() async {
    if (_selectedAccountId == null) return;
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(importRepositoryProvider);
      final parsed = await repo.parseRawCsv(_csvController.text);
      if (parsed.isEmpty || parsed.length < 2) {
        throw Exception('CSV must have a header and at least one row');
      }

      // Convert rows to ImportedRow models
      final rows = <ImportedRow>[];
      for (var i = 1; i < parsed.length; i++) {
        final r = parsed[i];
        if (r.length < 3) continue;

        final date = DateTime.tryParse(r[0]) ?? DateTime.now();
        final name = r[1];
        final amount = double.tryParse(r[2]) ?? 0.0;
        final type = r.length > 3 && r[3].toLowerCase() == 'income' ? TransactionType.income : TransactionType.expense;

        rows.add(ImportedRow(
          date: date,
          name: name,
          amount: amount,
          type: type,
        ));
      }

      final result = await repo.reconcileRows(
        rows: rows,
        accountId: _selectedAccountId!,
      );

      setState(() => _result = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildDiffStep() {
    final r = _result!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            tabs: [
              Tab(text: 'New (${r.newRows.length})'),
              Tab(text: 'Conflicts (${r.conflicts.length})'),
              Tab(text: 'Matched (${r.matched.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: New Rows (Ready to add)
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: r.newRows.length,
              itemBuilder: (ctx, i) {
                final item = r.newRows[i].importedRow;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.add, color: Colors.white)),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(item.date)),
                    trailing: Text('₹${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),

            // Tab 2: Conflicts (Probable duplicates / different description)
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: r.conflicts.length,
              itemBuilder: (ctx, i) {
                final c = r.conflicts[i];
                return Card(
                  color: Colors.orange.shade50,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                            const SizedBox(width: 8),
                            Text('Conflict Match Score: ${(c.matchScore * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Imported: "${c.importedRow.name}" • ₹${c.importedRow.amount.toStringAsFixed(2)}'),
                        Text('Existing: "${c.existingTransaction?.name}" • ₹${c.existingTransaction?.amount.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Tab 3: Matched (Identical records skipped)
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: r.matched.length,
              itemBuilder: (ctx, i) {
                final m = r.matched[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(m.importedRow.name),
                    subtitle: const Text('Identical to existing record — Skipped'),
                    trailing: Text('₹${m.importedRow.amount.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _result = null),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final approved = r.newRows.map((e) => e.importedRow).toList();
                    await ref.read(importRepositoryProvider).commitReconciliation(
                          approvedRows: approved,
                          accountId: _selectedAccountId!,
                          filename: 'statement_import.csv',
                          matchedCount: r.matched.length,
                          conflictsCount: r.conflicts.length,
                        );

                    ref.invalidate(transactionListProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully merged ${approved.length} transactions!')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Approve & Merge (${r.newRows.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
