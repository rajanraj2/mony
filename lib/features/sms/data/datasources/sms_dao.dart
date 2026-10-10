import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/sms_rule.dart' as domain;
import '../../domain/models/pending_sms_transaction.dart' as domain;

part 'sms_dao.g.dart';

@DriftAccessor(tables: [SmsRulesTable, PendingSmsTransactionsTable, TransactionsTable])
class SmsDao extends DatabaseAccessor<AppDatabase> with _$SmsDaoMixin {
  SmsDao(super.db);

  Stream<List<domain.PendingSmsTransaction>> watchPending() {
    return (select(pendingSmsTransactionsTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .watch()
        .map((rows) => rows.map(_mapPendingToDomain).toList());
  }

  Future<List<domain.PendingSmsTransaction>> getPending() {
    return (select(pendingSmsTransactionsTable)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .get()
        .then((rows) => rows.map(_mapPendingToDomain).toList());
  }

  Future<void> insertPending(domain.PendingSmsTransaction t) {
    return into(pendingSmsTransactionsTable).insert(PendingSmsTransactionsTableCompanion(
      id: Value(t.id),
      rawSms: Value(t.rawSms),
      parsedName: Value(t.parsedName),
      parsedAmount: Value(t.parsedAmount),
      parsedAccountHint: Value(t.parsedAccountHint),
      direction: Value(t.direction),
      smsDate: Value(t.smsDate.millisecondsSinceEpoch),
      capturedAt: Value(t.capturedAt.millisecondsSinceEpoch),
      status: Value(t.status.name),
      duplicateFlag: Value(t.duplicateFlag ? 1 : 0),
    ));
  }

  Future<void> updatePendingStatus(String id, String status) {
    return (update(pendingSmsTransactionsTable)..where((t) => t.id.equals(id))).write(
      PendingSmsTransactionsTableCompanion(status: Value(status)),
    );
  }

  Future<void> deletePending(String id) {
    return (delete(pendingSmsTransactionsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<domain.SmsRule>> watchRules() {
    return (select(smsRulesTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .map((rows) => rows.map(_mapRuleToDomain).toList());
  }

  Future<List<domain.SmsRule>> getRules() {
    return (select(smsRulesTable)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get()
        .then((rows) => rows.map(_mapRuleToDomain).toList());
  }

  Future<void> insertRule(domain.SmsRule r) {
    return into(smsRulesTable).insert(SmsRulesTableCompanion(
      id: Value(r.id),
      name: Value(r.name),
      senderPattern: Value(r.senderPattern),
      messagePattern: Value(r.messagePattern),
      direction: Value(r.direction),
      defaultCategoryId: Value(r.defaultCategoryId),
      accountHint: Value(r.accountHint),
      enabled: Value(r.enabled ? 1 : 0),
      sortOrder: Value(r.sortOrder),
    ));
  }

  Future<void> updateRule(domain.SmsRule r) {
    return update(smsRulesTable).replace(SmsRulesTableCompanion(
      id: Value(r.id),
      name: Value(r.name),
      senderPattern: Value(r.senderPattern),
      messagePattern: Value(r.messagePattern),
      direction: Value(r.direction),
      defaultCategoryId: Value(r.defaultCategoryId),
      accountHint: Value(r.accountHint),
      enabled: Value(r.enabled ? 1 : 0),
      sortOrder: Value(r.sortOrder),
    ));
  }

  Future<void> deleteRule(String id) {
    return (delete(smsRulesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<bool> checkRecentDuplicate(double amount, DateTime date) async {
    final fiveMinAgo = date.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
    final fiveMinAhead = date.add(const Duration(minutes: 5)).millisecondsSinceEpoch;

    // Check confirmed transactions
    final existingTxn = await (select(transactionsTable)
          ..where((t) =>
              t.amount.equals(amount) &
              t.date.isBiggerOrEqualValue(fiveMinAgo) &
              t.date.isSmallerOrEqualValue(fiveMinAhead)))
        .get();

    if (existingTxn.isNotEmpty) return true;

    // Check pending table
    final existingPending = await (select(pendingSmsTransactionsTable)
          ..where((t) =>
              t.parsedAmount.equals(amount) &
              t.capturedAt.isBiggerOrEqualValue(fiveMinAgo) &
              t.capturedAt.isSmallerOrEqualValue(fiveMinAhead)))
        .get();

    return existingPending.isNotEmpty;
  }

  domain.PendingSmsTransaction _mapPendingToDomain(PendingSmsTransactionsTableData r) {
    return domain.PendingSmsTransaction(
      id: r.id,
      rawSms: r.rawSms,
      parsedName: r.parsedName,
      parsedAmount: r.parsedAmount,
      parsedAccountHint: r.parsedAccountHint,
      direction: r.direction,
      smsDate: DateTime.fromMillisecondsSinceEpoch(r.smsDate),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(r.capturedAt),
      status: domain.PendingStatus.fromString(r.status),
      duplicateFlag: r.duplicateFlag == 1,
    );
  }

  domain.SmsRule _mapRuleToDomain(SmsRulesTableData r) {
    return domain.SmsRule(
      id: r.id,
      name: r.name,
      senderPattern: r.senderPattern,
      messagePattern: r.messagePattern,
      direction: r.direction,
      defaultCategoryId: r.defaultCategoryId,
      accountHint: r.accountHint,
      enabled: r.enabled == 1,
      sortOrder: r.sortOrder,
    );
  }
}
