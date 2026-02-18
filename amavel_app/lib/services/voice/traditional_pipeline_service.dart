import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:amavel_app/config/api_keys.dart';
import 'package:amavel_app/config/app_config.dart';
import 'package:amavel_app/core/logger/app_logger.dart';
import 'package:amavel_app/core/utils/audio_utils.dart';
import 'voice_service.dart';

/// Traditional pipeline implementation: Google STT → Claude → Azure TTS
/// Implements VoiceService using separate APIs for each step
class TraditionalPipelineService implements VoiceService {
  static const String _googleSttUrl =
      'https://speech.googleapis.com/v1/speech:recognize';
  static const String _claudeUrl = 'https://api.anthropic.com/v1/messages';
  static const String _azureTtsUrl =
      'https://westeurope.tts.speech.microsoft.com/cognitiveservices/v1';

  late final Dio _dio;
  late final StreamController<VoiceEvent> _eventController;

  bool _isConnected = false;
  Uint8List _audioBuffer = Uint8List(0);
  String _systemPrompt = '';
  List<Map<String, dynamic>> _tools = [];
  bool _isClosed = false;

  @override
  Stream<VoiceEvent> get eventStream => _eventController.stream;

  @override
  bool get isConnected => _isConnected;

  TraditionalPipelineService() {
    _eventController = StreamController<VoiceEvent>.broadcast();
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  @override
  Future<void> connect(
    String systemPrompt,
    List<Map<String, dynamic>> tools,
  ) async {
    if (_isConnected) {
      AppLogger.info('Traditional pipeline already connected');
      return;
    }

    try {
      _isClosed = false;
      _systemPrompt = systemPrompt;
      _tools = tools;

      // Validate API keys
      if (ApiKeys.googleCloudApiKey.isEmpty) {
        throw Exception('Google Cloud API key not configured');
      }
      if (ApiKeys.anthropicApiKey.isEmpty) {
        throw Exception('Anthropic API key not configured');
      }
      if (ApiKeys.azureSpeechKey.isEmpty) {
        throw Exception('Azure Speech key not configured');
      }

      _isConnected = true;
      _emitConnectionStateChanged(true);
      AppLogger.info('Traditional pipeline connected');
    } catch (e, st) {
      AppLogger.error('Failed to connect traditional pipeline', e, st);
      _emitError('Connection failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _isClosed = true;
    _isConnected = false;
    _audioBuffer = Uint8List(0);

    try {
      await _eventController.close();
      _dio.close();
      AppLogger.info('Traditional pipeline disconnected');
    } catch (e, st) {
      AppLogger.error('Error during disconnect', e, st);
    }
  }

  @override
  Future<void> sendAudio(Uint8List pcmAudio) async {
    if (!_isConnected) {
      throw Exception('Not connected');
    }

    // Append to buffer
    final newBuffer = Uint8List(_audioBuffer.length + pcmAudio.length);
    newBuffer.setRange(0, _audioBuffer.length, _audioBuffer);
    newBuffer.setRange(_audioBuffer.length, newBuffer.length, pcmAudio);
    _audioBuffer = newBuffer;
  }

  @override
  Future<void> commitAudioBuffer() async {
    if (!_isConnected || _audioBuffer.isEmpty) {
      return;
    }

    try {
      AppLogger.info('Starting voice pipeline with ${_audioBuffer.length} bytes');

      // Step 1: Speech-to-Text with Google Cloud
      final userTranscript = await _transcribeAudio(_audioBuffer);
      _emitTranscriptComplete(userTranscript, true);
      AppLogger.info('User transcript: $userTranscript');

      // Clear buffer after transcription
      _audioBuffer = Uint8List(0);

      // Step 2: Send to Claude with tools
      final claudeResponse = await _processWithClaude(userTranscript);
      _emitTranscriptDelta(claudeResponse['text'], false);
      _emitTranscriptComplete(claudeResponse['text'], false);

      // Step 3: Text-to-Speech with Azure
      await _synthesizeAndStream(claudeResponse['text']);

      AppLogger.info('Voice pipeline completed successfully');
    } catch (e, st) {
      AppLogger.error('Voice pipeline error', e, st);
      _emitError('Pipeline error: $e');
    }
  }

  Future<String> _transcribeAudio(Uint8List pcmAudio) async {
    try {
      AppLogger.info('Transcribing audio with Google Cloud STT');

      // Convert PCM to WAV format for better results
      final wavData = AudioUtils.pcmToWav(pcmAudio, 24000, 1);
      final base64Audio = base64Encode(wavData);

      final response = await _dio.post(
        _googleSttUrl,
        queryParameters: {
          'key': ApiKeys.googleCloudApiKey,
        },
        data: {
          'audio': {
            'content': base64Audio,
          },
          'config': {
            'encoding': 'LINEAR16',
            'sampleRateHertz': 24000,
            'languageCode': 'pt-PT',
            'model': 'latest_long',
            'useEnhanced': true,
          },
        },
      );

      final results = response.data['results'] as List?;
      if (results == null || results.isEmpty) {
        throw Exception('No transcription results from Google STT');
      }

      final transcript = StringBuffer();
      for (final result in results) {
        final alternatives = result['alternatives'] as List?;
        if (alternatives != null && alternatives.isNotEmpty) {
          transcript.write(alternatives[0]['transcript']);
          transcript.write(' ');
        }
      }

      return transcript.toString().trim();
    } catch (e, st) {
      AppLogger.error('STT error', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _processWithClaude(String userMessage) async {
    try {
      AppLogger.info('Processing with Claude');

      // Build messages
      final messages = [
        {
          'role': 'user',
          'content': userMessage,
        }
      ];

      // Build request
      final data = {
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 500,
        'system': _systemPrompt,
        'messages': messages,
      };

      // Add tools if provided
      if (_tools.isNotEmpty) {
        data['tools'] = _tools;
      }

      final response = await _dio.post(
        _claudeUrl,
        options: Options(
          headers: {
            'x-api-key': ApiKeys.anthropicApiKey,
            'anthropic-version': '2023-06-01',
          },
        ),
        data: data,
      );

      // Extract text response
      final content = response.data['content'] as List;
      String responseText = '';
      List<Map<String, dynamic>> toolUses = [];

      for (final block in content) {
        if (block['type'] == 'text') {
          responseText = block['text'];
        } else if (block['type'] == 'tool_use') {
          toolUses.add({
            'id': block['id'],
            'name': block['name'],
            'input': block['input'],
          });
        }
      }

      // Handle tool calls if needed
      if (toolUses.isNotEmpty) {
        AppLogger.info('Tool calls requested: ${toolUses.map((t) => t['name']).join(', ')}');
        for (final toolUse in toolUses) {
          _emitFunctionCall(
            toolUse['name'],
            jsonEncode(toolUse['input']),
            toolUse['id'],
          );
        }
      }

      return {
        'text': responseText.isNotEmpty ? responseText : 'Processing your request...',
        'toolUses': toolUses,
      };
    } catch (e, st) {
      AppLogger.error('Claude processing error', e, st);
      rethrow;
    }
  }

  Future<void> _synthesizeAndStream(String text) async {
    try {
      AppLogger.info('Synthesizing speech with Azure TTS');

      // Build SSML
      final ssml = '''<?xml version="1.0" encoding="UTF-8"?>
<speak version="1.0" xml:lang="pt-PT">
  <voice name="pt-PT-FernandaNeural">
    <prosody rate="1.0">$text</prosody>
  </voice>
</speak>''';

      final response = await _dio.post(
        _azureTtsUrl,
        options: Options(
          headers: {
            'Ocp-Apim-Subscription-Key': ApiKeys.azureSpeechKey,
            'Content-Type': 'application/ssml+xml',
            'X-Microsoft-OutputFormat':
                'audio-16khz-32kbitrate-mono-mp3',
          },
          responseType: ResponseType.bytes,
        ),
        data: ssml,
      );

      final audioBytes = response.data as Uint8List;
      AppLogger.info('Received ${audioBytes.length} bytes of audio from Azure TTS');

      // Convert MP3 to PCM16 for streaming
      // Note: This is a simplified version. In production, you'd use proper audio conversion
      final pcmAudio = await AudioUtils.mp3ToPcm(audioBytes);

      // Stream audio in chunks
      const chunkSize = 4096;
      for (int i = 0; i < pcmAudio.length; i += chunkSize) {
        final end = (i + chunkSize > pcmAudio.length)
            ? pcmAudio.length
            : i + chunkSize;
        final chunk = pcmAudio.sublist(i, end);
        _emitAudioDelta(chunk);

        // Small delay between chunks for natural streaming
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _emitAudioComplete();
    } catch (e, st) {
      AppLogger.error('TTS error', e, st);
      rethrow;
    }
  }

  @override
  Future<void> cancelResponse() async {
    if (_isConnected) {
      _audioBuffer = Uint8List(0);
      AppLogger.info('Response cancelled');
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

  void _emitFunctionCall(String name, String arguments, String callId) {
    if (!_eventController.isClosed) {
      _eventController.add(
        FunctionCall(
          name: name,
          arguments: arguments,
          callId: callId,
        ),
      );
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
