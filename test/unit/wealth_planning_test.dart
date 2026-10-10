import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/planning/domain/models/planning_models.dart';
import 'package:mony/features/planning/data/repositories/planning_repository_impl.dart';

void main() {
  group('Wealth Planning Math Engine Tests', () {
    final repo = PlanningRepositoryImpl();

    test('FIRE Calculator calculates target corpus and monthly savings needed', () {
      final input = FirePlanInput(
        currentAge: 30,
        targetRetirementAge: 50, // 20 years to retirement
        currentMonthlyExpenses: 50000,
        inflationRate: 6.0,
        expectedReturn: 12.0,
        currentNetWorth: 1000000, // 10 Lakhs
        safeWithdrawalRate: 4.0,
      );

      final result = repo.calculateFirePlan(input);

      // Target corpus should be non-zero and accounts for 20 years of inflation
      expect(result.targetCorpus, greaterThan(30000000)); // > 3 Crores
      expect(result.requiredMonthlySavings, greaterThan(0));
      expect(result.yearsToFire, equals(20));
      expect(result.isFireAchieved, isFalse);
    });

    test('Monte Carlo Simulator runs 100 iterations with valid percentiles', () {
      final input = MonteCarloInput(
        initialPortfolio: 500000,
        monthlyContribution: 25000,
        meanReturnPercent: 12.0,
        volatilityPercent: 15.0,
        horizonYears: 10,
        simulationRuns: 100,
      );

      final percentiles = repo.runMonteCarloSimulation(
        input: input,
        targetGoal: 5000000,
      );

      expect(percentiles.p90, greaterThanOrEqualTo(percentiles.p50));
      expect(percentiles.p50, greaterThanOrEqualTo(percentiles.p10));
      expect(percentiles.probabilityOfTarget, inInclusiveRange(0.0, 100.0));
    });

    test('Compound Savings Scenario calculates compound growth accurately', () {
      // Cutting ₹5,000/month for 10 years at 12% return
      final fv = repo.calculateCompoundSavingsScenario(
        monthlyReduction: 5000,
        years: 10,
        annualReturn: 12.0,
      );

      // FV formula: 5000 * [ ((1.01)^120 - 1) / 0.01 ] ≈ 11.5 Lakhs
      expect(fv, closeTo(1150000, 50000));
    });
  });
}
