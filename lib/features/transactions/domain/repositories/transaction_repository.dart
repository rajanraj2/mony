import '../models/transaction.dart';
import '../models/transaction_filter.dart';

abstract class ITransactionRepository {
  Stream<List<Transaction>> watchTransactions([TransactionFilter? filter]);
  Future<List<Transaction>> getTransactions([TransactionFilter? filter]);
  Future<Transaction?> getTransactionById(String id);
  Future<void> createTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<TransactionSummary> getSummary({DateTime? startDate, DateTime? endDate});
  Future<List<String>> getFrequentNames({int limit = 10});
  Future<int> rollbackToTimestamp(DateTime targetTimestamp);
  Future<int> countTransactionsAfter(DateTime targetTimestamp);
}
