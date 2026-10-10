import '../models/sms_rule.dart';
import '../models/pending_sms_transaction.dart';

abstract class ISmsRepository {
  Stream<List<PendingSmsTransaction>> watchPendingTransactions();
  Future<List<PendingSmsTransaction>> getPendingTransactions();
  Future<void> insertPendingTransaction(PendingSmsTransaction txn);
  Future<void> updatePendingStatus(String id, PendingStatus status);
  Future<void> deletePendingTransaction(String id);

  Stream<List<SmsRule>> watchSmsRules();
  Future<List<SmsRule>> getSmsRules();
  Future<void> createSmsRule(SmsRule rule);
  Future<void> updateSmsRule(SmsRule rule);
  Future<void> deleteSmsRule(String id);

  Future<PendingSmsTransaction?> processIncomingSms({
    required String sender,
    required String body,
    DateTime? timestamp,
  });
}
