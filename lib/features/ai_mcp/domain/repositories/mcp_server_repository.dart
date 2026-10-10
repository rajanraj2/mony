import '../models/mcp_tool.dart';

abstract class IMcpServerRepository {
  List<McpTool> getRegisteredTools();

  Future<McpToolResult> executeToolCall({
    required String toolName,
    required Map<String, dynamic> arguments,
  });

  Future<Map<String, dynamic>> handleJsonRpcRequest(Map<String, dynamic> request);
}
