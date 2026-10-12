import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_filter.dart';

// Current active filter state
class TransactionFilterNotifier extends StateNotifier<TransactionFilter> {
  TransactionFilterNotifier() : super(const TransactionFilter());

  void setFilter(TransactionFilter filter) => state = filter;
  void clearFilter() => state = const TransactionFilter();
  void setSearchQuery(String? q) => state = state.copyWith(searchQuery: q);
  void setAccountId(String? id) => state = state.copyWith(accountId: id);
  void setCategoryId(String? id) => state = state.copyWith(categoryId: id);
  void setType(TransactionType? type) => state = state.copyWith(type: type);
  void setDateRange(DateTime? start, DateTime? end) =>
      state = state.copyWith(startDate: start, endDate: end);
}

final transactionFilterProvider =
    StateNotifierProvider<TransactionFilterNotifier, TransactionFilter>((ref) {
  return TransactionFilterNotifier();
});

// Reactive stream of transactions based on filter
final transactionListProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionFilterProvider);
  return repo.watchTransactions(filter);
});

// Reactive periodic summary derived directly from transactionListProvider
final transactionSummaryProvider = StreamProvider<TransactionSummary>((ref) {
  return ref.watch(transactionListProvider.stream).map((txns) {
    double income = 0;
    double expense = 0;
    for (final t in txns) {
      if (t.type == TransactionType.income) income += t.amount;
      if (t.type == TransactionType.expense) expense += t.amount;
    }
    return TransactionSummary(
      totalIncome: income,
      totalExpense: expense,
      netSavings: income - expense,
      transactionCount: txns.length,
    );
  });
});

// Frequent names for autocomplete
final frequentNamesProvider = FutureProvider<List<String>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getFrequentNames();
});

// Account stream provider
final accountListProvider = StreamProvider((ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAllAccounts();
});

// Category stream provider
final categoryListProvider = StreamProvider((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAllCategories();
});

// Net worth provider (sum of all account balances)
final netWorthProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountListProvider);
  return accountsAsync.when(
    data: (accounts) => accounts.fold(0.0, (sum, acc) => sum + acc.currentBalance),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
