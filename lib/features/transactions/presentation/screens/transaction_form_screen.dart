import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/utils/calculator.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../categories/domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_template.dart';
import '../providers/template_providers.dart';
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
  String? _selectedBudgetId;
  DateTime _selectedDate = DateTime.now();
  double? _calculatedAmount;
  bool _isLoading = false;

  // Labels & Tags
  final List<String> _selectedLabels = [];
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
      _selectedLabels.addAll(init.labels);
      for (final l in init.labels) {
        if (!_availableLabels.contains(l)) {
          _availableLabels.add(l);
        }
      }
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

  void _applyTemplate(TransactionTemplate tpl) {
    setState(() {
      _type = tpl.type;
      if (tpl.amount != null) {
        _amountController.text = tpl.amount!.toStringAsFixed(2);
        _calculatedAmount = tpl.amount;
      }
      if (tpl.payeeName != null && tpl.payeeName!.isNotEmpty) {
        _nameController.text = tpl.payeeName!;
      }
      if (tpl.categoryId != null) {
        _selectedCategoryId = tpl.categoryId;
      }
      if (tpl.accountId != null) {
        _selectedAccountId = tpl.accountId;
      }
      if (tpl.budgetId != null) {
        _selectedBudgetId = tpl.budgetId;
      }
      if (tpl.description != null && tpl.description!.isNotEmpty) {
        _descController.text = tpl.description!;
      }
      _selectedLabels.clear();
      _selectedLabels.addAll(tpl.labels);
      for (final l in tpl.labels) {
        if (!_availableLabels.contains(l)) {
          _availableLabels.add(l);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: Color(tpl.color),
        content: Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Auto-populated from template: ${tpl.name}'),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCurrentAsTemplate() async {
    final nameCtrl = TextEditingController(text: _nameController.text.trim());
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Reusable Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save this transaction setup with its amount, category, and labels as a quick template.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g. Daily Metro, Starbucks, Zomato Dinner',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save Template')),
        ],
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final tpl = TransactionTemplate(
        id: const Uuid().v4(),
        name: nameCtrl.text.trim(),
        icon: _type == TransactionType.income ? 'account_balance_wallet' : 'flash_on',
        color: _type == TransactionType.income ? 0xFF2E7D32 : 0xFF2563EB,
        type: _type,
        amount: _calculatedAmount,
        categoryId: _selectedCategoryId,
        accountId: _selectedAccountId,
        budgetId: _selectedBudgetId,
        payeeName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        labels: List<String>.from(_selectedLabels),
        isPreset: false,
        createdAt: DateTime.now(),
      );

      await ref.read(templateRepositoryProvider).createTemplate(tpl);
      ref.invalidate(templateListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            content: Text('Template "${tpl.name}" saved successfully!'),
          ),
        );
      }
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Category'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Gym & Fitness, Pet Care, Books',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      final newCat = Category(
        id: const Uuid().v4(),
        name: nameCtrl.text.trim(),
        type: _type == TransactionType.income ? CategoryType.income : CategoryType.expense,
        color: 0xFF0284C7,
        icon: 'label',
        createdAt: DateTime.now(),
      );

      await ref.read(categoryRepositoryProvider).createCategory(newCat);
      ref.invalidate(categoryListProvider);
      setState(() => _selectedCategoryId = newCat.id);
    }
  }

  Future<void> _showAddTagDialog() async {
    final tagCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Label / Tag'),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Label Name',
            hintText: 'e.g. #trip2026, #taxFree, #shared',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (result == true && tagCtrl.text.trim().isNotEmpty) {
      String tag = tagCtrl.text.trim();
      if (!tag.startsWith('#')) tag = '#$tag';
      setState(() {
        if (!_availableLabels.contains(tag)) _availableLabels.add(tag);
        if (!_selectedLabels.contains(tag)) _selectedLabels.add(tag);
      });
    }
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
              labels: _selectedLabels,
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
          labels: _selectedLabels,
        );
        await ref.read(updateTransactionUseCaseProvider).execute(updated);
      }

      ref.invalidate(transactionListProvider);
      ref.invalidate(accountListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')),
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
    final budgets = ref.watch(budgetListProvider).value ?? [];
    final templates = ref.watch(templateListProvider).value ?? [];

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
            onPressed: _saveCurrentAsTemplate,
            tooltip: 'Save as Reusable Template',
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          IconButton(
            onPressed: _isLoading ? null : _submit,
            tooltip: 'Save Transaction',
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. TOP TEMPLATES CAROUSEL
            if (templates.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Templates',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  TextButton.icon(
                    onPressed: _saveCurrentAsTemplate,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Save Template', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: templates.map((tpl) {
                    final isExpense = tpl.type == TransactionType.expense;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(
                          _getIconForTemplate(tpl.icon),
                          size: 16,
                          color: Color(tpl.color),
                        ),
                        label: Text(
                          tpl.amount != null
                              ? '${tpl.name} (₹${tpl.amount!.toStringAsFixed(0)})'
                              : tpl.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFF1F242D),
                        side: BorderSide(color: Color(tpl.color).withOpacity(0.4)),
                        onPressed: () => _applyTemplate(tpl),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 2. Transaction Type Segmented Button
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

            // 3. Amount Field
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

            // 4. Payee / Merchant Field
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
            const SizedBox(height: 14),

            // 5. CATEGORY SELECTION JUST BELOW INPUT FIELDS
            if (_type != TransactionType.transfer) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category / Spend Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  TextButton.icon(
                    onPressed: _showCreateCategoryDialog,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add_circle_outline, size: 14),
                    label: const Text('Add Category', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...filteredCategories.map((c) {
                      final isSelected = _selectedCategoryId == c.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          avatar: Icon(
                            _getIconForCategory(c.icon),
                            size: 16,
                            color: isSelected ? Colors.white : Color(c.color),
                          ),
                          label: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          selectedColor: Color(c.color),
                          backgroundColor: const Color(0xFF1E242E),
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setState(() => _selectedCategoryId = val ? c.id : null);
                          },
                        ),
                      );
                    }),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: Color(0xFF60A5FA)),
                      label: const Text('New Category', style: TextStyle(fontSize: 12, color: Color(0xFF60A5FA))),
                      backgroundColor: const Color(0xFF1E242E),
                      onPressed: _showCreateCategoryDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 6. LINKED BUDGET SELECTION (FOR EXPENSES)
            if (_type == TransactionType.expense && budgets.isNotEmpty) ...[
              const Text(
                'Linked Budget',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedBudgetId == null,
                      label: const Text('No Specific Budget', style: TextStyle(fontSize: 12)),
                      selectedColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFF1E242E),
                      onSelected: (_) => setState(() => _selectedBudgetId = null),
                    ),
                    const SizedBox(width: 6),
                    ...budgets.map((b) {
                      final isSelected = _selectedBudgetId == b.id;
                      final cat = categories.where((c) => c.id == b.categoryId).firstOrNull;
                      final label = cat != null
                          ? '${cat.name} Budget (₹${b.amount.toStringAsFixed(0)})'
                          : 'Budget ₹${b.amount.toStringAsFixed(0)}';
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          avatar: const Icon(Icons.pie_chart, size: 14, color: Color(0xFF38BDF8)),
                          label: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: const Color(0xFF1E242E),
                          onSelected: (val) {
                            setState(() {
                              _selectedBudgetId = val ? b.id : null;
                              if (val && _selectedCategoryId == null) {
                                _selectedCategoryId = b.categoryId;
                              }
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 7. LABELS & TAGS MULTI-SELECT CHIPS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Labels & Tags',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                TextButton.icon(
                  onPressed: _showAddTagDialog,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.tag, size: 14),
                  label: const Text('Add Tag', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._availableLabels.map((lbl) {
                    final isSelected = _selectedLabels.contains(lbl);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          lbl,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        selectedColor: const Color(0xFF8B5CF6),
                        backgroundColor: const Color(0xFF1E242E),
                        checkmarkColor: Colors.white,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedLabels.add(lbl);
                            } else {
                              _selectedLabels.remove(lbl);
                            }
                          });
                        },
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 14, color: Color(0xFFA78BFA)),
                    label: const Text('New Tag', style: TextStyle(fontSize: 12, color: Color(0xFFA78BFA))),
                    backgroundColor: const Color(0xFF1E242E),
                    onPressed: _showAddTagDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 8. Account Selection Dropdown
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

            // Pending / Cleared status toggle
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

  IconData _getIconForTemplate(String icon) {
    switch (icon) {
      case 'local_cafe':
        return Icons.local_cafe;
      case 'directions_subway':
        return Icons.directions_subway;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'movie':
        return Icons.movie;
      case 'bolt':
        return Icons.bolt;
      case 'home':
        return Icons.home;
      case 'trending_up':
        return Icons.trending_up;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.flash_on;
    }
  }

  IconData _getIconForCategory(String icon) {
    switch (icon) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'movie':
        return Icons.movie;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt':
        return Icons.receipt;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'trending_up':
        return Icons.trending_up;
      case 'work':
        return Icons.work;
      default:
        return Icons.category;
    }
  }
}
