enum BudgetPeriod {
  weekly,
  monthly,
  custom;

  static BudgetPeriod fromString(String val) =>
      BudgetPeriod.values.firstWhere((e) => e.name == val, orElse: () => BudgetPeriod.monthly);
}

class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final bool rollover;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    this.periodStart,
    this.periodEnd,
    this.rollover = false,
    required this.createdAt,
  });

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? periodStart,
    DateTime? periodEnd,
    bool? rollover,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      rollover: rollover ?? this.rollover,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BudgetProgress {
  final Budget budget;
  final String categoryName;
  final int categoryColor;
  final String categoryIcon;
  final double spent;
  final double rolloverAmount;

  const BudgetProgress({
    required this.budget,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.spent,
    this.rolloverAmount = 0.0,
  });

  double get effectiveBudget => budget.amount + rolloverAmount;
  double get remaining => (effectiveBudget - spent).clamp(0.0, double.infinity);
  double get overspent => (spent - effectiveBudget).clamp(0.0, double.infinity);
  double get percentage => effectiveBudget > 0 ? (spent / effectiveBudget).clamp(0.0, 1.5) : 0.0;
  bool get isOverBudget => spent > effectiveBudget;
  bool get isNearLimit => percentage >= 0.8 && !isOverBudget;
}
