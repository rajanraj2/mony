import 'package:uuid/uuid.dart';
import '../../domain/models/sms_rule.dart';
import '../../domain/models/pending_sms_transaction.dart';
import '../../domain/repositories/sms_repository.dart';
import '../datasources/sms_dao.dart';

class SmsRepositoryImpl implements ISmsRepository {
  final SmsDao _dao;
  final _uuid = const Uuid();

  SmsRepositoryImpl(this._dao);

  @override
  Stream<List<PendingSmsTransaction>> watchPendingTransactions() => _dao.watchPending();

  @override
  Future<List<PendingSmsTransaction>> getPendingTransactions() => _dao.getPending();

  @override
  Future<void> insertPendingTransaction(PendingSmsTransaction txn) => _dao.insertPending(txn);

  @override
  Future<void> updatePendingStatus(String id, PendingStatus status) =>
      _dao.updatePendingStatus(id, status.name);

  @override
  Future<void> deletePendingTransaction(String id) => _dao.deletePending(id);

  @override
  Stream<List<SmsRule>> watchSmsRules() => _dao.watchRules();

  @override
  Future<List<SmsRule>> getSmsRules() => _dao.getRules();

  @override
  Future<void> createSmsRule(SmsRule rule) => _dao.insertRule(rule);

  @override
  Future<void> updateSmsRule(SmsRule rule) => _dao.updateRule(rule);

  @override
  Future<void> deleteSmsRule(String id) => _dao.deleteRule(id);

  @override
  Future<PendingSmsTransaction?> processIncomingSms({
    required String sender,
    required String body,
    DateTime? timestamp,
  }) async {
    final rules = await _dao.getRules();
    final effectiveRules = rules.isNotEmpty ? rules : _defaultBankRules;

    final smsDate = timestamp ?? DateTime.now();

    for (final rule in effectiveRules) {
      if (!rule.enabled) continue;

      final senderRegex = RegExp(rule.senderPattern, caseSensitive: false);
      if (!senderRegex.hasMatch(sender)) continue;

      final msgRegex = RegExp(rule.messagePattern, caseSensitive: false);
      final match = msgRegex.firstMatch(body);
      if (match == null) continue;

      // Extract amount and merchant name
      double? amount;
      String? merchant;

      final amountStr = match.namedGroup('amount') ?? (match.groupCount >= 1 ? match.group(1) : null);
      if (amountStr != null) {
        amount = double.tryParse(amountStr.replaceAll(',', '').replaceAll('Rs.', '').replaceAll('INR', '').trim());
      }

      merchant = match.namedGroup('merchant') ?? (match.groupCount >= 2 ? match.group(2) : null);
      merchant = merchant?.trim();

      if (amount != null && amount > 0) {
        final isDuplicate = await _dao.checkRecentDuplicate(amount, smsDate);

        final pending = PendingSmsTransaction(
          id: _uuid.v4(),
          rawSms: body,
          parsedName: merchant ?? 'Unknown Payee',
          parsedAmount: amount,
          parsedAccountHint: rule.accountHint,
          direction: rule.direction,
          smsDate: smsDate,
          capturedAt: DateTime.now(),
          status: PendingStatus.pending,
          duplicateFlag: isDuplicate,
        );

        await _dao.insertPending(pending);
        return pending;
      }
    }

    return null;
  }

  static final List<SmsRule> _defaultBankRules = [
    // HDFC Debit
    const SmsRule(
      id: 'rule-hdfc-debit',
      name: 'HDFC Debit',
      senderPattern: r'HDFCBK|HDFC',
      messagePattern: r'(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:debited|spent).*?(?:at|to|info)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+on|\s+avail)',
      direction: 'expense',
      accountHint: 'HDFC Bank',
      sortOrder: 1,
    ),
    // SBI Debit
    const SmsRule(
      id: 'rule-sbi-debit',
      name: 'SBI Debit',
      senderPattern: r'SBIINB|SBIPAY|SBI',
      messagePattern: r'(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:debited|transferred).*?(?:to|at)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+ref|\s+on)',
      direction: 'expense',
      accountHint: 'State Bank of India',
      sortOrder: 2,
    ),
    // ICICI Debit
    const SmsRule(
      id: 'rule-icici-debit',
      name: 'ICICI Debit',
      senderPattern: r'ICICIB|ICICI',
      messagePattern: r'(?:acct.*?)?(?:debited for|spent)\s*(?:INR|Rs\.?)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*at\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+on)',
      direction: 'expense',
      accountHint: 'ICICI Bank',
      sortOrder: 3,
    ),
    // UPI generic debit (GPay, PhonePe, Paytm)
    const SmsRule(
      id: 'rule-upi-debit',
      name: 'UPI Generic Debit',
      senderPattern: r'.*UPI.*|PAYTM|PHONEPE|GPAY',
      messagePattern: r'(?:paid|sent|debited)\s*(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:to|at)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+using|\s+on)',
      direction: 'expense',
      accountHint: 'UPI Account',
      sortOrder: 4,
    ),
    // Salary / Credit pattern
    const SmsRule(
      id: 'rule-salary-credit',
      name: 'Generic Bank Credit',
      senderPattern: r'.*',
      messagePattern: r'(?:credited with|received)\s*(?:Rs\.?|INR)\s*(?<amount>[\d,]+(?:\.\d{2})?)\s*(?:from|by)\s*(?<merchant>[a-zA-Z0-9\s&*-]+?)(?:\.|\s+on)',
      direction: 'income',
      accountHint: 'Primary Bank',
      sortOrder: 5,
    ),
  ];
}
