import '../models/budget.dart';

abstract class IBudgetRepository {
  Stream<List<Budget>> watchBudgets();
  Future<List<Budget>> getBudgets();
  Future<Budget?> getBudgetById(String id);
  Future<Budget?> getBudgetByCategoryId(String categoryId);
  Future<void> createBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String id);
  Stream<List<BudgetProgress>> watchBudgetProgresses();
}
