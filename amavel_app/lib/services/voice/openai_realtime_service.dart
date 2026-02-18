import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:amavel_app/config/api_keys.dart';
import 'package:amavel_app/config/app_config.dart';
import 'package:amavel_app/core/logger/app_logger.dart';
import 'package:amavel_app/core/utils/audio_utils.dart';
import 'voice_service.dart';

/// OpenAI Realtime API implementation of VoiceService
/// Handles real-time speech-to-text, LLM processing, and text-to-speech
class OpenAIRealtimeService implements VoiceService {
  static const String _wsUrl = 'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview';
  static const String _betaHeader = 'realtime=v1';
  static const int _maxReconnectAttempts = 3;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);

  late final WebSocketChannel _channel;
  late final StreamController<VoiceEvent> _eventController;
  late final StreamController<Uint8List> _audioBufferController;

  String _sessionId = '';
  bool _isConnected = false;
  bool _isClosed = false;
  int _reconnectAttempts = 0;
  String? _currentResponseId;
  String? _currentAudioTranscript;
  Map<String, dynamic> _lastSessionConfig = {};

  @override
  Stream<VoiceEvent> get eventStream => _eventController.stream;

  Stream<Uint8List> get _audioBuffer => _audioBufferController.stream;

  @override
  bool get isConnected => _isConnected;

  OpenAIRealtimeService() {
    _eventController = StreamController<VoiceEvent>.broadcast();
    _audioBufferController = StreamController<Uint8List>();
  }

  @override
  Future<void> connect(
    String systemPrompt,
    List<Map<String, dynamic>> tools,
  ) async {
    if (_isConnected) {
      AppLogger.info('OpenAI Realtime already connected');
      return;
    }

    try {
      _isClosed = false;
      _reconnectAttempts = 0;
      await _establishConnection(systemPrompt, tools);
    } catch (e, st) {
      AppLogger.error('Failed to connect to OpenAI Realtime', e, st);
      _emitError('Connection failed: $e');
      rethrow;
    }
  }

  Future<void> _establishConnection(
    String systemPrompt,
    List<Map<String, dynamic>> tools,
  ) async {
    try {
      final token = ApiKeys.openaiApiKey;
      if (token.isEmpty) {
        throw Exception('OpenAI API key not configured');
      }

      AppLogger.info('Connecting to OpenAI Realtime API');

      _channel = WebSocketChannel.connect(
        Uri.parse(_wsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'OpenAI-Beta': _betaHeader,
        },
      );

      // Handle incoming messages
      _channel.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      // Wait a moment for connection to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Send session update
      await _sendSessionUpdate(systemPrompt, tools);

      _isConnected = true;
      _reconnectAttempts = 0;
      _emitConnectionStateChanged(true);
      AppLogger.info('Connected to OpenAI Realtime API');
    } catch (e, st) {
      AppLogger.error('Connection establishment failed', e, st);
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> _sendSessionUpdate(
    String systemPrompt,
    List<Map<String, dynamic>> tools,
  ) async {
    final config = {
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': systemPrompt,
        'voice': AppConfig.openaiVoice,
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 800,
        },
        'tools': tools,
        'max_response_output_tokens': 500,
      },
    };

    _lastSessionConfig = config;
    _sendMessage(config);
  }

  void _sendMessage(Map<String, dynamic> message) {
    try {
      final jsonString = jsonEncode(message);
      _channel.sink.add(jsonString);
      AppLogger.debug('Sent message: ${message['type']}');
    } catch (e, st) {
      AppLogger.error('Failed to send message', e, st);
      _emitError('Failed to send message: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final eventType = data['type'] as String?;

      AppLogger.debug('Received event: $eventType');

      switch (eventType) {
        case 'session.created':
          _handleSessionCreated(data);
        case 'session.updated':
          _handleSessionUpdated(data);
        case 'input_audio_buffer.speech_started':
          AppLogger.info('User started speaking');
        case 'input_audio_buffer.speech_stopped':
          AppLogger.info('User stopped speaking');
        case 'input_audio_buffer.committed':
          AppLogger.info('Audio buffer committed');
        case 'response.created':
          _handleResponseCreated(data);
        case 'response.output_item.added':
          _handleOutputItemAdded(data);
        case 'response.audio_transcript.delta':
          _handleAudioTranscriptDelta(data);
        case 'response.audio_transcript.done':
          _handleAudioTranscriptDone(data);
        case 'response.audio.delta':
          _handleAudioDelta(data);
        case 'response.audio.done':
          _handleAudioDone(data);
        case 'response.function_call_arguments.delta':
          _handleFunctionCallDelta(data);
        case 'response.function_call_arguments.done':
          _handleFunctionCallDone(data);
        case 'response.done':
          _handleResponseDone(data);
        case 'error':
          _handleApiError(data);
        default:
          AppLogger.debug('Unhandled event type: $eventType');
      }
    } catch (e, st) {
      AppLogger.error('Error handling message', e, st);
      _emitError('Message handling error: $e');
    }
  }

  void _handleSessionCreated(Map<String, dynamic> data) {
    _sessionId = data['session']?['id'] ?? '';
    AppLogger.info('Session created: $_sessionId');
  }

  void _handleSessionUpdated(Map<String, dynamic> data) {
    AppLogger.info('Session updated');
  }

  void _handleResponseCreated(Map<String, dynamic> data) {
    _currentResponseId = data['response']?['id'];
    _currentAudioTranscript = '';
    AppLogger.debug('Response created: $_currentResponseId');
  }

  void _handleOutputItemAdded(Map<String, dynamic> data) {
    final item = data['item'] as Map<String, dynamic>?;
    final itemType = item?['type'] as String?;
    AppLogger.debug('Output item added: $itemType');
  }

  void _handleAudioTranscriptDelta(Map<String, dynamic> data) {
    final delta = data['delta'] as String? ?? '';
    _currentAudioTranscript = (_currentAudioTranscript ?? '') + delta;
    _emitTranscriptDelta(delta, false);
  }

  void _handleAudioTranscriptDone(Map<String, dynamic> data) {
    final transcript = _currentAudioTranscript ?? '';
    AppLogger.info('Assistant response: $transcript');
    _emitTranscriptComplete(transcript, false);
  }

  void _handleAudioDelta(Map<String, dynamic> data) {
    try {
      final delta = data['delta'] as String?;
      if (delta == null) return;

      // Decode base64 audio
      final audioBytes = base64Decode(delta);
      _emitAudioDelta(Uint8List.fromList(audioBytes));
    } catch (e, st) {
      AppLogger.error('Error decoding audio delta', e, st);
    }
  }

  void _handleAudioDone(Map<String, dynamic> data) {
    AppLogger.info('Audio generation complete');
    _emitAudioComplete();
  }

  void _handleFunctionCallDelta(Map<String, dynamic> data) {
    AppLogger.debug('Function call delta received');
  }

  void _handleFunctionCallDone(Map<String, dynamic> data) {
    AppLogger.debug('Function call done');
  }

  void _handleResponseDone(Map<String, dynamic> data) {
    _currentResponseId = null;
    AppLogger.info('Response finished');
  }

  void _handleApiError(Map<String, dynamic> data) {
    final error = data['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ?? 'Unknown error';
    AppLogger.error('OpenAI API error: $message');
    _emitError('API error: $message');
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    AppLogger.error('WebSocket error', error, stackTrace);
    _emitError('Connection error: $error');
    _attemptReconnect();
  }

  void _handleDone() {
    AppLogger.info('WebSocket connection closed');
    _isConnected = false;
    _emitConnectionStateChanged(false);

    if (!_isClosed) {
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isClosed) {
      AppLogger.error('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _baseReconnectDelay * (_reconnectAttempts);

    AppLogger.info('Attempting reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    Future.delayed(delay, () {
      if (!_isClosed && !_isConnected) {
        _establishConnection(
          _lastSessionConfig['session']?['instructions'] ?? '',
          List<Map<String, dynamic>>.from(
            _lastSessionConfig['session']?['tools'] ?? [],
          ),
        ).catchError((e) {
          AppLogger.error('Reconnection failed', e);
        });
      }
    });
  }

  @override
  Future<void> sendAudio(Uint8List pcmAudio) async {
    if (!_isConnected) {
      throw Exception('Not connected to OpenAI Realtime');
    }

    try {
      // Encode PCM audio to base64
      final base64Audio = base64Encode(pcmAudio);

      final message = {
        'type': 'input_audio_buffer.append',
        'audio': base64Audio,
      };

      _sendMessage(message);
    } catch (e, st) {
      AppLogger.error('Error sending audio', e, st);
      _emitError('Audio send failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> commitAudioBuffer() async {
    if (!_isConnected) {
      throw Exception('Not connected to OpenAI Realtime');
    }

    try {
      _sendMessage({'type': 'input_audio_buffer.commit'});
    } catch (e, st) {
      AppLogger.error('Error committing audio buffer', e, st);
      _emitError('Buffer commit failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelResponse() async {
    if (!_isConnected) {
      throw Exception('Not connected to OpenAI Realtime');
    }

    try {
      if (_currentResponseId != null) {
        _sendMessage({
          'type': 'response.cancel',
        });
        _currentResponseId = null;
      }
    } catch (e, st) {
      AppLogger.error('Error canceling response', e, st);
      _emitError('Response cancel failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _isClosed = true;
    _isConnected = false;

    try {
      await _channel.sink.close();
      await _eventController.close();
      await _audioBufferController.close();
      AppLogger.info('Disconnected from OpenAI Realtime');
    } catch (e, st) {
      AppLogger.error('Error during disconnect', e, st);
    }
  }

  // Event emission helpers
  void _emitTranscriptDelta(String text, bool isUser) {
    if (!_eventController.isClosed) {
      _eventController.add(
        TranscriptDelta(text: text, isUser: isUser),
      );
    }
  }

  void _emitTranscriptComplete(String text, bool isUser) {
    if (!_eventController.isClosed) {
      _eventController.add(
        TranscriptComplete(text: text, isUser: isUser),
      );
    }
  }

  void _emitAudioDelta(Uint8List audio) {
    if (!_eventController.isClosed) {
      _eventController.add(AudioDelta(pcmAudio: audio));
    }
  }

  void _emitAudioComplete() {
    if (!_eventController.isClosed) {
      _eventController.add(AudioComplete());
    }
  }

  void _emitError(String message) {
    if (!_eventController.isClosed) {
      _eventController.add(
        VoiceError(message: message),
      );
    }
  }

  void _emitConnectionStateChanged(bool connected) {
    if (!_eventController.isClosed) {
      _eventController.add(
        ConnectionStateChanged(connected: connected),
      );
    }
  }
}
