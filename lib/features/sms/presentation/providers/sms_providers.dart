import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/sms_rule.dart';
import '../../domain/models/pending_sms_transaction.dart';

final pendingSmsListProvider = StreamProvider<List<PendingSmsTransaction>>((ref) {
  return ref.watch(smsRepositoryProvider).watchPendingTransactions();
});

final smsRulesListProvider = StreamProvider<List<SmsRule>>((ref) {
  return ref.watch(smsRepositoryProvider).watchSmsRules();
});
