import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/transaction_filter.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final ITransactionRepository _repo;
  final _uuid = const Uuid();

  AddTransactionUseCase(this._repo);

  Future<Transaction> execute({
    required String accountId,
    String? transferAccountId,
    String? categoryId,
    required double amount,
    required String currencyCode,
    double? fxRate,
    required TransactionType type,
    required String name,
    String? description,
    String? person,
    String? place,
    String? attachmentPath,
    required DateTime date,
    TransactionStatus status = TransactionStatus.cleared,
    String? recurrenceId,
    List<String> labels = const [],
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }
    if (type == TransactionType.transfer && transferAccountId == null) {
      throw ArgumentError('Transfer destination account is required');
    }

    final now = DateTime.now();
    final txn = Transaction(
      id: _uuid.v4(),
      accountId: accountId,
      transferAccountId: transferAccountId,
      categoryId: categoryId,
      amount: amount,
      currencyCode: currencyCode,
      fxRate: fxRate,
      type: type,
      name: name.trim(),
      description: description?.trim(),
      person: person?.trim(),
      place: place?.trim(),
      attachmentPath: attachmentPath,
      date: date,
      status: status,
      recurrenceId: recurrenceId,
      labels: labels,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.createTransaction(txn);
    return txn;
  }
}

class UpdateTransactionUseCase {
  final ITransactionRepository _repo;

  UpdateTransactionUseCase(this._repo);

  Future<void> execute(Transaction transaction) async {
    if (transaction.amount <= 0) throw ArgumentError('Amount must be positive');
    await _repo.updateTransaction(
      transaction.copyWith(updatedAt: DateTime.now()),
    );
  }
}

class DeleteTransactionUseCase {
  final ITransactionRepository _repo;

  DeleteTransactionUseCase(this._repo);

  Future<void> execute(String id) => _repo.deleteTransaction(id);
}
