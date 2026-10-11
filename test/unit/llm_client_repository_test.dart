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
  group('Zero-Config Universal LLM Key Auto-Detection Tests', () {
    test('Auto-detects Anthropic from sk-ant- prefix', () {
      final detected = LlmVendor.detectFromKey('sk-ant-api03-abcdef123456');
      expect(detected.vendor, equals(LlmVendor.anthropic));
      expect(detected.model, equals('claude-3-5-sonnet-20241022'));
      expect(detected.baseUrl, equals('https://api.anthropic.com/v1'));
      expect(detected.headerType, equals('anthropic'));
    });

    test('Auto-detects Google Gemini from AIzaSy prefix', () {
      final detected = LlmVendor.detectFromKey('AIzaSyAbCdEf123456');
      expect(detected.vendor, equals(LlmVendor.gemini));
      expect(detected.model, equals('gemini-1.5-pro'));
      expect(detected.baseUrl, equals('https://generativelanguage.googleapis.com/v1beta'));
    });

    test('Auto-detects Groq from gsk_ prefix', () {
      final detected = LlmVendor.detectFromKey('gsk_abcdef1234567890');
      expect(detected.vendor, equals(LlmVendor.groq));
      expect(detected.model, equals('llama-3.3-70b-versatile'));
      expect(detected.baseUrl, equals('https://api.groq.com/openai/v1'));
    });

    test('Auto-detects OpenRouter from sk-or- prefix', () {
      final detected = LlmVendor.detectFromKey('sk-or-v1-abcdef123456');
      expect(detected.vendor, equals(LlmVendor.openrouter));
      expect(detected.baseUrl, equals('https://openrouter.ai/api/v1'));
    });

    test('Defaults standard sk- keys to OpenAI with gpt-4o', () {
      final detected = LlmVendor.detectFromKey('sk-proj-abcdef123456');
      expect(detected.vendor, equals(LlmVendor.openai));
      expect(detected.model, equals('gpt-4o'));
      expect(detected.baseUrl, equals('https://api.openai.com/v1'));
    });

    test('Auto-detects local Ollama when entering ollama or localhost', () {
      final detected = LlmVendor.detectFromKey('ollama');
      expect(detected.vendor, equals(LlmVendor.ollama));
      expect(detected.baseUrl, equals('http://localhost:11434/v1'));
      expect(detected.model, equals('llama3'));
    });
  });

  group('LLM Client Repository Integration Tests', () {
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

    test('User can save any raw key and Mony activates automatically', () async {
      final config = const LlmProviderConfig(apiKey: 'sk-ant-test12345');
      await llmRepo.saveConfig(config);

      final saved = await llmRepo.getConfig();
      expect(saved, isNotNull);
      expect(saved!.vendor, equals(LlmVendor.anthropic));
      expect(saved.effectiveModel, equals('claude-3-5-sonnet-20241022'));
    });

    test('Local fallback executes when no key is entered', () async {
      final response = await llmRepo.sendPrompt(userPrompt: 'What is my current net worth?');
      expect(response, contains('Current Total Net Worth'));
    });
  });
}
