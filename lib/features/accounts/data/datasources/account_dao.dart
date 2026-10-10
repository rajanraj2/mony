import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/account.dart' as domain;

part 'account_dao.g.dart';

@DriftAccessor(tables: [AccountsTable, TransactionsTable])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Stream<List<domain.Account>> watchAccounts() {
    return (select(accountsTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .asyncMap((rows) async {
      final accounts = <domain.Account>[];
      for (final r in rows) {
        final balance = await getCalculatedBalance(r.id, r.openingBalance);
        accounts.add(_mapToDomain(r, balance));
      }
      return accounts;
    });
  }

  Future<List<domain.Account>> getAllAccounts() async {
    final rows = await (select(accountsTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    final accounts = <domain.Account>[];
    for (final r in rows) {
      final balance = await getCalculatedBalance(r.id, r.openingBalance);
      accounts.add(_mapToDomain(r, balance));
    }
    return accounts;
  }

  Future<domain.Account?> getAccountById(String id) async {
    final row = await (select(accountsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final balance = await getCalculatedBalance(row.id, row.openingBalance);
    return _mapToDomain(row, balance);
  }

  Future<void> insertAccount(domain.Account acc) {
    return into(accountsTable).insert(AccountsTableCompanion(
      id: Value(acc.id),
      name: Value(acc.name),
      type: Value(acc.type.name),
      currencyCode: Value(acc.currencyCode),
      openingBalance: Value(acc.openingBalance),
      color: Value(acc.color),
      icon: Value(acc.icon),
      sortOrder: Value(acc.sortOrder),
      createdAt: Value(acc.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(acc.updatedAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> updateAccount(domain.Account acc) {
    return update(accountsTable).replace(AccountsTableCompanion(
      id: Value(acc.id),
      name: Value(acc.name),
      type: Value(acc.type.name),
      currencyCode: Value(acc.currencyCode),
      openingBalance: Value(acc.openingBalance),
      color: Value(acc.color),
      icon: Value(acc.icon),
      sortOrder: Value(acc.sortOrder),
      createdAt: Value(acc.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(acc.updatedAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteAccount(String id) {
    return (delete(accountsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<double> getCalculatedBalance(String accountId, double openingBalance) async {
    final txns = await (select(transactionsTable)
          ..where((t) => t.accountId.equals(accountId) | t.transferAccountId.equals(accountId)))
        .get();

    double balance = openingBalance;
    for (final t in txns) {
      if (t.accountId == accountId) {
        if (t.type == 'income') balance += t.amount;
        if (t.type == 'expense') balance -= t.amount;
        if (t.type == 'transfer') balance -= t.amount;
      }
      if (t.transferAccountId == accountId && t.type == 'transfer') {
        balance += t.amount;
      }
    }
    return balance;
  }

  domain.Account _mapToDomain(AccountsTableData r, double calculatedBalance) {
    return domain.Account(
      id: r.id,
      name: r.name,
      type: domain.AccountType.fromString(r.type),
      currencyCode: r.currencyCode,
      openingBalance: r.openingBalance,
      currentBalance: calculatedBalance,
      color: r.color,
      icon: r.icon,
      sortOrder: r.sortOrder,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
    );
  }
}
