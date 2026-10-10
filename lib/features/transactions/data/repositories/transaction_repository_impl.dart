import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_filter.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_dao.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final TransactionDao _dao;

  TransactionRepositoryImpl(this._dao);

  @override
  Stream<List<Transaction>> watchTransactions([TransactionFilter? filter]) =>
      _dao.watchTransactions(filter);

  @override
  Future<List<Transaction>> getTransactions([TransactionFilter? filter]) =>
      _dao.getTransactions(filter);

  @override
  Future<Transaction?> getTransactionById(String id) =>
      _dao.getTransactionById(id);

  @override
  Future<void> createTransaction(Transaction transaction) =>
      _dao.insertTransaction(transaction);

  @override
  Future<void> updateTransaction(Transaction transaction) =>
      _dao.updateTransaction(transaction);

  @override
  Future<void> deleteTransaction(String id) =>
      _dao.deleteTransaction(id);

  @override
  Future<TransactionSummary> getSummary({DateTime? startDate, DateTime? endDate}) async {
    final txns = await _dao.getTransactions(
      TransactionFilter(startDate: startDate, endDate: endDate),
    );
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
  }

  @override
  Future<List<String>> getFrequentNames({int limit = 10}) =>
      _dao.getFrequentNames(limit: limit);
}
