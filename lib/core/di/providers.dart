import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../../features/accounts/data/datasources/account_dao.dart';
import '../../features/accounts/data/repositories/account_repository_impl.dart';
import '../../features/accounts/domain/repositories/account_repository.dart';
import '../../features/categories/data/datasources/category_dao.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/transactions/data/datasources/transaction_dao.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/transactions/domain/usecases/transaction_usecases.dart';
import '../../features/budgets/data/datasources/budget_dao.dart';
import '../../features/budgets/data/repositories/budget_repository_impl.dart';
import '../../features/budgets/domain/repositories/budget_repository.dart';
import '../../features/goals/data/datasources/goal_dao.dart';
import '../../features/goals/data/repositories/goal_repository_impl.dart';
import '../../features/goals/domain/repositories/goal_repository.dart';
import '../../features/analytics/data/repositories/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/sms/data/datasources/sms_dao.dart';
import '../../features/sms/data/repositories/sms_repository_impl.dart';
import '../../features/sms/domain/repositories/sms_repository.dart';
import '../../features/import/data/repositories/import_repository_impl.dart';
import '../../features/import/domain/repositories/import_repository.dart';
import '../../features/portfolio/data/datasources/asset_dao.dart';
import '../../features/portfolio/data/repositories/portfolio_repository_impl.dart';
import '../../features/portfolio/domain/repositories/portfolio_repository.dart';
import '../../features/planning/data/repositories/planning_repository_impl.dart';
import '../../features/planning/domain/repositories/planning_repository.dart';
import '../../features/ai_mcp/data/repositories/mcp_server_repository_impl.dart';
import '../../features/ai_mcp/domain/repositories/mcp_server_repository.dart';

// Database Singleton
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// DAOs
final accountDaoProvider = Provider<AccountDao>((ref) {
  return AccountDao(ref.watch(databaseProvider));
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return CategoryDao(ref.watch(databaseProvider));
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao(ref.watch(databaseProvider));
});

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  return BudgetDao(ref.watch(databaseProvider));
});

final goalDaoProvider = Provider<GoalDao>((ref) {
  return GoalDao(ref.watch(databaseProvider));
});

final smsDaoProvider = Provider<SmsDao>((ref) {
  return SmsDao(ref.watch(databaseProvider));
});

final assetDaoProvider = Provider<AssetDao>((ref) {
  return AssetDao(ref.watch(databaseProvider));
});

// Repositories
final accountRepositoryProvider = Provider<IAccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(accountDaoProvider));
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryDaoProvider));
});

final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(transactionDaoProvider));
});

final budgetRepositoryProvider = Provider<IBudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.watch(budgetDaoProvider));
});

final goalRepositoryProvider = Provider<IGoalRepository>((ref) {
  return GoalRepositoryImpl(ref.watch(goalDaoProvider));
});

final analyticsRepositoryProvider = Provider<IAnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(databaseProvider));
});

final smsRepositoryProvider = Provider<ISmsRepository>((ref) {
  return SmsRepositoryImpl(ref.watch(smsDaoProvider));
});

final importRepositoryProvider = Provider<IImportRepository>((ref) {
  return ImportRepositoryImpl(ref.watch(databaseProvider));
});

final portfolioRepositoryProvider = Provider<IPortfolioRepository>((ref) {
  return PortfolioRepositoryImpl(
    ref.watch(assetDaoProvider),
    ref.watch(accountDaoProvider),
  );
});

final planningRepositoryProvider = Provider<IPlanningRepository>((ref) {
  return PlanningRepositoryImpl();
});

final mcpServerRepositoryProvider = Provider<IMcpServerRepository>((ref) {
  return McpServerRepositoryImpl(
    ref.watch(addTransactionUseCaseProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(budgetRepositoryProvider),
    ref.watch(goalRepositoryProvider),
    ref.watch(analyticsRepositoryProvider),
    ref.watch(portfolioRepositoryProvider),
  );
});

// Use Cases
final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  return AddTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((ref) {
  return UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  return DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider));
});
