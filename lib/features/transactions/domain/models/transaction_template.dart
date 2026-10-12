import 'transaction.dart';

class TransactionTemplate {
  final String id;
  final String name;
  final String icon;
  final int color;
  final TransactionType type;
  final double? amount;
  final String? categoryId;
  final String? accountId;
  final String? budgetId;
  final String? payeeName;
  final String? description;
  final List<String> labels;
  final bool isPreset;
  final DateTime createdAt;

  const TransactionTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.amount,
    this.categoryId,
    this.accountId,
    this.budgetId,
    this.payeeName,
    this.description,
    this.labels = const [],
    this.isPreset = false,
    required this.createdAt,
  });

  TransactionTemplate copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    String? budgetId,
    String? payeeName,
    String? description,
    List<String>? labels,
    bool? isPreset,
    DateTime? createdAt,
  }) {
    return TransactionTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      budgetId: budgetId ?? this.budgetId,
      payeeName: payeeName ?? this.payeeName,
      description: description ?? this.description,
      labels: labels ?? this.labels,
      isPreset: isPreset ?? this.isPreset,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<TransactionTemplate> get defaultTemplates {
    final now = DateTime(2026, 1, 1);
    return [
      TransactionTemplate(
        id: 'tpl-coffee',
        name: 'Morning Coffee',
        icon: 'local_cafe',
        color: 0xFF795548,
        type: TransactionType.expense,
        amount: 150.0,
        categoryId: 'cat-food',
        payeeName: 'Cafe / Coffee Shop',
        description: 'Morning espresso / beverage',
        labels: ['#discretionary', '#routine'],
        isPreset: true,
        createdAt: now,
      ),
      TransactionTemplate(
        id: 'tpl-transit',
        name: 'Metro / Commute',
        icon: 'directions_subway',
        color: 0xFF1976D2,
        type: TransactionType.expense,
        amount: 60.0,
        categoryId: 'cat-transport',
        payeeName: 'Metro Transit',
        description: 'Daily office commute',
        labels: ['#commute', '#essential'],
        isPreset: true,
        createdAt: now,
      ),
      TransactionTemplate(
        id: 'tpl-groceries',
        name: 'Grocery Run',
        icon: 'shopping_cart',
        color: 0xFF43A047,
        type: TransactionType.expense,
        amount: 1200.0,
        categoryId: 'cat-food',
        payeeName: 'Supermarket / Blinkit',
        description: 'Weekly household groceries',
        labels: ['#groceries', '#essential'],
        isPreset: true,
        createdAt: now,
      ),
      TransactionTemplate(
        id: 'tpl-ott',
        name: 'Streaming / OTT',
        icon: 'movie',
        color: 0xFFE50914,
        type: TransactionType.expense,
        amount: 649.0,
        categoryId: 'cat-entertainment',
        payeeName: 'Netflix / Prime',
        description: 'Monthly OTT subscription',
        labels: ['#subscription', '#personal'],
        isPreset: true,
        createdAt: now,
      ),
      TransactionTemplate(
        id: 'tpl-utility',
        name: 'Electricity / Bill',
        icon: 'bolt',
        color: 0xFFFB8C00,
        type: TransactionType.expense,
        amount: 2500.0,
        categoryId: 'cat-utilities',
        payeeName: 'Electricity Board',
        description: 'Monthly electricity utility',
        labels: ['#bills', '#essential'],
        isPreset: true,
        createdAt: now,
      ),
      TransactionTemplate(
        id: 'tpl-rent',
        name: 'House Rent',
        icon: 'home',
        color: 0xFF8E24AA,
        type: TransactionType.expense,
        amount: 25000.0,
        categoryId: 'cat-housing',
        payeeName: 'House Rent',
        description: 'Monthly apartment rent',
        labels: ['#rent', '#essential'],
        isPreset: true,
        createdAt: now,
      ),
      TransactionTemplate(
        id: 'tpl-sip',
        name: 'Mutual Fund SIP',
        icon: 'trending_up',
        color: 0xFF00897B,
        type: TransactionType.expense,
        amount: 5000.0,
        categoryId: 'cat-investment',
        payeeName: 'Mutual Fund SIP',
        description: 'Automated index fund SIP',
        labels: ['#investment', '#wealth'],
        isPreset: true,
        createdAt: now,
      ),
      TransactionTemplate(
        id: 'tpl-salary',
        name: 'Monthly Salary',
        icon: 'account_balance_wallet',
        color: 0xFF2E7D32,
        type: TransactionType.income,
        amount: 85000.0,
        categoryId: 'cat-salary',
        payeeName: 'Employer Payroll',
        description: 'Monthly salary deposit',
        labels: ['#salary', '#income'],
        isPreset: true,
        createdAt: now,
      ),
    ];
  }
}
