import 'transaction.dart';

class TransactionFilter {
  final String? accountId;
  final String? categoryId;
  final TransactionType? type;
  final TransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final String? person;
  final String? place;
  final String? label;

  const TransactionFilter({
    this.accountId,
    this.categoryId,
    this.type,
    this.status,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.person,
    this.place,
    this.label,
  });

  TransactionFilter copyWith({
    String? accountId,
    String? categoryId,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    String? person,
    String? place,
    String? label,
  }) {
    return TransactionFilter(
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      person: person ?? this.person,
      place: place ?? this.place,
      label: label ?? this.label,
    );
  }
}

class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final int transactionCount;

  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.transactionCount,
  });

  double get savingsRate =>
      totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0.0;
}
