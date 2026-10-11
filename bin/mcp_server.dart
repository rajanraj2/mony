import 'dart:convert';
import 'dart:io';

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

void main(List<String> args) async {
  // Headless CLI runner: communicates strictly over stdio using JSON-RPC 2.0
  final db = AppDatabase();

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

  // Listen to stdin line by line (JSON-RPC 2.0 stdio transport)
  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) async {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;

    try {
      final jsonRequest = jsonDecode(trimmed) as Map<String, dynamic>;
      final response = await mcpServer.handleJsonRpcRequest(jsonRequest);
      stdout.writeln(jsonEncode(response));
    } catch (e) {
      final errResponse = {
        'jsonrpc': '2.0',
        'id': null,
        'error': {'code': -32700, 'message': 'Parse error: $e'},
      };
      stdout.writeln(jsonEncode(errResponse));
    }
  });
}
