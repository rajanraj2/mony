import 'dart:math';

// ── FIRE Calculator Models ──────────────────────────────────────────────────

class FirePlanInput {
  final int currentAge;
  final int targetRetirementAge;
  final double currentMonthlyExpenses;
  final double inflationRate; // in percent (e.g. 6.0)
  final double expectedReturn; // in percent (e.g. 12.0)
  final double currentNetWorth;
  final double safeWithdrawalRate; // in percent (default 4.0)

  const FirePlanInput({
    required this.currentAge,
    required this.targetRetirementAge,
    required this.currentMonthlyExpenses,
    this.inflationRate = 6.0,
    this.expectedReturn = 12.0,
    required this.currentNetWorth,
    this.safeWithdrawalRate = 4.0,
  });

  int get yearsToRetirement => (targetRetirementAge - currentAge).clamp(0, 80);
}

class FirePlanResult {
  final double targetCorpus;
  final double futureMonthlyExpenses;
  final double requiredMonthlySavings;
  final double corpusShortfall;
  final int yearsToFire;
  final bool isFireAchieved;

  const FirePlanResult({
    required this.targetCorpus,
    required this.futureMonthlyExpenses,
    required this.requiredMonthlySavings,
    required this.corpusShortfall,
    required this.yearsToFire,
    required this.isFireAchieved,
  });
}

// ── Monte Carlo Simulation Models ───────────────────────────────────────────

class MonteCarloInput {
  final double initialPortfolio;
  final double monthlyContribution;
  final double meanReturnPercent; // e.g. 11.0%
  final double volatilityPercent; // e.g. 15.0%
  final int horizonYears; // e.g. 20
  final int simulationRuns; // e.g. 500

  const MonteCarloInput({
    required this.initialPortfolio,
    required this.monthlyContribution,
    this.meanReturnPercent = 11.0,
    this.volatilityPercent = 15.0,
    this.horizonYears = 20,
    this.simulationRuns = 500,
  });
}

class MonteCarloPercentiles {
  final double p10; // Conservative (10th percentile)
  final double p50; // Median (50th percentile)
  final double p90; // Optimistic (90th percentile)
  final double probabilityOfTarget;

  const MonteCarloPercentiles({
    required this.p10,
    required this.p50,
    required this.p90,
    required this.probabilityOfTarget,
  });
}

// ── Debt Payoff Models ──────────────────────────────────────────────────────

enum DebtStrategy {
  avalanche, // highest interest rate first
  snowball,  // lowest balance first
}

class LoanDebt {
  final String id;
  final String name;
  final double balance;
  final double annualInterestRate; // in percent
  final double minimumPayment;

  const LoanDebt({
    required this.id,
    required this.name,
    required this.balance,
    required this.annualInterestRate,
    required this.minimumPayment,
  });
}

class DebtPayoffResult {
  final DebtStrategy strategy;
  final int totalMonths;
  final double totalInterestPaid;
  final double monthlyPayment;

  const DebtPayoffResult({
    required this.strategy,
    required this.totalMonths,
    required this.totalInterestPaid,
    required this.monthlyPayment,
  });
}
