import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/transaction.dart';
import '../providers/transaction_providers.dart';
import 'transaction_form_screen.dart';

enum TransactionSortOrder {
  dateNewOld,
  dateOldNew,
  amountHighLow,
  amountLowHigh;

  String get displayName {
    switch (this) {
      case TransactionSortOrder.dateNewOld:
        return 'Date (new-old)';
      case TransactionSortOrder.dateOldNew:
        return 'Date (old-new)';
      case TransactionSortOrder.amountHighLow:
        return 'Amount (high-low)';
      case TransactionSortOrder.amountLowHigh:
        return 'Amount (low-high)';
    }
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  TransactionSortOrder _sortOrder = TransactionSortOrder.dateNewOld;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final accounts = ref.watch(accountListProvider).value ?? [];
    final query = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: () {
              // Export CSV summary
              final txns = transactionsAsync.value ?? [];
              final buffer = StringBuffer('Date,Time,Payee,Type,Amount,Labels\n');
              for (final t in txns) {
                buffer.writeln('${DateFormat("yyyy-MM-dd").format(t.date)},${DateFormat("HH:mm").format(t.date)},"${t.name}",${t.type.name},${t.amount},"${t.labels.join(" ")}"');
              }
              Share.share(buffer.toString(), subject: 'Mony Transactions.csv');
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          // Fast instant filtering
          final filtered = allTransactions.where((t) {
            if (query.isEmpty) return true;
            final matchName = t.name.toLowerCase().contains(query);
            final matchDesc = t.description?.toLowerCase().contains(query) ?? false;
            final matchPerson = t.person?.toLowerCase().contains(query) ?? false;
            final matchPlace = t.place?.toLowerCase().contains(query) ?? false;
            final matchLabels = t.labels.any((l) => l.toLowerCase().contains(query));
            return matchName || matchDesc || matchPerson || matchPlace || matchLabels;
          }).toList();

          // Apply sorting
          switch (_sortOrder) {
            case TransactionSortOrder.dateNewOld:
              filtered.sort((a, b) => b.date.compareTo(a.date));
              break;
            case TransactionSortOrder.dateOldNew:
              filtered.sort((a, b) => a.date.compareTo(b.date));
              break;
            case TransactionSortOrder.amountHighLow:
              filtered.sort((a, b) => b.amount.compareTo(a.amount));
              break;
            case TransactionSortOrder.amountLowHigh:
              filtered.sort((a, b) => a.amount.compareTo(b.amount));
              break;
          }

          // Compute matching aggregates
          double totalIncome = 0;
          double totalExpense = 0;
          for (final t in filtered) {
            if (t.type == TransactionType.income) totalIncome += t.amount;
            if (t.type == TransactionType.expense) totalExpense += t.amount;
          }
          final netBalance = totalIncome - totalExpense;

          return Column(
            children: [
              // 1. Search Text Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search merchant, notes, #essential, person...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF60A5FA)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white60),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF161B22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF30363D)),
                    ),
                  ),
                ),
              ),

              // 2. Top Stats Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Income', style: TextStyle(fontSize: 11, color: Color(0xFF8B949E))),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatStat(totalIncome)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFF30363D)),
                      Column(
                        children: [
                          const Text('Expense', style: TextStyle(fontSize: 11, color: Color(0xFF8B949E))),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatStat(totalExpense)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF87171)),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFF30363D)),
                      Column(
                        children: [
                          const Text('Net Balance', style: TextStyle(fontSize: 11, color: Color(0xFF8B949E))),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatStat(netBalance)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: netBalance >= 0 ? const Color(0xFF38BDF8) : const Color(0xFFF87171),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. Count & Sort Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} transactions',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    PopupMenuButton<TransactionSortOrder>(
                      initialValue: _sortOrder,
                      onSelected: (val) => setState(() => _sortOrder = val),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E242E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _sortOrder.displayName,
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                      itemBuilder: (_) => TransactionSortOrder.values.map((s) {
                        return PopupMenuItem(
                          value: s,
                          child: Text(s.displayName),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 4. Results List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              query.isEmpty ? 'No transactions in ledger' : 'No matching transactions for "$query"',
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final t = filtered[idx];
                          final isExp = t.type == TransactionType.expense;
                          final isInc = t.type == TransactionType.income;

                          final accountName = accounts.where((a) => a.id == t.accountId).firstOrNull?.name ?? 'Account';
                          final timeStr = DateFormat('HH:mm').format(t.date);
                          final dateStr = DateFormat('MMM d').format(t.date);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            color: const Color(0xFF161B22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF21262D)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isExp
                                    ? const Color(0xFFEF4444).withOpacity(0.15)
                                    : (isInc ? const Color(0xFF22C55E).withOpacity(0.15) : const Color(0xFF38BDF8).withOpacity(0.15)),
                                child: Icon(
                                  isExp
                                      ? Icons.arrow_upward
                                      : (isInc ? Icons.arrow_downward : Icons.swap_horiz),
                                  color: isExp
                                      ? const Color(0xFFF87171)
                                      : (isInc ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8)),
                                  size: 18,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (t.labels.isNotEmpty) ...[
                                    const SizedBox(width: 6),
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
                                ],
                              ),
                              subtitle: Text(
                                '$timeStr • $dateStr • $accountName${t.description != null ? ' • ${t.description}' : ''}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF8B949E)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '${isExp ? '-' : isInc ? '+' : ''}₹${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isExp
                                      ? const Color(0xFFF87171)
                                      : (isInc ? const Color(0xFF4ADE80) : const Color(0xFF38BDF8)),
                                ),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TransactionFormScreen(initialTransaction: t)),
                              ),
                            ),
                          );
                        },
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

  String _formatStat(double amount) {
    final abs = amount.abs();
    if (abs >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (abs >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
