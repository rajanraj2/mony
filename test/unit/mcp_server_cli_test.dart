import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mony/core/database/database.dart';
import 'package:mony/features/accounts/data/datasources/account_dao.dart';
import 'package:mony/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:mony/features/ai_mcp/data/repositories/mcp_server_repository_impl.dart';
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
  group('Headless MCP Server JSON-RPC Protocol Tests', () {
    late AppDatabase db;
    late McpServerRepositoryImpl mcpServer;

    setUp(() {
      db = AppDatabase();
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

      mcpServer = McpServerRepositoryImpl(
        addTxnUseCase,
        txnRepo,
        accountRepo,
        categoryRepo,
        budgetRepo,
        goalRepo,
        analyticsRepo,
        portfolioRepo,
      );
    });

    test('tools/list returns 8 compliant tool definitions', () async {
      final request = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'tools/list',
      };

      final response = await mcpServer.handleJsonRpcRequest(request);
      expect(response['jsonrpc'], equals('2.0'));
      expect(response['id'], equals(1));
      expect(response['result'], isNotNull);

      final tools = response['result']['tools'] as List;
      expect(tools.length, equals(8));
      expect(tools.any((t) => t['name'] == 'mony.add_transaction'), isTrue);
      expect(tools.any((t) => t['name'] == 'mony.get_net_worth'), isTrue);
    });

    test('tools/call mony.get_net_worth returns formatted JSON-RPC content', () async {
      final request = {
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/call',
        'params': {
          'name': 'mony.get_net_worth',
          'arguments': {},
        },
      };

      final response = await mcpServer.handleJsonRpcRequest(request);
      expect(response['id'], equals(2));
      expect(response['result'], isNotNull);
      expect(response['result']['isError'], isFalse);

      final content = response['result']['content'] as List;
      expect(content.first['text'], contains('Current Total Net Worth'));
    });
  });
}
