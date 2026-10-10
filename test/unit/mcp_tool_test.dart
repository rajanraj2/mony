import 'package:flutter_test/flutter_test.dart';
import 'package:mony/features/ai_mcp/domain/models/mcp_tool.dart';

void main() {
  group('MCP Tool and Protocol Tests', () {
    test('McpTool serializes to valid MCP JSON schema specification', () {
      const tool = McpTool(
        name: 'mony.add_transaction',
        description: 'Record an income or expense transaction in Mony.',
        requiredScope: 'write:transactions',
        inputSchema: {
          'type': 'object',
          'required': ['amount', 'name'],
          'properties': {
            'amount': {'type': 'number'},
            'name': {'type': 'string'},
          },
        },
      );

      final json = tool.toJson();
      expect(json['name'], equals('mony.add_transaction'));
      expect(json['description'], isNotEmpty);
      expect(json['inputSchema'], isA<Map<String, dynamic>>());
      expect((json['inputSchema'] as Map)['required'], contains('amount'));
    });

    test('McpToolResult structures content array according to MCP spec', () {
      final success = McpToolResult.success('Transaction created successfully', {'id': 'txn-123'});
      final json = success.toJson();

      expect(json['isError'], isFalse);
      expect(json['content'], isList);
      expect((json['content'] as List).first['text'], contains('Transaction created successfully'));
      expect(json['data']['id'], equals('txn-123'));
    });

    test('McpToolResult error formatting', () {
      final err = McpToolResult.error('Insufficient parameters provided');
      final json = err.toJson();

      expect(json['isError'], isTrue);
      expect((json['content'] as List).first['text'], equals('Insufficient parameters provided'));
    });
  });
}
