import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/budget.dart';

final budgetListProvider = StreamProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchBudgets();
});

final budgetProgressListProvider = StreamProvider<List<BudgetProgress>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchBudgetProgresses();
});
