enum PendingStatus {
  pending,
  approved,
  rejected;

  static PendingStatus fromString(String val) =>
      PendingStatus.values.firstWhere((e) => e.name == val, orElse: () => PendingStatus.pending);
}

class PendingSmsTransaction {
  final String id;
  final String rawSms;
  final String? parsedName;
  final double? parsedAmount;
  final String? parsedAccountHint;
  final String direction; // income, expense
  final DateTime smsDate;
  final DateTime capturedAt;
  final PendingStatus status;
  final bool duplicateFlag;

  const PendingSmsTransaction({
    required this.id,
    required this.rawSms,
    this.parsedName,
    this.parsedAmount,
    this.parsedAccountHint,
    required this.direction,
    required this.smsDate,
    required this.capturedAt,
    this.status = PendingStatus.pending,
    this.duplicateFlag = false,
  });

  PendingSmsTransaction copyWith({
    String? id,
    String? rawSms,
    String? parsedName,
    double? parsedAmount,
    String? parsedAccountHint,
    String? direction,
    DateTime? smsDate,
    DateTime? capturedAt,
    PendingStatus? status,
    bool? duplicateFlag,
  }) {
    return PendingSmsTransaction(
      id: id ?? this.id,
      rawSms: rawSms ?? this.rawSms,
      parsedName: parsedName ?? this.parsedName,
      parsedAmount: parsedAmount ?? this.parsedAmount,
      parsedAccountHint: parsedAccountHint ?? this.parsedAccountHint,
      direction: direction ?? this.direction,
      smsDate: smsDate ?? this.smsDate,
      capturedAt: capturedAt ?? this.capturedAt,
      status: status ?? this.status,
      duplicateFlag: duplicateFlag ?? this.duplicateFlag,
    );
  }
}
