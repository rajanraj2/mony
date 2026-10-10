class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final String requiredScope;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.requiredScope,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
      };
}

class McpToolResult {
  final bool isError;
  final String text;
  final Map<String, dynamic>? data;

  const McpToolResult({
    required this.isError,
    required this.text,
    this.data,
  });

  factory McpToolResult.success(String text, [Map<String, dynamic>? data]) =>
      McpToolResult(isError: false, text: text, data: data);

  factory McpToolResult.error(String message) =>
      McpToolResult(isError: true, text: message);

  Map<String, dynamic> toJson() => {
        'content': [
          {
            'type': 'text',
            'text': text,
          }
        ],
        if (data != null) 'data': data,
        'isError': isError,
      };
}
