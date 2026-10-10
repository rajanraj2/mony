import 'dart:math';
import '../../domain/models/planning_models.dart';
import '../../domain/repositories/planning_repository.dart';

class PlanningRepositoryImpl implements IPlanningRepository {
  @override
  FirePlanResult calculateFirePlan(FirePlanInput input) {
    final years = input.yearsToRetirement;
    final rInflation = input.inflationRate / 100.0;
    final rReturn = input.expectedReturn / 100.0;
    final swr = input.safeWithdrawalRate / 100.0;

    // Inflated monthly expenses at retirement date: E_future = E_now * (1 + inflation)^years
    final futureMonthlyExpenses = input.currentMonthlyExpenses * pow(1 + rInflation, years);
    final annualRetirementExpenses = futureMonthlyExpenses * 12.0;

    // Target corpus based on Safe Withdrawal Rate: Target = AnnualExpenses / SWR
    final targetCorpus = annualRetirementExpenses / swr;

    // Compound current net worth: FV_current = NetWorth * (1 + rReturn)^years
    final futureNetWorth = input.currentNetWorth * pow(1 + rReturn, years);

    final shortfall = (targetCorpus - futureNetWorth).clamp(0.0, double.infinity);

    // Calculate required monthly savings using Future Value of Annuity formula:
    // Shortfall = PMT * [ ((1 + r_m)^n - 1) / r_m ]
    double requiredMonthly = 0.0;
    if (shortfall > 0 && years > 0) {
      final monthlyRate = rReturn / 12.0;
      final totalMonths = years * 12;
      if (monthlyRate > 0) {
        final fvFactor = (pow(1 + monthlyRate, totalMonths) - 1.0) / monthlyRate;
        requiredMonthly = shortfall / fvFactor;
      }
    }

    return FirePlanResult(
      targetCorpus: targetCorpus,
      futureMonthlyExpenses: futureMonthlyExpenses,
      requiredMonthlySavings: requiredMonthly,
      corpusShortfall: shortfall,
      yearsToFire: years,
      isFireAchieved: futureNetWorth >= targetCorpus,
    );
  }

  @override
  MonteCarloPercentiles runMonteCarloSimulation({
    required MonteCarloInput input,
    required double targetGoal,
  }) {
    final random = Random(42); // deterministic seed for reproducibility
    final finalValues = <double>[];

    final months = input.horizonYears * 12;
    final monthlyMean = (input.meanReturnPercent / 100.0) / 12.0;
    final monthlyVol = (input.volatilityPercent / 100.0) / sqrt(12);

    for (var run = 0; run < input.simulationRuns; run++) {
      var currentBalance = input.initialPortfolio;

      for (var m = 0; m < months; m++) {
        // Box-Muller transform for standard normal variable
        final u1 = random.nextDouble().clamp(0.00001, 0.99999);
        final u2 = random.nextDouble().clamp(0.00001, 0.99999);
        final z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

        final monthReturn = monthlyMean + (monthlyVol * z);
        currentBalance = (currentBalance * (1.0 + monthReturn)) + input.monthlyContribution;
      }
      finalValues.add(currentBalance.clamp(0.0, double.infinity));
    }

    finalValues.sort();
    final p10Index = (input.simulationRuns * 0.10).floor();
    final p50Index = (input.simulationRuns * 0.50).floor();
    final p90Index = (input.simulationRuns * 0.90).floor();

    final successes = finalValues.where((val) => val >= targetGoal).length;
    final successProb = (successes / input.simulationRuns) * 100.0;

    return MonteCarloPercentiles(
      p10: finalValues[p10Index],
      p50: finalValues[p50Index],
      p90: finalValues[p90Index],
      probabilityOfTarget: successProb,
    );
  }

  @override
  DebtPayoffResult calculateDebtPayoff({
    required List<LoanDebt> debts,
    required double extraMonthlyPayment,
    required DebtStrategy strategy,
  }) {
    if (debts.isEmpty) {
      return DebtPayoffResult(
        strategy: strategy,
        totalMonths: 0,
        totalInterestPaid: 0,
        monthlyPayment: 0,
      );
    }

    // Clone debts to avoid mutation
    final activeDebts = debts.map((d) => _MutableDebt(d.name, d.balance, d.annualInterestRate, d.minimumPayment)).toList();

    double totalInterestPaid = 0.0;
    int months = 0;
    final baseMinPayment = debts.fold(0.0, (s, d) => s + d.minimumPayment);
    final totalMonthlyBudget = baseMinPayment + extraMonthlyPayment;

    while (activeDebts.any((d) => d.balance > 0) && months < 360) {
      months++;

      // Sort by chosen strategy
      if (strategy == DebtStrategy.avalanche) {
        activeDebts.sort((a, b) => b.rate.compareTo(a.rate)); // highest rate first
      } else {
        activeDebts.sort((a, b) => a.balance.compareTo(b.balance)); // lowest balance first
      }

      double availableExtra = extraMonthlyPayment;

      // 1. Accrue interest & pay minimums
      for (final d in activeDebts) {
        if (d.balance <= 0) continue;
        final interest = d.balance * (d.rate / 100.0 / 12.0);
        totalInterestPaid += interest;
        d.balance += interest;

        final payment = min(d.minPayment, d.balance);
        d.balance -= payment;
      }

      // 2. Apply extra payment to priority debt
      for (final d in activeDebts) {
        if (d.balance > 0 && availableExtra > 0) {
          final extraPay = min(availableExtra, d.balance);
          d.balance -= extraPay;
          availableExtra -= extraPay;
        }
      }
    }

    return DebtPayoffResult(
      strategy: strategy,
      totalMonths: months,
      totalInterestPaid: totalInterestPaid,
      monthlyPayment: totalMonthlyBudget,
    );
  }

  @override
  double calculateCompoundSavingsScenario({
    required double monthlyReduction,
    required int years,
    double annualReturn = 12.0,
  }) {
    final rMonthly = (annualReturn / 100.0) / 12.0;
    final totalMonths = years * 12;
    if (rMonthly <= 0) return monthlyReduction * totalMonths;

    // FV = PMT * [ ((1 + r)^n - 1) / r ]
    return monthlyReduction * ((pow(1 + rMonthly, totalMonths) - 1.0) / rMonthly);
  }
}

class _MutableDebt {
  final String name;
  double balance;
  final double rate;
  final double minPayment;

  _MutableDebt(this.name, this.balance, this.rate, this.minPayment);
}
