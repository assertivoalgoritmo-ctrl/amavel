import 'dart:typed_data';

/// Abstract interface for the voice pipeline service
/// Defines the contract for voice input/output processing
abstract class VoiceService {
  /// Stream of voice events from the service
  Stream<VoiceEvent> get eventStream;

  /// Connect to the voice service with system prompt and tools
  ///
  /// [systemPrompt] - The system instructions for the AI
  /// [tools] - List of function definitions for tool calling
  Future<void> connect(String systemPrompt, List<Map<String, dynamic>> tools);

  /// Disconnect from the voice service
  Future<void> disconnect();

  /// Send audio data to the service
  ///
  /// [pcmAudio] - PCM16 encoded audio data (24000 Hz, mono)
  Future<void> sendAudio(Uint8List pcmAudio);

  /// Commit the current audio buffer for processing
  /// Triggers the voice pipeline (STT -> LLM -> TTS)
  Future<void> commitAudioBuffer();

  /// Cancel the current response generation
  Future<void> cancelResponse();

  /// Check if the service is currently connected
  bool get isConnected;
}

/// Sealed class representing voice service events
sealed class VoiceEvent {}

/// Represents a partial transcript from speech-to-text
class TranscriptDelta extends VoiceEvent {
  final String text;
  final bool isUser;

  TranscriptDelta({
    required this.text,
    required this.isUser,
  });

  @override
  String toString() => 'TranscriptDelta(text: $text, isUser: $isUser)';
}

/// Represents a complete transcript from speech-to-text
class TranscriptComplete extends VoiceEvent {
  final String text;
  final bool isUser;

  TranscriptComplete({
    required this.text,
    required this.isUser,
  });

  @override
  String toString() => 'TranscriptComplete(text: $text, isUser: $isUser)';
}

/// Represents audio data chunk from text-to-speech
class AudioDelta extends VoiceEvent {
  final Uint8List pcmAudio;

  AudioDelta({required this.pcmAudio});

  @override
  String toString() => 'AudioDelta(audioLength: ${pcmAudio.length})';
}

/// Represents completion of audio generation
class AudioComplete extends VoiceEvent {
  AudioComplete();

  @override
  String toString() => 'AudioComplete()';
}

/// Represents a function call requested by the LLM
class FunctionCall extends VoiceEvent {
  final String name;
  final String arguments;
  final String callId;

  FunctionCall({
    required this.name,
    required this.arguments,
    required this.callId,
  });

  @override
  String toString() =>
      'FunctionCall(name: $name, arguments: $arguments, callId: $callId)';
}

/// Represents an error in the voice pipeline
class VoiceError extends VoiceEvent {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  VoiceError({
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() => 'VoiceError(message: $message, error: $error)';
}

/// Represents a change in connection state
class ConnectionStateChanged extends VoiceEvent {
  final bool connected;

  ConnectionStateChanged({required this.connected});

  @override
  String toString() => 'ConnectionStateChanged(connected: $connected)';
}
