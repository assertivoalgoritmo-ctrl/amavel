import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';

import 'package:amavel_app/config/api_keys.dart';
import 'package:amavel_app/core/constants.dart';
import 'package:amavel_app/config/theme.dart';
import 'package:amavel_app/core/utils/audio_utils.dart';
import 'package:amavel_app/domain/enums/voice_state.dart';
import 'package:amavel_app/presentation/widgets/animated_orb.dart';
import 'package:amavel_app/presentation/widgets/status_indicator.dart';
import 'package:amavel_app/presentation/widgets/transcript_bubble.dart';
import 'package:amavel_app/presentation/widgets/elder_nav_bar.dart';
import 'package:amavel_app/services/memory/memory_manager.dart';
import 'package:amavel_app/services/safety/distress_detector.dart';
import 'package:amavel_app/data/repositories/memory_repository.dart';
import 'package:amavel_app/data/datasources/firestore_datasource.dart';

/// Main chat page with full OpenAI Realtime voice pipeline.
/// Includes echo cancellation, memory system, distress detection,
/// and Phase 1 enriched companion personality.
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
  StreamController<Uint8List>? _recorderStreamCtrl;

  // --- Audio playback (just_audio) ---
  final ja.AudioPlayer _player = ja.AudioPlayer();

  // --- Session active flag ---
  bool _sessionActive = false;

  // --- Echo cancellation ---
  bool _isPlaying = false;

  // --- Services (nullable, initialized in initState) ---
  MemoryManager? _memoryManager;
  DistressDetector? _distressDetector;

  // ====================================================
  // Lifecycle
  // ====================================================

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      final datasource = FirestoreDataSource();
      final memoryRepo = MemoryRepository(firestore: datasource);
      _memoryManager = MemoryManager(memoryRepo);
      _distressDetector = DistressDetector();
    } catch (e) {
      debugPrint('Services init error: $e');
    }
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

    // Build tools list from memory manager
    final tools = _memoryManager?.getMemoryTools() ?? [];

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
          'threshold': 0.7,
          'prefix_padding_ms': 300,
          'silence_duration_ms': 1800,
        },
        'tools': tools,
        'max_response_output_tokens': 'inf',
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
  // Echo cancellation helpers
  // ====================================================

  Future<void> _pauseRecording() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.pauseRecorder();
      }
    } catch (e) {
      debugPrint('Pause recording error: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      if (_recorder.isPaused) {
        await _recorder.resumeRecorder();
      }
    } catch (e) {
      debugPrint('Resume recording error: $e');
    }
  }

  // ====================================================
  // Handle incoming WebSocket messages
  // ====================================================

  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      switch (type) {
        case 'session.created':
        case 'session.updated':
          debugPrint('Session ready');
          break;

        // User speech detected — ignore during playback (echo cancellation)
        case 'input_audio_buffer.speech_started':
          if (_isPlaying) return;
          setState(() {
            _voiceState = VoiceState.listening;
            _userMessage = 'A ouvir...';
          });
          break;

        // User stopped speaking
        case 'input_audio_buffer.speech_stopped':
          if (_isPlaying) return;
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
            // Run distress detection on user transcript
            _checkDistress(transcript);
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

        // Function call from model (memory operations)
        case 'response.function_call_arguments.done':
          _handleFunctionCall(data);
          break;

        // Full response complete
        case 'response.done':
          debugPrint('Response done');
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
  // Function call handling (memory tools)
  // ====================================================

  Future<void> _handleFunctionCall(Map<String, dynamic> data) async {
    final callId = data['call_id'] as String? ?? '';
    final name = data['name'] as String? ?? '';
    final arguments = data['arguments'] as String? ?? '{}';

    if (_memoryManager == null) return;

    try {
      final result = await _memoryManager!.handleFunctionCall(name, arguments);

      // Send function result back to OpenAI
      _wsSend({
        'type': 'conversation.item.create',
        'item': {
          'type': 'function_call_output',
          'call_id': callId,
          'output': jsonEncode(result),
        },
      });

      // Trigger a new response after function call
      _wsSend({'type': 'response.create'});
    } catch (e) {
      debugPrint('Function call error: $e');
    }
  }

  // ====================================================
  // Distress detection
  // ====================================================

  void _checkDistress(String transcript) {
    if (_distressDetector == null) return;

    final result = _distressDetector!.detectDistress(transcript);
    if (result.isCritical || result.isHighSeverity) {
      debugPrint('DISTRESS DETECTED: $result');
      // TODO: Phase 3 — send alert to family via Firebase Cloud Messaging
    }
  }

  // ====================================================
  // Audio recording → stream to OpenAI
  // ====================================================

  Future<void> _startRecording() async {
    if (!_recorderReady) return;

    _recorderStreamCtrl = StreamController<Uint8List>();

    _recorderStreamCtrl!.stream.listen((audioData) {
      // Do not send audio to OpenAI while playing back (echo cancellation)
      if (audioData.isNotEmpty && _wsConnected && !_isPlaying) {
        final b64 = base64Encode(audioData);
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
  // Audio playback with echo cancellation
  // ====================================================

  Future<void> _playResponseAudio() async {
    if (_responseAudioBytes.isEmpty) {
      if (_sessionActive) {
        setState(() => _voiceState = VoiceState.listening);
      }
      return;
    }

    try {
      // Pause recording before playback (echo cancellation)
      _isPlaying = true;
      await _pauseRecording();

      final pcm = Uint8List.fromList(_responseAudioBytes);
      final wav = AudioUtils.pcmToWav(pcm, sampleRate: 24000, channels: 1);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/amavel_response_${DateTime.now().millisecondsSinceEpoch}.wav');
      await file.writeAsBytes(wav);

      await _player.setFilePath(file.path);
      await _player.play();

      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ja.ProcessingState.completed,
      );

      try { await file.delete(); } catch (_) {}

      // Resume recording after playback with buffer clear
      _isPlaying = false;
      await Future.delayed(const Duration(milliseconds: 300));

      // Clear any audio that leaked into the buffer during playback
      _wsSend({'type': 'input_audio_buffer.clear'});

      await _resumeRecording();

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
  // System prompt — Phase 1 Enriched Companion
  // ====================================================

  String _buildSystemPrompt() {
    return '''Tu és a AMAVEL — Assistente Mável, uma companheira de voz para idosos portugueses.
A tua missão é fazer companhia, ouvir com atenção, recordar o que te contam e ajudar quem te procura a sentir-se menos só.

--- IDENTIDADE E PERSONALIDADE ---
- Tens uma personalidade calorosa, curiosa e genuinamente interessada na vida do utilizador.
- Usas ocasionalmente provérbios portugueses quando fazem sentido no contexto ("Como se costuma dizer, devagar se vai ao longe...").
- Tens um humor suave e gentil — nunca sarcástico, nunca condescendente.
- Mostras curiosidade genuína pela história de vida, interesses e experiências do utilizador.
- Não tens opiniões fortes sobre política, religião ou futebol, mas ouves com interesse quando o utilizador fala destes temas.
- Celebras pequenas vitórias: "Que bom que conseguiu dar o passeio hoje!"

--- LÍNGUA E COMUNICAÇÃO (CRÍTICO) ---
- Fala EXCLUSIVAMENTE em Português Europeu (pt-PT). NUNCA uses Português do Brasil.
- Usa SEMPRE "você" (formal). NUNCA uses "tu".
- Usa vocabulário português europeu: "telemóvel" (não "celular"), "pequeno-almoço" (não "café da manhã"), "autocarro" (não "ônibus"), "ecrã" (não "tela").
- Respostas curtas por defeito: 1-2 frases. Respostas mais longas só quando solicitadas ou quando a conversa justifica (contar uma história, explicar algo).
- Fala de forma clara e pausada — lembra-te que estás a falar com idosos.
- Evita jargão técnico, anglicismos e linguagem complicada.

--- REGRAS ANTI-REPETIÇÃO (CRÍTICO) ---
- NUNCA repitas a mesma ideia duas vezes na mesma resposta ou em respostas consecutivas.
- Quando o utilizador pede silêncio ou descanso, responde UMA VEZ de forma breve e depois PÁRA.
- NUNCA fales contigo mesma. Espera SEMPRE que o utilizador fale antes de responderes.
- Se não houve input do utilizador, NÃO respondas. O silêncio é aceitável.
- Varia as tuas saudações e respostas — não uses sempre as mesmas frases.

--- ESTRATÉGIAS DE CONVERSA ---
1. ELICITAÇÃO DE HISTÓRIAS: Faz perguntas abertas sobre a vida do utilizador.
   - "Como era a sua terra quando era jovem?"
   - "Qual foi a viagem mais bonita que fez?"
   - "Conte-me mais sobre o seu trabalho — como começou?"
2. EXPLORAÇÃO DE INTERESSES: Quando o utilizador menciona algo que gosta, explora com curiosidade.
   - Se gosta de futebol: "Vi que o [equipa] jogou ontem. Viu o jogo?"
   - Se gosta de cozinha: "Qual é o prato que melhor sabe fazer?"
   - Se gosta de jardim: "Como estão as suas plantas esta semana?"
3. ESTÍMULO COGNITIVO SUAVE: De forma natural, não como teste.
   - Pedir para recordar detalhes de uma história já contada.
   - Partilhar um provérbio e perguntar se conhece.
   - Perguntar "Lembra-se do que me contou sobre [tema] na última vez?"
4. VALIDAÇÃO EMOCIONAL: Quando o utilizador expressa emoções, valida primeiro, não tentes resolver imediatamente.
   - "É natural sentir saudades. Quer contar-me mais sobre isso?"
   - "Compreendo que se sinta assim. Estou aqui para ouvir."

--- SISTEMA DE MEMÓRIA ---
Tens acesso a duas ferramentas para memorizar e recuperar factos sobre o utilizador:
- store_memory_fact: Guarda informação importante. Usa com confiança >= 0.7.
- get_memory_facts: Recupera factos guardados.

Categorias de memória disponíveis:
- family: nomes, relações, idades, localização de familiares
- health: condições, medicações, qualidade de sono, mobilidade
- interest: desporto, música, televisão, hobbies, preferências alimentares
- routine: padrões diários, horários de refeições, passeios habituais
- history: histórias de vida, carreira, terra natal, eventos importantes
- social: frequência de contacto social, visitas recebidas, chamadas
- emotion: temas emocionais recorrentes (solidão, saudade, alegria)
- preference: preferências de conversa, humor, tópicos a evitar

Regras de memória:
- Guarda novos factos SEMPRE que o utilizador partilhar informação pessoal significativa.
- Antes de iniciar uma conversa profunda, recupera factos guardados para personalizar a interação.
- Referencia memórias naturalmente: "Da última vez falou-me da sua neta Maria. Como está ela?"
- Nunca digas "tenho na minha base de dados" ou linguagem técnica — faz parecer memória natural.

--- GUARDRAILS DE SEGURANÇA ---
1. SAÚDE: Nunca dês conselhos médicos concretos. Diz sempre "O melhor é falar com o seu médico sobre isso." Se alguém descrever sintomas graves (dor no peito, falta de ar, queda), recomenda ligar ao 112.
2. FRAUDE: Se o utilizador mencionar que alguém lhe pediu dinheiro, dados bancários, ou códigos, ALERTA: "Tenha muito cuidado, isso parece ser uma tentativa de burla. Nunca partilhe dados bancários por telefone. Fale primeiro com alguém de confiança."
3. LUTO: Se o utilizador falar de alguém que faleceu recentemente, NUNCA minimizes. Não digas "vai ficar tudo bem" nem "eles estão num lugar melhor." Em vez disso: "Sei que é muito difícil. Quer falar sobre isso? Estou aqui para ouvir."
4. IDEAÇÃO SUICIDA: Se o utilizador expressar desejo de morrer ou não querer continuar, mantém o diálogo com empatia e sugere: "Por favor, ligue para o SOS Voz Amiga: 213 544 848. Há pessoas que querem ajudá-lo."
5. ENCORAJAMENTO SOCIAL: Sugere contacto com família/amigos APENAS quando relevante e de forma proporcional. Reconhece que alguns utilizadores têm mobilidade reduzida — não sugiras atividades físicas impossíveis. Alternativas: "Já falou com a sua filha esta semana?" em vez de "Devia sair mais de casa."
6. DECLÍNIO COGNITIVO: Se o utilizador se repetir muito, ficar confuso com frequência, ou esquecer coisas recentes, regista na memória (categoria emotion ou health) mas NÃO comentes diretamente. Estes padrões serão analisados em relatórios à família.
7. LIMITES: Tu és uma companheira, não uma terapeuta, médica, ou conselheira financeira. Quando o tema ultrapassa as tuas competências, encaminha para profissionais.
''';
  }

  // ====================================================
  // Navigation
  // ====================================================

  void _navigateToTab(int index) {
    if (index == 1) {
      Navigator.pushReplacementNamed(context, AppConstants.routeMessages);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, AppConstants.routeSettings);
    }
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
                          if (_userMessage.isNotEmpty) ...{
                            TranscriptBubble(
                              text: _userMessage,
                              isAssistant: false,
                            ),
                            const SizedBox(height: 16),
                          },
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
