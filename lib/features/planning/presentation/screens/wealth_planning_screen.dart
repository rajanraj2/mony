import '../../../../shared/widgets/editable_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/planning_models.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';

class WealthPlanningScreen extends ConsumerStatefulWidget {
  const WealthPlanningScreen({super.key});

  @override
  ConsumerState<WealthPlanningScreen> createState() => _WealthPlanningScreenState();
}

class _WealthPlanningScreenState extends ConsumerState<WealthPlanningScreen> {
  // FIRE Inputs
  double _currentAge = 28;
  double _retirementAge = 50;
  double _monthlyExpenses = 50000;
  double _inflation = 6.0;
  double _expectedReturn = 12.0;

  // Scenario Modeling Input
  double _cutExpensesAmount = 5000;

  @override
  Widget build(BuildContext context) {
    final netWorthAsync = ref.watch(aggregateNetWorthProvider);
    final currentNetWorth = netWorthAsync.value ?? 0.0;

    final repo = ref.watch(planningRepositoryProvider);

    final fireResult = repo.calculateFirePlan(
      FirePlanInput(
        currentAge: _currentAge.toInt(),
        targetRetirementAge: _retirementAge.toInt(),
        currentMonthlyExpenses: _monthlyExpenses,
        inflationRate: _inflation,
        expectedReturn: _expectedReturn,
        currentNetWorth: currentNetWorth,
      ),
    );

    final compound10Y = repo.calculateCompoundSavingsScenario(
      monthlyReduction: _cutExpensesAmount,
      years: 10,
      annualReturn: _expectedReturn,
    );

    final compound20Y = repo.calculateCompoundSavingsScenario(
      monthlyReduction: _cutExpensesAmount,
      years: 20,
      annualReturn: _expectedReturn,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Wealth Planning & FIRE Studio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FIRE Hero Banner
          Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900, Colors.deepPurple.shade700],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('FIRE Target Corpus', style: TextStyle(color: Colors.white70)),
                      Chip(
                        label: Text(
                          fireResult.isFireAchieved ? '🎉 FIRE Ready!' : '${fireResult.yearsToFire} Years to Target',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        backgroundColor: fireResult.isFireAchieved ? Colors.green : Colors.purple.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${(fireResult.targetCorpus / 10000000).toStringAsFixed(2)} Crores',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Savings Needed', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            '₹${fireResult.requiredMonthlySavings.toStringAsFixed(0)}/mo',
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Future Monthly Spend', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            '₹${fireResult.futureMonthlyExpenses.toStringAsFixed(0)}/mo',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Sliders
          const Text('FIRE Parameter Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  EditableSlider(
                    label: 'Target Retirement Age',
                    value: _retirementAge,
                    min: _currentAge + 1,
                    max: 75,
                    suffix: ' yrs',
                    onChanged: (v) => setState(() => _retirementAge = v),
                  ),
                  EditableSlider(
                    label: 'Current Monthly Expenses',
                    value: _monthlyExpenses,
                    min: 15000,
                    max: 300000,
                    prefix: '₹',
                    onChanged: (v) => setState(() => _monthlyExpenses = v),
                  ),
                  EditableSlider(
                    label: 'Expected Portfolio Return',
                    value: _expectedReturn,
                    min: 8.0,
                    max: 16.0,
                    suffix: '%',
                    decimalDigits: 1,
                    onChanged: (v) => setState(() => _expectedReturn = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // What-If Scenario Analysis
          const Text('What-If Scenario Modeling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If you cut discretionary expenses by ₹${_cutExpensesAmount.toInt()}/month and invest it:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  EditableSlider(
                    label: 'Monthly Reduction Amount',
                    value: _cutExpensesAmount,
                    min: 1000,
                    max: 25000,
                    prefix: '₹',
                    onChanged: (v) => setState(() => _cutExpensesAmount = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ScenarioResultBox(years: 10, amount: compound10Y),
                      _ScenarioResultBox(years: 20, amount: compound20Y),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double? step;
  final String display;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(display, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ScenarioResultBox extends StatelessWidget {
  final int years;
  final double amount;

  const _ScenarioResultBox({required this.years, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$years-Year Wealth Impact', style: TextStyle(color: Colors.purple.shade800, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '₹${(amount / 100000).toStringAsFixed(1)} Lakhs',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
          ),
        ],
      ),
    );
  }
}
