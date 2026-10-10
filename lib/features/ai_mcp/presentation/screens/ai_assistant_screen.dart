import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../domain/models/mcp_tool.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _inputCtrl = TextEditingController();
  final _messages = <_ChatMessage>[];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        isUser: false,
        text: '👋 Hello! I am Mony AI. I am connected to your local database via the MCP 2 tool calling protocol. You can ask me to record transactions, check your net worth, or analyze your spending habits.',
      ),
    );
  }

  Future<void> _handleUserMessage(String query) async {
    if (query.trim().isEmpty) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: query));
      _isProcessing = true;
    });

    final mcp = ref.read(mcpServerRepositoryProvider);
    final lower = query.toLowerCase();

    try {
      McpToolResult result;

      // Smart tool dispatching based on intent
      if (lower.contains('net worth') || lower.contains('balance')) {
        result = await mcp.executeToolCall(toolName: 'mony.get_net_worth', arguments: {});
      } else if (lower.contains('summary') || lower.contains('spending') || lower.contains('spent')) {
        result = await mcp.executeToolCall(toolName: 'mony.get_summary', arguments: {});
      } else if (lower.contains('pattern') || lower.contains('insight')) {
        result = await mcp.executeToolCall(toolName: 'mony.analyze_patterns', arguments: {});
      } else if (lower.contains('portfolio') || lower.contains('stocks') || lower.contains('invest')) {
        result = await mcp.executeToolCall(toolName: 'mony.list_assets', arguments: {});
      } else if (lower.contains('add') || lower.contains('spent') || lower.contains('bought')) {
        // Natural language transaction extraction heuristic
        final amountMatch = RegExp(r'\d+').firstMatch(query);
        final amount = amountMatch != null ? double.parse(amountMatch.group(0)!) : 100.0;
        final name = query.replaceAll(RegExp(r'\d+'), '').replaceAll('add', '').replaceAll('spent', '').trim();

        result = await mcp.executeToolCall(
          toolName: 'mony.add_transaction',
          arguments: {
            'amount': amount,
            'name': name.isNotEmpty ? name : 'Manual Entry',
            'type': 'expense',
          },
        );
      } else {
        result = await mcp.executeToolCall(toolName: 'mony.list_transactions', arguments: {'limit': 5});
      }

      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: result.text));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: 'Error executing MCP tool: $e'));
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mcp = ref.watch(mcpServerRepositoryProvider);
    final tools = mcp.getRegisteredTools();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mony AI • MCP 2 Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.api_outlined),
            tooltip: 'View Registered MCP Tools',
            onPressed: () => _showToolsDialog(context, tools),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                const Icon(Icons.hub_outlined, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MCP 2 Server Active on localhost:7432 • 8 Tools Exposed',
                    style: TextStyle(color: Colors.indigo.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: m.isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(
                        color: m.isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          // Input Bar & Prompt Chips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('Check Net Worth'),
                        onPressed: () => _handleUserMessage('What is my total net worth?'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Monthly Summary'),
                        onPressed: () => _handleUserMessage('Show me my monthly spending summary'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Spending Patterns'),
                        onPressed: () => _handleUserMessage('Analyze my spending patterns'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Portfolio Returns'),
                        onPressed: () => _handleUserMessage('List my portfolio investments'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ask Mony AI or call an MCP tool...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onSubmitted: _handleUserMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _handleUserMessage(_inputCtrl.text),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showToolsDialog(BuildContext context, List<McpTool> tools) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registered MCP 2 Tools'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: tools.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final t = tools[i];
              return ListTile(
                dense: true,
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${t.description}\nScope: ${t.requiredScope}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;

  const _ChatMessage({required this.isUser, required this.text});
}
