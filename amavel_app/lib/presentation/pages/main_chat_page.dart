import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';

import 'package:amavel_app/config/api_keys.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/utils/audio_utils.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';
import 'package:amavel_app/presentation/widgets/animated_orb.dart';
import 'package:amavel_app/presentation/widgets/status_indicator.dart';
import 'package:amavel_app/presentation/widgets/transcript_bubble.dart';
import 'package:amavel_app/presentation/widgets/elder_nav_bar.dart';

/// Main chat page with full OpenAI Realtime voice pipeline.
/// Self-contained: handles recording, WebSocket, and playback directly.
class MainChatPage extends StatefulWidget {
  const MainChatPage({Key? key}) : super(key: key);

  @override
  State<MainChatPage> createState() => _MainChatPageState();
}

class _MainChatPageState extends State<MainChatPage> {
  // --- Voice state ---
  VoiceState _voiceState = VoiceState.idle;
  String _assistantMessage = 'Olá! Toca no círculo para falar comigo.';
  String _userMessage = '';
  String _errorMessage = '';

  // --- OpenAI WebSocket ---
  IOWebSocketChannel? _channel;
  bool _wsConnected = false;
  String _partialTranscript = '';
  List<int> _responseAudioBytes = [];

  // --- Audio recording (flutter_sound) ---
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  StreamController<Food>? _recorderStreamCtrl;

  // --- Audio playback (just_audio) ---
  final ja.AudioPlayer _player = ja.AudioPlayer();

  // --- Session active flag ---
  bool _sessionActive = false;

  // ====================================================
  // Lifecycle
  // ====================================================

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    try {
      await _stopRecording();
      await _disconnectWs();
      if (_recorderReady) {
        await _recorder.closeRecorder();
      }
      await _player.dispose();
    } catch (_) {}
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
      _recorderReady = true;
    } catch (e) {
      debugPrint('Recorder init error: $e');
    }
  }

  // ====================================================
  // Tap handler — start / stop voice session
  // ====================================================

  Future<void> _onOrbTap() async {
    if (_sessionActive) {
      await _endSession();
    } else {
      await _startSession();
    }
  }

  // ====================================================
  // Session lifecycle
  // ====================================================

  Future<void> _startSession() async {
    // Check API key
    if (!ApiKeys.hasOpenAiKey) {
      _setError('Chave da API OpenAI não configurada.');
      return;
    }

    // Request mic permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _setError('Permissão de microfone necessária.');
      return;
    }

    setState(() {
      _voiceState = VoiceState.connecting;
      _userMessage = '';
      _errorMessage = '';
      _assistantMessage = 'A ligar ao serviço de voz...';
    });

    try {
      // 1. Connect WebSocket
      await _connectWs();

      // 2. Start recording
      await _startRecording();

      _sessionActive = true;
      setState(() {
        _voiceState = VoiceState.listening;
        _assistantMessage = 'Estou a ouvir... fala comigo!';
      });
    } catch (e) {
      _setError('Erro ao iniciar: $e');
    }
  }

  Future<void> _endSession() async {
    _sessionActive = false;
    await _stopRecording();
    await _disconnectWs();
    setState(() {
      _voiceState = VoiceState.idle;
      _assistantMessage = 'Toca no círculo para falar comigo.';
      _userMessage = '';
    });
  }

  // ====================================================
  // WebSocket — OpenAI Realtime API
  // ====================================================

  Future<void> _connectWs() async {
    final uri = Uri.parse(
      'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview',
    );

    _channel = IOWebSocketChannel.connect(
      uri,
      headers: {
        'Authorization': 'Bearer ${ApiKeys.openaiApiKey}',
        'OpenAI-Beta': 'realtime=v1',
      },
    );

    // Listen for messages
    _channel!.stream.listen(
      _onWsMessage,
      onError: (e) {
        debugPrint('WS error: $e');
        if (_sessionActive) _setError('Erro de ligação: $e');
      },
      onDone: () {
        debugPrint('WS closed');
        _wsConnected = false;
        if (_sessionActive) {
          setState(() {
            _voiceState = VoiceState.error;
            _errorMessage = 'Ligação perdida.';
          });
        }
      },
    );

    // Wait briefly for the connection
    await Future.delayed(const Duration(milliseconds: 800));
    _wsConnected = true;

    // Send session configuration
    _wsSend({
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'instructions': _buildSystemPrompt(),
        'voice': 'nova',
        'input_audio_format': 'pcm16',
        'output_audio_format': 'pcm16',
        'input_audio_transcription': {
          'model': 'whisper-1',
        },
        'turn_detection': {
          'type': 'server_vad',
          'threshold': 0.5,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 1200,
        },
        'max_response_output_tokens': 500,
      },
    });
  }

  Future<void> _disconnectWs() async {
    _wsConnected = false;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _wsSend(Map<String, dynamic> msg) {
    if (_channel != null && _wsConnected) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (e) {
        debugPrint('WS send error: $e');
      }
    }
  }

  // ====================================================
  // Handle incoming WebSocket messages
  // ====================================================

  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      debugPrint('WS event: $type');

      switch (type) {
        // Session established
        case 'session.created':
        case 'session.updated':
          debugPrint('Session ready');
          break;

        // User speech detected
        case 'input_audio_buffer.speech_started':
          setState(() {
            _voiceState = VoiceState.listening;
            _userMessage = 'A ouvir...';
          });
          break;

        // User stopped speaking
        case 'input_audio_buffer.speech_stopped':
          setState(() {
            _voiceState = VoiceState.thinking;
            _userMessage = '';
            _assistantMessage = 'A pensar...';
          });
          break;

        // User transcript
        case 'conversation.item.input_audio_transcription.completed':
          final transcript = data['transcript'] as String? ?? '';
          if (transcript.isNotEmpty) {
            setState(() {
              _userMessage = transcript;
            });
          }
          break;

        // Assistant response started
        case 'response.created':
          _partialTranscript = '';
          _responseAudioBytes = [];
          setState(() {
            _voiceState = VoiceState.thinking;
            _assistantMessage = 'A pensar...';
          });
          break;

        // Assistant text arriving
        case 'response.audio_transcript.delta':
          final delta = data['delta'] as String? ?? '';
          _partialTranscript += delta;
          setState(() {
            _voiceState = VoiceState.speaking;
            _assistantMessage = _partialTranscript;
          });
          break;

        // Assistant audio arriving
        case 'response.audio.delta':
          final b64 = data['delta'] as String?;
          if (b64 != null) {
            _responseAudioBytes.addAll(base64Decode(b64));
          }
          if (_voiceState != VoiceState.speaking) {
            setState(() => _voiceState = VoiceState.speaking);
          }
          break;

        // Audio generation finished — play it
        case 'response.audio.done':
          _playResponseAudio();
          break;

        // Full response complete
        case 'response.done':
          debugPrint('Response done');
          // After audio finishes playing, state goes back to listening
          break;

        // Errors from OpenAI
        case 'error':
          final errMsg = (data['error'] as Map?)?['message'] ?? 'Erro desconhecido';
          debugPrint('OpenAI error: $errMsg');
          _setError('OpenAI: $errMsg');
          break;
      }
    } catch (e) {
      debugPrint('WS message parse error: $e');
    }
  }

  // ====================================================
  // Audio recording → stream to OpenAI
  // ====================================================

  Future<void> _startRecording() async {
    if (!_recorderReady) return;

    _recorderStreamCtrl = StreamController<Food>();

    // Listen for audio data and send to OpenAI
    _recorderStreamCtrl!.stream.listen((food) {
      if (food is FoodData && food.data != null && _wsConnected) {
        final b64 = base64Encode(food.data!);
        _wsSend({
          'type': 'input_audio_buffer.append',
          'audio': b64,
        });
      }
    });

    await _recorder.startRecorder(
      toStream: _recorderStreamCtrl!.sink,
      codec: Codec.pcm16,
      sampleRate: 24000,
      numChannels: 1,
    );
  }

  Future<void> _stopRecording() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
      await _recorderStreamCtrl?.close();
      _recorderStreamCtrl = null;
    } catch (_) {}
  }

  // ====================================================
  // Audio playback
  // ====================================================

  Future<void> _playResponseAudio() async {
    if (_responseAudioBytes.isEmpty) {
      // No audio — just go back to listening
      if (_sessionActive) {
        setState(() => _voiceState = VoiceState.listening);
      }
      return;
    }

    try {
      // Convert PCM16 to WAV
      final pcm = Uint8List.fromList(_responseAudioBytes);
      final wav = AudioUtils.pcmToWav(pcm, sampleRate: 24000, channels: 1);

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/amavel_response_${DateTime.now().millisecondsSinceEpoch}.wav');
      await file.writeAsBytes(wav);

      // Play
      await _player.setFilePath(file.path);
      await _player.play();

      // Wait for playback to finish
      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ja.ProcessingState.completed,
      );

      // Clean up temp file
      try { await file.delete(); } catch (_) {}

      // Return to listening if session still active
      if (_sessionActive && mounted) {
        setState(() {
          _voiceState = VoiceState.listening;
        });
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      if (_sessionActive && mounted) {
        setState(() => _voiceState = VoiceState.listening);
      }
    }
  }

  // ====================================================
  // System prompt
  // ====================================================

  String _buildSystemPrompt() {
    return '''
Tu és a AMAVEL, uma assistente de voz amigável e carinhosa para idosos portugueses.

Regras importantes:
- Fala SEMPRE em Português de Portugal (pt-PT).
- Usa linguagem simples, clara e calorosa.
- Trata o utilizador por "tu" de forma respeitosa.
- Sê paciente e repete se necessário.
- As tuas respostas devem ser curtas (2-3 frases no máximo).
- Se o utilizador parecer triste ou angustiado, mostra empatia e pergunta como podes ajudar.
- Nunca dês conselhos médicos concretos, sugere sempre falar com um médico.
- Lembra-te de factos que o utilizador partilhe (nome, família, gostos).
- Sê alegre e positiva, mas nunca condescendente.

Exemplos de resposta:
- "Que bom falar contigo! Como estás hoje?"
- "Isso é muito interessante! Conta-me mais sobre isso."
- "Compreendo que te sintas assim. Estou aqui para ti."
''';
  }

  // ====================================================
  // Error handling
  // ====================================================

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _voiceState = VoiceState.error;
        _errorMessage = msg;
        _assistantMessage = msg;
      });
    }
  }

  // ====================================================
  // Build UI
  // ====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmavelTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Animated Orb
                    GestureDetector(
                      onTap: _onOrbTap,
                      child: AnimatedOrb(
                        state: _voiceState,
                        size: 280,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Status Indicator
                    StatusIndicator(
                      state: _voiceState,
                    ),
                    const SizedBox(height: 32),

                    // Transcript Bubbles
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (_userMessage.isNotEmpty) ...[
                            TranscriptBubble(
                              text: _userMessage,
                              isAssistant: false,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TranscriptBubble(
                            text: _assistantMessage,
                            isAssistant: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Error display
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: AmavelTheme.textSizeBody,
                              color: Colors.red[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            ElderNavBar(
              currentIndex: 0,
              onTap: (index) {
                // Navigation will be handled at router level
              },
            ),
          ],
        ),
      ),
    );
  }
}
