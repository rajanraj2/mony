enum LlmVendor {
  openai,
  anthropic,
  gemini,
  customOpenAiCompatible;

  String get displayName {
    switch (this) {
      case LlmVendor.openai:
        return 'OpenAI (GPT-4o / GPT-4o-mini)';
      case LlmVendor.anthropic:
        return 'Anthropic (Claude 3.5 Sonnet)';
      case LlmVendor.gemini:
        return 'Google Gemini (Gemini 1.5 Pro/Flash)';
      case LlmVendor.customOpenAiCompatible:
        return 'Custom / Local (Ollama / OpenRouter / Groq)';
    }
  }

  String get defaultModel {
    switch (this) {
      case LlmVendor.openai:
        return 'gpt-4o';
      case LlmVendor.anthropic:
        return 'claude-3-5-sonnet-20241022';
      case LlmVendor.gemini:
        return 'gemini-1.5-pro';
      case LlmVendor.customOpenAiCompatible:
        return 'llama3';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case LlmVendor.openai:
        return 'https://api.openai.com/v1';
      case LlmVendor.anthropic:
        return 'https://api.anthropic.com/v1';
      case LlmVendor.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case LlmVendor.customOpenAiCompatible:
        return 'http://localhost:11434/v1';
    }
  }
}

class LlmProviderConfig {
  final LlmVendor vendor;
  final String apiKey;
  final String modelName;
  final String? customBaseUrl;
  final bool isEnabled;

  const LlmProviderConfig({
    required this.vendor,
    required this.apiKey,
    required this.modelName,
    this.customBaseUrl,
    this.isEnabled = true,
  });

  String get effectiveBaseUrl => customBaseUrl ?? vendor.defaultBaseUrl;

  LlmProviderConfig copyWith({
    LlmVendor? vendor,
    String? apiKey,
    String? modelName,
    String? customBaseUrl,
    bool? isEnabled,
  }) {
    return LlmProviderConfig(
      vendor: vendor ?? this.vendor,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
