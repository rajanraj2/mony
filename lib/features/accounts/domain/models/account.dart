enum AccountType {
  bank,
  cash,
  card,
  wallet;

  static AccountType fromString(String val) =>
      AccountType.values.firstWhere((e) => e.name == val, orElse: () => AccountType.bank);
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final String currencyCode;
  final double openingBalance;
  final double currentBalance;
  final int color;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.openingBalance,
    this.currentBalance = 0.0,
    required this.color,
    required this.icon,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? currencyCode,
    double? openingBalance,
    double? currentBalance,
    int? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
