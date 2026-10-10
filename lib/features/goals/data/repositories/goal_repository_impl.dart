import '../../domain/models/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_dao.dart';

class GoalRepositoryImpl implements IGoalRepository {
  final GoalDao _dao;

  GoalRepositoryImpl(this._dao);

  @override
  Stream<List<Goal>> watchGoals() => _dao.watchGoals();

  @override
  Future<List<Goal>> getGoals() => _dao.getGoals();

  @override
  Future<Goal?> getGoalById(String id) => _dao.getGoalById(id);

  @override
  Future<void> createGoal(Goal goal) => _dao.insertGoal(goal);

  @override
  Future<void> updateGoal(Goal goal) => _dao.updateGoal(goal);

  @override
  Future<void> deleteGoal(String id) => _dao.deleteGoal(id);

  @override
  Future<void> addContribution(String goalId, double amount) async {
    final goal = await _dao.getGoalById(goalId);
    if (goal != null) {
      await _dao.updateGoal(goal.copyWith(
        currentAmount: goal.currentAmount + amount,
      ));
    }
  }
}
