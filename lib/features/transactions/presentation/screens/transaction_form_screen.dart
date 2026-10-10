import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/calculator.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? initialTransaction;

  const TransactionFormScreen({super.key, this.initialTransaction});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _personController;
  late final TextEditingController _placeController;

  TransactionType _type = TransactionType.expense;
  TransactionStatus _status = TransactionStatus.cleared;
  String? _selectedAccountId;
  String? _selectedTransferAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  double? _calculatedAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    _amountController = TextEditingController(text: init != null ? init.amount.toStringAsFixed(2) : '');
    _nameController = TextEditingController(text: init?.name ?? '');
    _descController = TextEditingController(text: init?.description ?? '');
    _personController = TextEditingController(text: init?.person ?? '');
    _placeController = TextEditingController(text: init?.place ?? '');

    if (init != null) {
      _type = init.type;
      _status = init.status;
      _selectedAccountId = init.accountId;
      _selectedTransferAccountId = init.transferAccountId;
      _selectedCategoryId = init.categoryId;
      _selectedDate = init.date;
      _calculatedAmount = init.amount;
    }

    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final val = SimpleCalculator.evaluate(_amountController.text);
    setState(() => _calculatedAmount = val);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _personController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_calculatedAmount == null || _calculatedAmount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.initialTransaction == null) {
        // Create new
        await ref.read(addTransactionUseCaseProvider).execute(
              accountId: _selectedAccountId!,
              transferAccountId: _selectedTransferAccountId,
              categoryId: _selectedCategoryId,
              amount: _calculatedAmount!,
              currencyCode: 'INR',
              type: _type,
              name: _nameController.text.trim(),
              description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
              person: _personController.text.trim().isEmpty ? null : _personController.text.trim(),
              place: _placeController.text.trim().isEmpty ? null : _placeController.text.trim(),
              date: _selectedDate,
              status: _status,
            );
      } else {
        // Update
        final updated = widget.initialTransaction!.copyWith(
          accountId: _selectedAccountId!,
          transferAccountId: _selectedTransferAccountId,
          categoryId: _selectedCategoryId,
          amount: _calculatedAmount!,
          type: _type,
          name: _nameController.text.trim(),
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          person: _personController.text.trim().isEmpty ? null : _personController.text.trim(),
          place: _placeController.text.trim().isEmpty ? null : _placeController.text.trim(),
          date: _selectedDate,
          status: _status,
        );
        await ref.read(updateTransactionUseCaseProvider).execute(updated);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountListProvider).value ?? [];
    final categories = ref.watch(categoryListProvider).value ?? [];

    // Fallback auto-select first account if not set
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    final filteredCategories = categories.where((c) {
      if (_type == TransactionType.expense) return c.type.name == 'expense';
      if (_type == TransactionType.income) return c.type.name == 'income';
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTransaction == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _submit,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Transaction Type Segmented Button
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: TransactionType.transfer, label: Text('Transfer'), icon: Icon(Icons.swap_horiz)),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() {
                _type = set.first;
                _selectedCategoryId = null; // reset category on type switch
              }),
            ),
            const SizedBox(height: 16),

            // Amount field with live calculator display
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount (calc supported: e.g. 50+20*3)',
                prefixText: '₹ ',
                suffixText: _calculatedAmount != null && _calculatedAmount != double.tryParse(_amountController.text)
                    ? '= ₹${_calculatedAmount!.toStringAsFixed(2)}'
                    : null,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Name / Merchant field with autocomplete
            Consumer(
              builder: (context, ref, _) {
                final suggestions = ref.watch(frequentNamesProvider).value ?? [];
                return Autocomplete<String>(
                  initialValue: TextEditingValue(text: _nameController.text),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                    return suggestions.where(
                      (name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                    );
                  },
                  onSelected: (selection) => _nameController.text = selection,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    controller.addListener(() => _nameController.text = controller.text);
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Payee / Merchant / Name',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Account selection dropdown
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: const InputDecoration(
                labelText: 'Account',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
              items: accounts.map((a) {
                return DropdownMenuItem(value: a.id, child: Text('${a.name} (₹${a.currentBalance.toStringAsFixed(0)})'));
              }).toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Transfer destination account if transfer type
            if (_type == TransactionType.transfer) ...[
              DropdownButtonFormField<String>(
                value: _selectedTransferAccountId,
                decoration: const InputDecoration(
                  labelText: 'Transfer To Account',
                  prefixIcon: Icon(Icons.move_to_inbox),
                  border: OutlineInputBorder(),
                ),
                items: accounts.where((a) => a.id != _selectedAccountId).map((a) {
                  return DropdownMenuItem(value: a.id, child: Text(a.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedTransferAccountId = v),
                validator: (v) => _type == TransactionType.transfer && v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
            ],

            // Category selection dropdown (for expense/income)
            if (_type != TransactionType.transfer) ...[
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: filteredCategories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 16),
            ],

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const Divider(),

            // Pending / Cleared status toggle (checkbook mode)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Status: Cleared'),
              subtitle: Text(_status == TransactionStatus.cleared ? 'Transaction is processed' : 'Pending / Uncleared'),
              value: _status == TransactionStatus.cleared,
              onChanged: (val) => setState(() {
                _status = val ? TransactionStatus.cleared : TransactionStatus.pending;
              }),
            ),
            const Divider(),

            // Optional fields (Person, Place, Notes)
            TextFormField(
              controller: _personController,
              decoration: const InputDecoration(
                labelText: 'Person (optional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(
                labelText: 'Place (optional)',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes / Description (optional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(widget.initialTransaction == null ? 'Save Transaction' : 'Update Transaction'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
