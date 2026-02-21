import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

import 'package:amavel_app/config/api_keys.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/constants.dart';
import 'package:amavel_app/core/utils/audio_utils.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';
import 'package:amavel_app/domain/models/memory_fact.dart';
import 'package:amavel_app/domain/models/user_profile.dart';
import 'package:amavel_app/data/repositories/alert_repository.dart';
import 'package:amavel_app/data/repositories/memory_repository.dart';
import 'package:amavel_app/services/memory/memory_manager.dart';
import 'package:amavel_app/services/memory/system_prompt_builder.dart';
import 'package:amavel_app/services/safety/alert_dispatcher.dart';
import 'package:amavel_app/services/safety/distress_detector.dart';
import 'package:amavel_app/services/safety/guardrails_service.dart';
import 'package:amavel_app/presentation/widgets/animated_orb.dart';
import 'package:amavel_app/presentation/widgets/status_indicator.dart';
import 'package:amavel_app/presentation/widgets/transcript_bubble.dart';
import 'package:amavel_app/presentation/widgets/elder_nav_bar.dart';

/// Main chat page with full OpenAI Realtime voice pipeline.
/// Integrates: voice conversation, memory system, distress detection, alerts.
class MainChatPage extends StatefulWidget {
  const MainChatPage({Key? key}) : super(key: key);

  @override
  State<MainChatPage> createState() => _MainChatPageState();
}

class _MainChatPageState extends State<MainChatPage> {
  // --- Voice state ---
  VoiceState _voiceState = VoiceState.idle;
  String _assistantMessage = 'Olá! Toque no círculo para falar comigo.';
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
  StreamController<Uint8List>? _recorderStreamCtrl;

  // --- Audio playback (just_audio) ---
  final ja.AudioPlayer _player = ja.AudioPlayer();

  // --- Session active flag ---
  bool _sessionActive = false;

  // --- Playback flag (used for echo cancellation) ---
  bool _isPlaying = false;

  // --- User context (loaded from SharedPreferences) ---
  String? _userId;
  String? _userName;
  DateTime? _userBirthdate;

  // --- Memory system (nullable — graceful degradation if Firebase fails) ---
  MemoryRepository? _memoryRepository;
  MemoryManager? _memoryManager;
  List<MemoryFact> _memoryFacts = [];

  // --- Safety systems (nullable — graceful degradation if Firebase fails) ---
  GuardrailsService? _guardrails;
  AlertRepository? _alertRepository;
  AlertDispatcher? _alertDispatcher;

  // --- Function call tracking ---
  String _currentFunctionCallId = '';
  String _currentFunctionName = '';
  String _currentFunctionArgs = '';

  // ====================================================
  // Lifecycle
  // ====================================================

  @override
  void initState() {
    super.initState();

    // Initialize safety services (no Firebase dependency)
    _guardrails = GuardrailsService();

    // Initialize Firebase-dependent services safely
    try {
      _memoryRepository = MemoryRepository();
      _memoryManager = MemoryManager(_memoryRepository!);
      _alertRepository = AlertRepository();
      _alertDispatcher = AlertDispatcher(_alertRepository!);
      debugPrint('All services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase services (will work without memory/alerts): $e');
    }

    _initRecorder();
    _loadUserContext();
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

  /// Load user context from SharedPreferences and memory facts from Firestore
  Future<void> _loadUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(AppConstants.prefUserId);
      _userName = prefs.getString(AppConstants.prefUserName);

      final birthdateStr = prefs.getString(AppConstants.prefUserBirthdate);
      if (birthdateStr != null) {
        _userBirthdate = DateTime.tryParse(birthdateStr);
      }

      // Update greeting with user name
      if (_userName != null && _userName!.isNotEmpty && mounted) {
        setState(() {
          _assistantMessage = 'Olá, $_userName! Toque no círculo para falar comigo.';
        });
      }
    } catch (e) {
      debugPrint('Error loading user context: $e');
    }

    // Load memory facts (Firestore, may fail if not authenticated)
    if (_memoryRepository != null) {
      try {
        _memoryFacts = await _memoryRepository!.getFactsForUser();
        debugPrint('Loaded ${_memoryFacts.length} memory facts');
      } catch (e) {
        debugPrint('Error loading memory facts (may not be authenticated): $e');
        _memoryFacts = [];
      }
    }
  }

  // ====================================================
  // Tap handler — start / stop voice session
  // ====================================================

  Future<void> _onOrbTap() async {
    if (_voiceState == VoiceState.error) {
      await _startSession();
      return;
    }

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
    if (!ApiKeys.hasOpenAiKey) {
      _setError('Chave da API OpenAI não configurada.');
      return;
    }

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
      await _connectWs();
      await _startRecording();

      _sessionActive = true;
      setState(() {
        _voiceState = VoiceState.listening;
        _assistantMessage = 'Estou a ouvir... fale comigo!';
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
      _assistantMessage = _userName != null && _userName!.isNotEmpty
          ? 'Até já, $_userName! Toque no círculo para falar comigo.'
          : 'Toque no círculo para falar comigo.';
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

    await Future.delayed(const Duration(milliseconds: 800));
    _wsConnected = true;

    final systemPrompt = _buildSystemPrompt();
    final memoryTools = _memoryManager?.getMemoryTools() ?? [];

    final sessionConfig = <String, dynamic>{
      'modalities': ['text', 'audio'],
      'instructions': systemPrompt,
      'voice': 'coral',
      'input_audio_format': 'pcm16',
      'output_audio_format': 'pcm16',
      'input_audio_transcription': {
        'model': 'whisper-1',
      },
      'turn_detection': {
        'type': 'server_vad',
        'threshold': 0.7,
        'prefix_padding_ms': 300,
        'silence_duration_ms': 1800,
      },
      'max_response_output_tokens': 400,
    };

    if (memoryTools.isNotEmpty) {
      sessionConfig['tools'] = memoryTools;
      sessionConfig['tool_choice'] = 'auto';
    }

    _wsSend({
      'type': 'session.update',
      'session': sessionConfig,
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
  // Echo cancellation: pause/resume recording during playback
  // ====================================================

  Future<void> _pauseRecording() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.pauseRecorder();
        debugPrint('Recording paused (echo cancellation)');
      }
    } catch (e) {
      debugPrint('Error pausing recorder: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      if (_recorder.isPaused) {
        await _recorder.resumeRecorder();
        debugPrint('Recording resumed');
      }
    } catch (e) {
      debugPrint('Error resuming recorder: $e');
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
        case 'session.created':
        case 'session.updated':
          debugPrint('Session ready');
          break;

        case 'input_audio_buffer.speech_started':
          // Ignore speech detection while we are playing audio (echo cancellation)
          if (_isPlaying) {
            debugPrint('Ignoring speech_started during playback (echo)');
            break;
          }
          setState(() {
            _voiceState = VoiceState.listening;
            _userMessage = 'A ouvir...';
          });
          break;

        case 'input_audio_buffer.speech_stopped':
          if (_isPlaying) {
            debugPrint('Ignoring speech_stopped during playback (echo)');
            break;
          }
          setState(() {
            _voiceState = VoiceState.thinking;
            _userMessage = '';
            _assistantMessage = 'A pensar...';
          });
          break;

        case 'conversation.item.input_audio_transcription.completed':
          // Ignore transcriptions that arrive during or right after playback (echo)
          if (_isPlaying) {
            debugPrint('Ignoring echo transcription during playback');
            break;
          }
          final transcript = data['transcript'] as String? ?? '';
          if (transcript.isNotEmpty) {
            setState(() {
              _userMessage = transcript;
            });
            _analyzeUserTranscript(transcript);
          }
          break;

        case 'response.created':
          _partialTranscript = '';
          _responseAudioBytes = [];
          setState(() {
            _voiceState = VoiceState.thinking;
            _assistantMessage = 'A pensar...';
          });
          break;

        case 'response.audio_transcript.delta':
          final delta = data['delta'] as String? ?? '';
          _partialTranscript += delta;
          setState(() {
            _voiceState = VoiceState.speaking;
            _assistantMessage = _partialTranscript;
          });
          break;

        case 'response.audio.delta':
          final b64 = data['delta'] as String?;
          if (b64 != null) {
            _responseAudioBytes.addAll(base64Decode(b64));
          }
          if (_voiceState != VoiceState.speaking) {
            setState(() => _voiceState = VoiceState.speaking);
          }
          break;

        case 'response.audio.done':
          _playResponseAudio();
          break;

        case 'response.function_call_arguments.delta':
          final delta = data['delta'] as String? ?? '';
          _currentFunctionArgs += delta;
          break;

        case 'response.function_call_arguments.done':
          _currentFunctionCallId = data['call_id'] as String? ?? '';
          _currentFunctionName = data['name'] as String? ?? '';
          _currentFunctionArgs = data['arguments'] as String? ?? _currentFunctionArgs;
          debugPrint('Function call: $_currentFunctionName($_currentFunctionArgs)');
          _handleFunctionCall();
          break;

        case 'response.done':
          debugPrint('Response done');
          break;

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
  // Distress detection
  // ====================================================

  Future<void> _analyzeUserTranscript(String transcript) async {
    if (_guardrails == null) return;

    try {
      final result = _guardrails!.analyzeTranscript(transcript);

      if (!result.isSafe) {
        debugPrint('Safety alert: ${result.severity} — ${result.detectedPatterns}');

        if ((result.severity == 'critical' || result.severity == 'high') &&
            _alertDispatcher != null) {
          final userId = _userId ?? 'anonymous';
          final detector = DistressDetector();
          final distress = detector.detectDistress(transcript);

          await _alertDispatcher!.dispatchDistressAlert(
            userId,
            distress,
            transcript,
          );
          debugPrint('Alert dispatched for severity: ${result.severity}');
        }
      }
    } catch (e) {
      debugPrint('Error in distress analysis: $e');
    }
  }

  // ====================================================
  // Memory function call handling
  // ====================================================

  Future<void> _handleFunctionCall() async {
    if (_currentFunctionName.isEmpty || _memoryManager == null) {
      if (_currentFunctionCallId.isNotEmpty) {
        _wsSend({
          'type': 'conversation.item.create',
          'item': {
            'type': 'function_call_output',
            'call_id': _currentFunctionCallId,
            'output': jsonEncode({
              'success': false,
              'error': 'Sistema de memória indisponível',
            }),
          },
        });
        _wsSend({'type': 'response.create'});
        _currentFunctionCallId = '';
        _currentFunctionName = '';
        _currentFunctionArgs = '';
      }
      return;
    }

    try {
      debugPrint('Handling function call: $_currentFunctionName');

      final result = await _memoryManager!.handleFunctionCall(
        _currentFunctionName,
        _currentFunctionArgs,
      );

      debugPrint('Function result: $result');

      _wsSend({
        'type': 'conversation.item.create',
        'item': {
          'type': 'function_call_output',
          'call_id': _currentFunctionCallId,
          'output': jsonEncode(result),
        },
      });

      _wsSend({
        'type': 'response.create',
      });

      if (_currentFunctionName == 'store_memory_fact' &&
          result['success'] == true &&
          _memoryRepository != null) {
        try {
          _memoryFacts = await _memoryRepository!.getFactsForUser();
          debugPrint('Reloaded ${_memoryFacts.length} memory facts');
        } catch (e) {
          debugPrint('Error reloading memory facts: $e');
        }
      }
    } catch (e) {
      debugPrint('Error handling function call: $e');

      _wsSend({
        'type': 'conversation.item.create',
        'item': {
          'type': 'function_call_output',
          'call_id': _currentFunctionCallId,
          'output': jsonEncode({
            'success': false,
            'error': 'Erro interno: $e',
          }),
        },
      });

      _wsSend({
        'type': 'response.create',
      });
    } finally {
      _currentFunctionCallId = '';
      _currentFunctionName = '';
      _currentFunctionArgs = '';
    }
  }

  // ====================================================
  // Audio recording → stream to OpenAI
  // ====================================================

  Future<void> _startRecording() async {
    if (!_recorderReady) return;

    _recorderStreamCtrl = StreamController<Uint8List>();

    // Listen for audio data and send to OpenAI
    // Only send audio when NOT playing back (echo cancellation)
    _recorderStreamCtrl!.stream.listen((data) {
      if (_wsConnected && !_isPlaying) {
        final b64 = base64Encode(data);
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
  // Audio playback (with echo cancellation)
  // ====================================================

  Future<void> _playResponseAudio() async {
    if (_responseAudioBytes.isEmpty) {
      if (_sessionActive) {
        setState(() => _voiceState = VoiceState.listening);
      }
      return;
    }

    try {
      // --- Echo cancellation: pause recording while playing ---
      _isPlaying = true;
      await _pauseRecording();

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

      // --- Echo cancellation: small delay then resume recording ---
      // The delay ensures any residual speaker audio dissipates
      await Future.delayed(const Duration(milliseconds: 300));
      _isPlaying = false;
      await _resumeRecording();

      // Clear any audio that accumulated in the buffer during playback
      // This prevents OpenAI from processing echo audio that was captured
      _wsSend({'type': 'input_audio_buffer.clear'});

      // Return to listening if session still active
      if (_sessionActive && mounted) {
        setState(() {
          _voiceState = VoiceState.listening;
        });
      }
    } catch (e) {
      debugPrint('Playback error: $e');
      _isPlaying = false;
      await _resumeRecording();
      if (_sessionActive && mounted) {
        setState(() => _voiceState = VoiceState.listening);
      }
    }
  }

  // ====================================================
  // System prompt
  // ====================================================

  String _buildSystemPrompt() {
    UserProfile? userProfile;
    if (_userName != null && _userName!.isNotEmpty) {
      userProfile = UserProfile(
        id: _userId ?? 'anonymous',
        displayName: _userName,
        dateOfBirth: _userBirthdate,
        language: 'pt-PT',
        voicePreferences: VoicePreferences(),
        assistantName: 'AMAVEL',
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
    }

    final basePrompt = SystemPromptBuilder.buildPrompt(
      user: userProfile,
      facts: _memoryFacts.isNotEmpty ? _memoryFacts : null,
    );

    final guardrailsSection = _guardrails?.getGuardrailSystemPromptSection() ?? '';

    final languageRules = '''

--- REGRA ABSOLUTA DE LÍNGUA ---
FALA EXCLUSIVAMENTE EM PORTUGUÊS EUROPEU (pt-PT).
NUNCA fales em português do Brasil, espanhol, inglês, ou qualquer outra língua.
Se o utilizador falar noutra língua, responde SEMPRE em português europeu.
Usa vocabulário e expressões de Portugal (ex: "telemóvel" e não "celular", "autocarro" e não "ônibus").

--- REGRAS DE COMUNICAÇÃO (MUITO IMPORTANTE) ---
- Trata SEMPRE o utilizador por "você" (formal e respeitoso).
- POR DEFEITO, respostas curtas: 1 a 2 frases. Fala como numa conversa natural entre amigos.
- Faz perguntas ao utilizador para manter o diálogo vivo e bidirecional.
- Só dá respostas mais longas quando o utilizador faz uma pergunta complexa ou pede explicitamente mais detalhe.
- Prefere várias trocas curtas em vez de uma resposta longa. É uma conversa, não uma palestra.
- Fala de forma clara, simples e calorosa.
- Nunca sejas condescendente.
- Se não souberes algo, diz simplesmente que não sabes.

--- REGRAS ANTI-REPETIÇÃO (CRÍTICO) ---
- NUNCA repitas a mesma ideia duas vezes na mesma resposta ou em respostas consecutivas.
- Quando o utilizador pede silêncio ou descanso, responde UMA VEZ de forma breve e depois PÁRA. Não continues a falar.
- Cada resposta deve trazer algo NOVO à conversa. Se não tens nada novo a dizer, faz uma pergunta curta ou fica em silêncio.
- NUNCA fales contigo mesma. Espera SEMPRE que o utilizador fale antes de responderes.
- Se não houve input do utilizador, NÃO respondas. O silêncio é aceitável.
- Uma resposta = uma ideia. Não empilhes múltiplas despedidas ou reformulações da mesma mensagem.

--- MEMÓRIA ---
- Quando o utilizador partilhar informação pessoal (nomes de família, aniversários, preferências, gostos), usa a função store_memory_fact para guardar.
- No início de cada conversa, usa os factos conhecidos sobre o utilizador de forma natural.
- Apenas guarda factos com confiança >= 0.7.
''';

    return basePrompt + guardrailsSection + languageRules;
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
  // Navigation helper
  // ====================================================

  void _navigateToTab(int index) {
    if (index == 1) {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeMessages);
    } else if (index == 2) {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeSettings);
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

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: _onOrbTap,
                      child: AnimatedOrb(
                        state: _voiceState,
                        size: 280,
                      ),
                    ),
                    const SizedBox(height: 48),

                    StatusIndicator(
                      state: _voiceState,
                    ),
                    const SizedBox(height: 32),

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

            // Bottom Navigation Bar with working navigation
            ElderNavBar(
              currentIndex: 0,
              onTap: _navigateToTab,
            ),
          ],
        ),
      ),
    );
  }
}
