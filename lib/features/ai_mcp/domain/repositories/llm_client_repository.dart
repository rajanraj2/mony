import '../models/llm_provider_config.dart';

abstract class ILlmClientRepository {
  Stream<LlmProviderConfig?> watchConfig();
  Future<LlmProviderConfig?> getConfig();
  Future<void> saveConfig(LlmProviderConfig config);
  Future<void> clearConfig();

  /// Sends a natural language prompt to the user-configured LLM with Mony tools attached,
  /// executing required MCP tools automatically and returning the model's final response.
  Future<String> sendPrompt({
    required String userPrompt,
    List<Map<String, String>> conversationHistory,
  });
}
