import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mony/core/database/database.dart';
import 'package:mony/features/accounts/data/datasources/account_dao.dart';
import 'package:mony/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:mony/features/ai_mcp/data/repositories/mcp_server_repository_impl.dart';
import 'package:mony/features/ai_mcp/data/repositories/llm_client_repository_impl.dart';
import 'package:mony/features/ai_mcp/domain/models/llm_provider_config.dart';
import 'package:mony/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:mony/features/budgets/data/datasources/budget_dao.dart';
import 'package:mony/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:mony/features/categories/data/datasources/category_dao.dart';
import 'package:mony/features/categories/data/repositories/category_repository_impl.dart';
import 'package:mony/features/goals/data/datasources/goal_dao.dart';
import 'package:mony/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:mony/features/portfolio/data/datasources/asset_dao.dart';
import 'package:mony/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:mony/features/transactions/data/datasources/transaction_dao.dart';
import 'package:mony/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mony/features/transactions/domain/usecases/transaction_usecases.dart';

void main() {
  group('User LLM Provider Configuration & Execution Tests', () {
    late AppDatabase db;
    late LlmClientRepositoryImpl llmRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      final accountDao = AccountDao(db);
      final categoryDao = CategoryDao(db);
      final txnDao = TransactionDao(db);
      final budgetDao = BudgetDao(db);
      final goalDao = GoalDao(db);
      final assetDao = AssetDao(db);

      final accountRepo = AccountRepositoryImpl(accountDao);
      final categoryRepo = CategoryRepositoryImpl(categoryDao);
      final txnRepo = TransactionRepositoryImpl(txnDao);
      final budgetRepo = BudgetRepositoryImpl(budgetDao);
      final goalRepo = GoalRepositoryImpl(goalDao);
      final analyticsRepo = AnalyticsRepositoryImpl(db);
      final portfolioRepo = PortfolioRepositoryImpl(assetDao, accountDao);

      final addTxnUseCase = AddTransactionUseCase(txnRepo);

      final mcpServer = McpServerRepositoryImpl(
        addTxnUseCase,
        txnRepo,
        accountRepo,
        categoryRepo,
        budgetRepo,
        goalRepo,
        analyticsRepo,
        portfolioRepo,
      );

      llmRepo = LlmClientRepositoryImpl(mcpServer);
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial LLM config is null (runs in local tool mode)', () async {
      final config = await llmRepo.getConfig();
      expect(config, isNull);
    });

    test('Saves and retrieves custom OpenAI API key config correctly', () async {
      const config = LlmProviderConfig(
        vendor: LlmVendor.openai,
        apiKey: 'sk-proj-test1234567890abcdef',
        modelName: 'gpt-4o',
      );

      await llmRepo.saveConfig(config);
      final saved = await llmRepo.getConfig();

      expect(saved, isNotNull);
      expect(saved!.apiKey, equals('sk-proj-test1234567890abcdef'));
      expect(saved.modelName, equals('gpt-4o'));
      expect(saved.effectiveBaseUrl, equals('https://api.openai.com/v1'));
    });

    test('Falls back gracefully to local MCP execution when no API key configured', () async {
      final response = await llmRepo.sendPrompt(userPrompt: 'What is my current net worth?');
      expect(response, contains('Current Total Net Worth'));
    });
  });
}
