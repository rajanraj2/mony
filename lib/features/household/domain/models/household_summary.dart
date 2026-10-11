class MemberSpendContribution {
  final String userId;
  final String memberName;
  final double totalSpent;
  final double percentage; // 0.0 to 1.0

  const MemberSpendContribution({
    required this.userId,
    required this.memberName,
    required this.totalSpent,
    required this.percentage,
  });
}

class HouseholdFinancialOverview {
  final double combinedNetWorth;
  final double combinedMonthlyInflow;
  final double combinedMonthlyOutflow;
  final double combinedSavingsRate;
  final List<MemberSpendContribution> spendPerMember;

  const HouseholdFinancialOverview({
    required this.combinedNetWorth,
    required this.combinedMonthlyInflow,
    required this.combinedMonthlyOutflow,
    required this.combinedSavingsRate,
    required this.spendPerMember,
  });
}
