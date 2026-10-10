import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/domain/usecases/transaction_usecases.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../goals/domain/repositories/goal_repository.dart';
import '../../../analytics/domain/repositories/analytics_repository.dart';
import '../../../portfolio/domain/repositories/portfolio_repository.dart';
import '../../domain/models/mcp_tool.dart';
import '../../domain/repositories/mcp_server_repository.dart';

class McpServerRepositoryImpl implements IMcpServerRepository {
  final AddTransactionUseCase _addTxnUseCase;
  final ITransactionRepository _txnRepo;
  final IAccountRepository _accountRepo;
  final ICategoryRepository _categoryRepo;
  final IBudgetRepository _budgetRepo;
  final IGoalRepository _goalRepo;
  final IAnalyticsRepository _analyticsRepo;
  final IPortfolioRepository _portfolioRepo;

  McpServerRepositoryImpl(
    this._addTxnUseCase,
    this._txnRepo,
    this._accountRepo,
    this._categoryRepo,
    this._budgetRepo,
    this._goalRepo,
    this._analyticsRepo,
    this._portfolioRepo,
  );

  @override
  List<McpTool> getRegisteredTools() => _tools;

  @override
  Future<Map<String, dynamic>> handleJsonRpcRequest(Map<String, dynamic> request) async {
    final id = request['id'];
    final method = request['method'];
    final params = request['params'] as Map<String, dynamic>? ?? {};

    try {
      if (method == 'tools/list') {
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'tools': _tools.map((t) => t.toJson()).toList(),
          },
        };
      }

      if (method == 'tools/call') {
        final toolName = params['name'] as String;
        final args = params['arguments'] as Map<String, dynamic>? ?? {};
        final res = await executeToolCall(toolName: toolName, arguments: args);
        return {
          'jsonrpc': '2.0',
          'id': id,
          'result': res.toJson(),
        };
      }

      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': -32601, 'message': 'Method not found: $method'},
      };
    } catch (e) {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': -32000, 'message': e.toString()},
      };
    }
  }

  @override
  Future<McpToolResult> executeToolCall({
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    switch (toolName) {
      // 1. Add Transaction
      case 'mony.add_transaction':
        final amount = (arguments['amount'] as num).toDouble();
        final name = arguments['name'] as String;
        final typeStr = arguments['type'] as String? ?? 'expense';
        final type = TransactionType.fromString(typeStr);

        final accounts = await _accountRepo.getAllAccounts();
        final accountId = arguments['account_id'] as String? ?? (accounts.isNotEmpty ? accounts.first.id : 'acc-primary-bank');

        final txn = await _addTxnUseCase.execute(
          accountId: accountId,
          amount: amount,
          currencyCode: 'INR',
          type: type,
          name: name,
          date: arguments['date'] != null ? DateTime.parse(arguments['date']) : DateTime.now(),
          description: arguments['description'],
        );
        return McpToolResult.success('Successfully added ${txn.type.name} of ₹${txn.amount.toStringAsFixed(2)} for "${txn.name}".', {
          'id': txn.id,
          'amount': txn.amount,
          'type': txn.type.name,
        });

      // 2. List Transactions
      case 'mony.list_transactions':
        final txns = await _txnRepo.getTransactions();
        final limit = (arguments['limit'] as num?)?.toInt() ?? 10;
        final preview = txns.take(limit).map((t) => {
              'id': t.id,
              'name': t.name,
              'amount': t.amount,
              'type': t.type.name,
              'date': t.date.toIso8601String().substring(0, 10),
            }).toList();
        return McpToolResult.success('Retrieved ${preview.length} transactions.', {'transactions': preview});

      // 3. Get Spending Summary
      case 'mony.get_summary':
        final summary = await _txnRepo.getSummary();
        return McpToolResult.success(
          'Total Income: ₹${summary.totalIncome.toStringAsFixed(2)}, Total Expense: ₹${summary.totalExpense.toStringAsFixed(2)}, Savings Rate: ${summary.savingsRate.toStringAsFixed(1)}%.',
          {
            'total_income': summary.totalIncome,
            'total_expense': summary.totalExpense,
            'net_savings': summary.netSavings,
            'savings_rate': summary.savingsRate,
          },
        );

      // 4. Get Aggregate Net Worth
      case 'mony.get_net_worth':
        final netWorth = await _portfolioRepo.getAggregateNetWorth();
        return McpToolResult.success(
          'Current Total Net Worth across cash accounts and investment assets: ₹${netWorth.toStringAsFixed(2)}.',
          {'net_worth': netWorth},
        );

      // 5. List Accounts
      case 'mony.list_accounts':
        final accs = await _accountRepo.getAllAccounts();
        final list = accs.map((a) => {
              'id': a.id,
              'name': a.name,
              'type': a.type.name,
              'balance': a.currentBalance,
            }).toList();
        return McpToolResult.success('Found ${list.length} accounts.', {'accounts': list});

      // 6. Get Budget Statuses
      case 'mony.get_budget_status':
        final budgets = await _budgetRepo.getBudgets();
        return McpToolResult.success('Found ${budgets.length} configured budgets.', {
          'budgets': budgets.map((b) => {'id': b.id, 'amount': b.amount, 'period': b.period.name}).toList(),
        });

      // 7. Analyze Patterns
      case 'mony.analyze_patterns':
        final insights = await _analyticsRepo.generateInsights();
        return McpToolResult.success('Generated ${insights.length} pattern insights.', {
          'insights': insights.map((i) => {'title': i.title, 'description': i.description}).toList(),
        });

      // 8. List Portfolio Assets
      case 'mony.list_assets':
        final assets = await _portfolioRepo.getAssets();
        return McpToolResult.success('Retrieved ${assets.length} portfolio assets.', {
          'assets': assets.map((a) => {'name': a.name, 'value': a.currentValue, 'cagr': a.cagr}).toList(),
        });

      default:
        return McpToolResult.error('Unknown tool: $toolName');
    }
  }

  static const List<McpTool> _tools = [
    McpTool(
      name: 'mony.add_transaction',
      description: 'Record an income, expense, or transfer transaction in Mony.',
      requiredScope: 'write:transactions',
      inputSchema: {
        'type': 'object',
        'required': ['amount', 'name'],
        'properties': {
          'amount': {'type': 'number', 'description': 'Transaction amount in INR'},
          'name': {'type': 'string', 'description': 'Merchant or payee name'},
          'type': {'type': 'string', 'enum': ['expense', 'income', 'transfer']},
          'description': {'type': 'string', 'description': 'Optional memo or notes'},
        },
      },
    ),
    McpTool(
      name: 'mony.list_transactions',
      description: 'Query recent transactions from user ledger.',
      requiredScope: 'read:transactions',
      inputSchema: {
        'type': 'object',
        'properties': {
          'limit': {'type': 'integer', 'description': 'Number of entries to return (default 10)'},
        },
      },
    ),
    McpTool(
      name: 'mony.get_summary',
      description: 'Get overall spending, income, and savings rate summary.',
      requiredScope: 'read:analytics',
      inputSchema: {'type': 'object'},
    ),
    McpTool(
      name: 'mony.get_net_worth',
      description: 'Fetch total comprehensive net worth (Cash + Portfolio Assets).',
      requiredScope: 'read:accounts',
      inputSchema: {'type': 'object'},
    ),
    McpTool(
      name: 'mony.list_accounts',
      description: 'List user bank, cash, and wallet accounts with live balances.',
      requiredScope: 'read:accounts',
      inputSchema: {'type': 'object'},
    ),
    McpTool(
      name: 'mony.get_budget_status',
      description: 'Review spending limit statuses and budget adherence.',
      requiredScope: 'read:budgets',
      inputSchema: {'type': 'object'},
    ),
    McpTool(
      name: 'mony.analyze_patterns',
      description: 'Detect spending anomalies, weekend spikes, and monthly trends.',
      requiredScope: 'read:analytics',
      inputSchema: {'type': 'object'},
    ),
    McpTool(
      name: 'mony.list_assets',
      description: 'Retrieve investment assets with current market valuations and CAGR.',
      requiredScope: 'read:portfolio',
      inputSchema: {'type': 'object'},
    ),
  ];
}
