/// API key management.
///
/// Keys are loaded from environment variables at build time.
/// NEVER hardcode API keys in source code.
///
/// To build with keys, use:
/// ```
/// flutter build apk \
///   --dart-define=OPENAI_API_KEY=sk-xxx \
///   --dart-define=ANTHROPIC_API_KEY=sk-ant-xxx \
///   --dart-define=GOOGLE_CLOUD_KEY=xxx \
///   --dart-define=AZURE_SPEECH_KEY=xxx
/// ```
class ApiKeys {
  ApiKeys._();

  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  static const String anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

  static const String googleCloudKey = String.fromEnvironment(
    'GOOGLE_CLOUD_KEY',
    defaultValue: '',
  );

  static const String azureSpeechKey = String.fromEnvironment(
    'AZURE_SPEECH_KEY',
    defaultValue: '',
  );

  /// Validate that required keys are present
  static bool get hasOpenAiKey => openaiApiKey.isNotEmpty;
  static bool get hasAnthropicKey => anthropicApiKey.isNotEmpty;
  static bool get hasGoogleKey => googleCloudKey.isNotEmpty;
  static bool get hasAzureKey => azureSpeechKey.isNotEmpty;

  /// Check if the primary pipeline (OpenAI Realtime) is configured
  static bool get isPrimaryPipelineReady => hasOpenAiKey;

  /// Check if the fallback pipeline is fully configured
  static bool get isFallbackPipelineReady =>
      hasAnthropicKey && hasGoogleKey && hasAzureKey;
}
