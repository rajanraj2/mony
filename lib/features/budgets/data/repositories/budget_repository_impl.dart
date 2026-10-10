import '../../domain/models/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_dao.dart';

class BudgetRepositoryImpl implements IBudgetRepository {
  final BudgetDao _dao;

  BudgetRepositoryImpl(this._dao);

  @override
  Stream<List<Budget>> watchBudgets() => _dao.watchBudgets();

  @override
  Future<List<Budget>> getBudgets() => _dao.getBudgets();

  @override
  Future<Budget?> getBudgetById(String id) => _dao.getBudgetById(id);

  @override
  Future<Budget?> getBudgetByCategoryId(String categoryId) =>
      _dao.getBudgetByCategoryId(categoryId);

  @override
  Future<void> createBudget(Budget budget) => _dao.insertBudget(budget);

  @override
  Future<void> updateBudget(Budget budget) => _dao.updateBudget(budget);

  @override
  Future<void> deleteBudget(String id) => _dao.deleteBudget(id);

  @override
  Stream<List<BudgetProgress>> watchBudgetProgresses() =>
      _dao.watchBudgetProgresses();
}
