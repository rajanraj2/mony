class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String currencyCode;
  final String? linkedAccountId;
  final DateTime deadline;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.currencyCode,
    this.linkedAccountId,
    required this.deadline,
    required this.createdAt,
  });

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? currencyCode,
    String? linkedAccountId,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currencyCode: currencyCode ?? this.currencyCode,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progressPercentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isReached => currentAmount >= targetAmount;
  int get daysRemaining => deadline.difference(DateTime.now()).inDays.clamp(0, 99999);
  
  /// Monthly contribution required to reach goal by deadline
  double get requiredMonthlyContribution {
    final monthsRemaining = (daysRemaining / 30.44).ceil();
    if (monthsRemaining <= 0 || isReached) return 0.0;
    final remainingAmount = targetAmount - currentAmount;
    return remainingAmount / monthsRemaining;
  }
}
