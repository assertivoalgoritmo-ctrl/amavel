import 'package:amavel_app/domain/enums/pipeline_mode.dart';

/// Application configuration.
/// In production, these values come from Firebase Remote Config.
class AppConfig {
  AppConfig._();

  /// Current voice pipeline mode
  static PipelineMode pipelineMode = PipelineMode.openaiRealtime;

  /// App language
  static const String defaultLanguage = 'pt-PT';

  /// OpenAI Realtime API
  static const String openaiRealtimeUrl =
      'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview';
  static const String openaiRealtimeModel = 'gpt-4o-realtime-preview';

  /// OpenAI voice options: alloy, echo, fable, onyx, nova, shimmer
  static const String openaiVoice = 'nova';

  /// Audio format for OpenAI Realtime
  static const String audioFormat = 'pcm16';
  static const int sampleRate = 24000;
  static const int channels = 1;
  static const int bitsPerSample = 16;

  /// Anthropic Claude API (fallback pipeline)
  static const String anthropicApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String anthropicModel = 'claude-sonnet-4-20250514';

  /// Google Cloud Speech-to-Text (fallback pipeline)
  static const String googleSttUrl =
      'https://speech.googleapis.com/v1/speech:recognize';
  static const String googleSttLanguage = 'pt-PT';

  /// Azure Speech Services (fallback pipeline)
  static const String azureTtsRegion = 'westeurope';
  static const String azureTtsVoice = 'pt-PT-FernandaNeural';

  /// Firebase
  static const String firestoreRegion = 'europe-west1';

  /// Memory
  static const int maxMemoryFactsInPrompt = 30;
  static const double memoryConfidenceThreshold = 0.7;

  /// Guardrails
  static const double distressAlertThreshold = 0.6;
  static const int maxConversationDurationMinutes = 60;

  /// Assistant identity
  static const String assistantName = 'AMAVEL';
  static const String assistantNamePronunciation = 'Amável';

  /// UI
  static const double voiceActivityThreshold = 0.5;
  static const int silenceDurationMs = 800;

  /// Feature flags
  static bool memoryEnabled = true;
  static bool alertsEnabled = true;
  static bool familyMessagingEnabled = true;
}
