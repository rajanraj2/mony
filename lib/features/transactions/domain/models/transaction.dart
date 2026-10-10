enum TransactionType {
  income,
  expense,
  transfer;

  static TransactionType fromString(String val) =>
      TransactionType.values.firstWhere((e) => e.name == val, orElse: () => TransactionType.expense);
}

enum TransactionStatus {
  cleared,
  pending;

  static TransactionStatus fromString(String val) =>
      TransactionStatus.values.firstWhere((e) => e.name == val, orElse: () => TransactionStatus.cleared);
}

class Transaction {
  final String id;
  final String accountId;
  final String? transferAccountId;
  final String? categoryId;
  final double amount;
  final String currencyCode;
  final double? fxRate;
  final TransactionType type;
  final String name;
  final String? description;
  final String? person;
  final String? place;
  final String? attachmentPath;
  final DateTime date;
  final TransactionStatus status;
  final String? recurrenceId;
  final List<String> labels;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.accountId,
    this.transferAccountId,
    this.categoryId,
    required this.amount,
    required this.currencyCode,
    this.fxRate,
    required this.type,
    required this.name,
    this.description,
    this.person,
    this.place,
    this.attachmentPath,
    required this.date,
    this.status = TransactionStatus.cleared,
    this.recurrenceId,
    this.labels = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction copyWith({
    String? id,
    String? accountId,
    String? transferAccountId,
    String? categoryId,
    double? amount,
    String? currencyCode,
    double? fxRate,
    TransactionType? type,
    String? name,
    String? description,
    String? person,
    String? place,
    String? attachmentPath,
    DateTime? date,
    TransactionStatus? status,
    String? recurrenceId,
    List<String>? labels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      transferAccountId: transferAccountId ?? this.transferAccountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      fxRate: fxRate ?? this.fxRate,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      person: person ?? this.person,
      place: place ?? this.place,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      date: date ?? this.date,
      status: status ?? this.status,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      labels: labels ?? this.labels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
