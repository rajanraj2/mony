import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/models/llm_provider_config.dart';
import '../../domain/repositories/llm_client_repository.dart';
import '../../domain/repositories/mcp_server_repository.dart';

class LlmClientRepositoryImpl implements ILlmClientRepository {
  final IMcpServerRepository _mcpServer;
  final Dio _dio;
  final _configController = StreamController<LlmProviderConfig?>.broadcast();
  LlmProviderConfig? _currentConfig;

  LlmClientRepositoryImpl(this._mcpServer, [Dio? dio]) : _dio = dio ?? Dio();

  @override
  Stream<LlmProviderConfig?> watchConfig() => _configController.stream;

  @override
  Future<LlmProviderConfig?> getConfig() async => _currentConfig;

  @override
  Future<void> saveConfig(LlmProviderConfig config) async {
    _currentConfig = config;
    _configController.add(_currentConfig);
  }

  @override
  Future<void> clearConfig() async {
    _currentConfig = null;
    _configController.add(null);
  }

  @override
  Future<String> sendPrompt({
    required String userPrompt,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    final cfg = _currentConfig;
    if (cfg == null || cfg.apiKey.trim().isEmpty) {
      return _localFallbackProcessor(userPrompt);
    }

    final detected = cfg.detected;

    try {
      final tools = _mcpServer.getRegisteredTools();

      // Anthropic Native Messages API
      if (detected.vendor == LlmVendor.anthropic) {
        return await _callAnthropic(cfg, detected, tools, userPrompt);
      }

      // OpenAI / Groq / OpenRouter / Ollama (Universal OpenAI-Compatible API)
      return await _callOpenAiCompatible(cfg, detected, tools, userPrompt, conversationHistory);
    } catch (e) {
      final fallbackResult = await _localFallbackProcessor(userPrompt);
      return '⚠️ (Model API error: $e)\n\n$fallbackResult';
    }
  }

  Future<String> _callOpenAiCompatible(
    LlmProviderConfig cfg,
    DetectedConfig detected,
    List tools,
    String userPrompt,
    List<Map<String, String>> history,
  ) async {
    final openAiTools = tools.map((t) => {
          'type': 'function',
          'function': {
            'name': t.name,
            'description': t.description,
            'parameters': t.inputSchema,
          },
        }).toList();

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': 'You are Mony AI, an intelligent personal financial assistant. You have access to local tools to manage expenses, check net worth, review budgets, and analyze spending. When user requests finance actions, invoke the appropriate tools.',
      },
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': userPrompt},
    ];

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (detected.headerType == 'bearer') {
      headers['Authorization'] = 'Bearer ${cfg.apiKey.trim()}';
    }

    final response = await _dio.post(
      '${cfg.effectiveBaseUrl}/chat/completions',
      options: Options(headers: headers),
      data: {
        'model': cfg.effectiveModel,
        'messages': messages,
        'tools': openAiTools,
        'tool_choice': 'auto',
      },
    );

    final choice = response.data['choices'][0]['message'];

    // Tool execution loop
    if (choice['tool_calls'] != null && (choice['tool_calls'] as List).isNotEmpty) {
      final toolCalls = choice['tool_calls'] as List;
      messages.add(choice);

      for (final tc in toolCalls) {
        final fn = tc['function'];
        final toolName = fn['name'] as String;
        final args = fn['arguments'] is String ? jsonDecode(fn['arguments']) as Map<String, dynamic> : fn['arguments'] as Map<String, dynamic>;

        final toolResult = await _mcpServer.executeToolCall(
          toolName: toolName,
          arguments: args,
        );

        messages.add({
          'role': 'tool',
          'tool_call_id': tc['id'],
          'name': toolName,
          'content': toolResult.text,
        });
      }

      final secondResponse = await _dio.post(
        '${cfg.effectiveBaseUrl}/chat/completions',
        options: Options(headers: headers),
        data: {
          'model': cfg.effectiveModel,
          'messages': messages,
        },
      );

      return secondResponse.data['choices'][0]['message']['content'] ?? 'Done.';
    }

    return choice['content'] ?? 'Done.';
  }

  Future<String> _callAnthropic(
    LlmProviderConfig cfg,
    DetectedConfig detected,
    List tools,
    String userPrompt,
  ) async {
    final anthropicTools = tools.map((t) => {
          'name': t.name,
          'description': t.description,
          'input_schema': t.inputSchema,
        }).toList();

    final response = await _dio.post(
      'https://api.anthropic.com/v1/messages',
      options: Options(
        headers: {
          'x-api-key': cfg.apiKey.trim(),
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
      ),
      data: {
        'model': cfg.effectiveModel,
        'max_tokens': 1024,
        'system': 'You are Mony AI, an intelligent personal financial assistant. Use provided tools to query or record transactions.',
        'messages': [
          {'role': 'user', 'content': userPrompt}
        ],
        'tools': anthropicTools,
      },
    );

    final contentBlocks = response.data['content'] as List;
    final textBlocks = contentBlocks.where((b) => b['type'] == 'text').map((b) => b['text']).join('\n');
    final toolUseBlocks = contentBlocks.where((b) => b['type'] == 'tool_use');

    if (toolUseBlocks.isNotEmpty) {
      final results = <String>[];
      for (final tu in toolUseBlocks) {
        final res = await _mcpServer.executeToolCall(
          toolName: tu['name'] as String,
          arguments: tu['input'] as Map<String, dynamic>,
        );
        results.add(res.text);
      }
      return '${textBlocks.isNotEmpty ? "$textBlocks\n\n" : ""}${results.join('\n')}';
    }

    return textBlocks;
  }

  Future<String> _localFallbackProcessor(String prompt) async {
    final lower = prompt.toLowerCase();
    if (lower.contains('net worth') || lower.contains('balance')) {
      final res = await _mcpServer.executeToolCall(toolName: 'mony.get_net_worth', arguments: {});
      return res.text;
    } else if (lower.contains('summary') || lower.contains('spent')) {
      final res = await _mcpServer.executeToolCall(toolName: 'mony.get_summary', arguments: {});
      return res.text;
    } else if (lower.contains('pattern') || lower.contains('spike')) {
      final res = await _mcpServer.executeToolCall(toolName: 'mony.analyze_patterns', arguments: {});
      return res.text;
    }
    final res = await _mcpServer.executeToolCall(toolName: 'mony.list_transactions', arguments: {'limit': 5});
    return res.text;
  }
}
