/// Represents the current state of the voice interaction pipeline.
enum VoiceState {
  /// App is idle, waiting for user to initiate conversation
  idle,

  /// App is actively listening to user speech
  listening,

  /// Processing user input (sending to LLM, waiting for response)
  thinking,

  /// Playing back the assistant's audio response
  speaking,

  /// Connection error or temporary issue
  error,

  /// App is connecting to the voice service
  connecting,
}

extension VoiceStateExtension on VoiceState {
  bool get isActive =>
      this == VoiceState.listening ||
      this == VoiceState.thinking ||
      this == VoiceState.speaking;

  String get portugueseLabel {
    switch (this) {
      case VoiceState.idle:
        return 'Toque para falar';
      case VoiceState.listening:
        return 'A ouvir...';
      case VoiceState.thinking:
        return 'A pensar...';
      case VoiceState.speaking:
        return 'A falar...';
      case VoiceState.error:
        return 'Erro de ligação';
      case VoiceState.connecting:
        return 'A ligar...';
    }
  }
}
