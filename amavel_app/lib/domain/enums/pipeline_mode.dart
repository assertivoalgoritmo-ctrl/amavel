/// Which voice pipeline to use for conversation.
enum PipelineMode {
  /// OpenAI Realtime API — single WebSocket call for voice-to-voice
  /// Lowest latency (~200ms), recommended for production
  openaiRealtime,

  /// Traditional pipeline: Google STT → Anthropic Claude → Azure TTS
  /// Higher latency (~1-2s) but supports Claude as LLM
  traditional,
}

extension PipelineModeExtension on PipelineMode {
  String get displayName {
    switch (this) {
      case PipelineMode.openaiRealtime:
        return 'OpenAI Realtime';
      case PipelineMode.traditional:
        return 'Google + Claude + Azure';
    }
  }
}
