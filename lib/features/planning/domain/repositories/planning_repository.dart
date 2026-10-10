import '../models/planning_models.dart';

abstract class IPlanningRepository {
  FirePlanResult calculateFirePlan(FirePlanInput input);

  MonteCarloPercentiles runMonteCarloSimulation({
    required MonteCarloInput input,
    required double targetGoal,
  });

  DebtPayoffResult calculateDebtPayoff({
    required List<LoanDebt> debts,
    required double extraMonthlyPayment,
    required DebtStrategy strategy,
  });

  double calculateCompoundSavingsScenario({
    required double monthlyReduction,
    required int years,
    double annualReturn,
  });
}
