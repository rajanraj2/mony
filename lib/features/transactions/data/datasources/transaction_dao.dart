import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/transaction.dart' as domain;
import '../../domain/models/transaction_filter.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable, AccountsTable, CategoriesTable])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<domain.Transaction>> watchTransactions([TransactionFilter? filter]) {
    final query = select(transactionsTable);
    _applyFilter(query, filter);
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.watch().map((rows) => rows.map(_mapToDomain).toList());
  }

  Future<List<domain.Transaction>> getTransactions([TransactionFilter? filter]) {
    final query = select(transactionsTable);
    _applyFilter(query, filter);
    query.orderBy([(t) => OrderingTerm.desc(t.date)]);
    return query.get().then((rows) => rows.map(_mapToDomain).toList());
  }

  Future<domain.Transaction?> getTransactionById(String id) {
    return (select(transactionsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull()
        .then((r) => r != null ? _mapToDomain(r) : null);
  }

  Future<void> insertTransaction(domain.Transaction t) {
    return into(transactionsTable).insert(_mapToCompanion(t));
  }

  Future<void> updateTransaction(domain.Transaction t) {
    return update(transactionsTable).replace(_mapToCompanion(t));
  }

  Future<void> deleteTransaction(String id) {
    return (delete(transactionsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<String>> getFrequentNames({int limit = 10}) async {
    final nameCol = transactionsTable.name;
    final countCol = countAll();
    final query = selectOnly(transactionsTable)
      ..addColumns([nameCol, countCol])
      ..groupBy([nameCol])
      ..orderBy([OrderingTerm.desc(countCol)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map((r) => r.read(nameCol)!).toList();
  }

  void _applyFilter(SimpleSelectStatement<$TransactionsTableTable, TransactionsTableData> query, TransactionFilter? f) {
    if (f == null) return;
    if (f.accountId != null) {
      query.where((t) => t.accountId.equals(f.accountId!) | t.transferAccountId.equals(f.accountId!));
    }
    if (f.categoryId != null) {
      query.where((t) => t.categoryId.equals(f.categoryId!));
    }
    if (f.type != null) {
      query.where((t) => t.type.equals(f.type!.name));
    }
    if (f.status != null) {
      query.where((t) => t.status.equals(f.status!.name));
    }
    if (f.startDate != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(f.startDate!.millisecondsSinceEpoch));
    }
    if (f.endDate != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(f.endDate!.millisecondsSinceEpoch));
    }
    if (f.searchQuery != null && f.searchQuery!.isNotEmpty) {
      query.where((t) => t.name.like('%${f.searchQuery}%') | t.description.like('%${f.searchQuery}%'));
    }
    if (f.person != null) {
      query.where((t) => t.person.equals(f.person!));
    }
    if (f.place != null) {
      query.where((t) => t.place.equals(f.place!));
    }
  }

  domain.Transaction _mapToDomain(TransactionsTableData r) {
    return domain.Transaction(
      id: r.id,
      accountId: r.accountId,
      transferAccountId: r.transferAccountId,
      categoryId: r.categoryId,
      amount: r.amount,
      currencyCode: r.currencyCode,
      fxRate: r.fxRate,
      type: domain.TransactionType.fromString(r.type),
      name: r.name,
      description: r.description,
      person: r.person,
      place: r.place,
      attachmentPath: r.attachmentPath,
      date: DateTime.fromMillisecondsSinceEpoch(r.date),
      status: domain.TransactionStatus.fromString(r.status),
      recurrenceId: r.recurrenceId,
      labels: r.labels.isNotEmpty ? r.labels.split(',') : const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    );
  }

  TransactionsTableCompanion _mapToCompanion(domain.Transaction t) {
    return TransactionsTableCompanion(
      id: Value(t.id),
      accountId: Value(t.accountId),
      transferAccountId: Value(t.transferAccountId),
      categoryId: Value(t.categoryId),
      amount: Value(t.amount),
      currencyCode: Value(t.currencyCode),
      fxRate: Value(t.fxRate),
      type: Value(t.type.name),
      name: Value(t.name),
      description: Value(t.description),
      person: Value(t.person),
      place: Value(t.place),
      attachmentPath: Value(t.attachmentPath),
      date: Value(t.date.millisecondsSinceEpoch),
      status: Value(t.status.name),
      recurrenceId: Value(t.recurrenceId),
      labels: Value(t.labels.join(',')),
      createdAt: Value(t.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(t.updatedAt.millisecondsSinceEpoch),
    );
  }
}
