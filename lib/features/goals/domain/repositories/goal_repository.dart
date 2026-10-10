import '../models/goal.dart';

abstract class IGoalRepository {
  Stream<List<Goal>> watchGoals();
  Future<List<Goal>> getGoals();
  Future<Goal?> getGoalById(String id);
  Future<void> createGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> deleteGoal(String id);
  Future<void> addContribution(String goalId, double amount);
}
