enum LlmVendor {
  autoDetected,
  openai,
  anthropic,
  gemini,
  openrouter,
  groq,
  ollama;

  String get displayName {
    switch (this) {
      case LlmVendor.autoDetected:
        return 'Auto-Detected Provider';
      case LlmVendor.openai:
        return 'OpenAI';
      case LlmVendor.anthropic:
        return 'Anthropic';
      case LlmVendor.gemini:
        return 'Google Gemini';
      case LlmVendor.openrouter:
        return 'OpenRouter';
      case LlmVendor.groq:
        return 'Groq Cloud';
      case LlmVendor.ollama:
        return 'Local Ollama';
    }
  }

  /// Auto-detect vendor, endpoint, and default model directly from key signature
  static DetectedConfig detectFromKey(String key, [String? optionalModel]) {
    final cleanKey = key.trim();

    // 1. Anthropic (sk-ant-...)
    if (cleanKey.startsWith('sk-ant-')) {
      return DetectedConfig(
        vendor: LlmVendor.anthropic,
        baseUrl: 'https://api.anthropic.com/v1',
        model: optionalModel != null && optionalModel.isNotEmpty ? optionalModel : 'claude-3-5-sonnet-20241022',
        headerType: 'anthropic',
      );
    }

    // 2. Google Gemini (AIzaSy...)
    if (cleanKey.startsWith('AIzaSy')) {
      return DetectedConfig(
        vendor: LlmVendor.gemini,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        model: optionalModel != null && optionalModel.isNotEmpty ? optionalModel : 'gemini-1.5-pro',
        headerType: 'gemini',
      );
    }

    // 3. OpenRouter (sk-or-v1-...)
    if (cleanKey.startsWith('sk-or-')) {
      return DetectedConfig(
        vendor: LlmVendor.openrouter,
        baseUrl: 'https://openrouter.ai/api/v1',
        model: optionalModel != null && optionalModel.isNotEmpty ? optionalModel : 'auto',
        headerType: 'bearer',
      );
    }

    // 4. Groq (gsk_...)
    if (cleanKey.startsWith('gsk_')) {
      return DetectedConfig(
        vendor: LlmVendor.groq,
        baseUrl: 'https://api.groq.com/openai/v1',
        model: optionalModel != null && optionalModel.isNotEmpty ? optionalModel : 'llama-3.3-70b-versatile',
        headerType: 'bearer',
      );
    }

    // 5. Local / Ollama (empty key or localhost)
    if (cleanKey.isEmpty || cleanKey.toLowerCase() == 'ollama' || cleanKey.startsWith('http')) {
      return DetectedConfig(
        vendor: LlmVendor.ollama,
        baseUrl: cleanKey.startsWith('http') ? cleanKey : 'http://localhost:11434/v1',
        model: optionalModel != null && optionalModel.isNotEmpty ? optionalModel : 'llama3',
        headerType: 'none',
      );
    }

    // 6. Default to OpenAI (standard sk-...)
    return DetectedConfig(
      vendor: LlmVendor.openai,
      baseUrl: 'https://api.openai.com/v1',
      model: optionalModel != null && optionalModel.isNotEmpty ? optionalModel : 'gpt-4o',
      headerType: 'bearer',
    );
  }
}

class DetectedConfig {
  final LlmVendor vendor;
  final String baseUrl;
  final String model;
  final String headerType; // bearer, anthropic, gemini, none

  const DetectedConfig({
    required this.vendor,
    required this.baseUrl,
    required this.model,
    required this.headerType,
  });
}

class LlmProviderConfig {
  final String apiKey;
  final String? modelName;
  final String? customBaseUrl;
  final bool isEnabled;

  const LlmProviderConfig({
    required this.apiKey,
    this.modelName,
    this.customBaseUrl,
    this.isEnabled = true,
  });

  DetectedConfig get detected => LlmVendor.detectFromKey(apiKey, modelName);

  String get effectiveBaseUrl => customBaseUrl ?? detected.baseUrl;
  String get effectiveModel => modelName != null && modelName!.isNotEmpty ? modelName! : detected.model;
  LlmVendor get vendor => detected.vendor;

  LlmProviderConfig copyWith({
    String? apiKey,
    String? modelName,
    String? customBaseUrl,
    bool? isEnabled,
  }) {
    return LlmProviderConfig(
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
