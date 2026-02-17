import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amavel_app/domain/models/voice_state.dart';
import 'package:amavel_app/domain/models/pipeline_mode.dart';
import 'package:amavel_app/services/voice_service.dart';
import 'package:amavel_app/services/audio_recorder.dart';
import 'package:amavel_app/services/audio_player.dart';
import 'package:amavel_app/services/system_prompt_builder.dart';
import 'package:amavel_app/services/guardrails_service.dart';
import 'package:amavel_app/services/alert_dispatcher.dart';
import 'package:amavel_app/data/repositories/memory_repository.dart';
import 'package:amavel_app/domain/usecases/memory_manager.dart';
import 'app_providers.dart';
import 'memory_providers.dart';

/// Notifier for managing voice interaction state
class VoiceStateNotifier extends StateNotifier<VoiceState> {
  VoiceStateNotifier({
    required this.audioRecorder,
    required this.audioPlayer,
    required this.systemPromptBuilder,
    required this.memoryManager,
    required this.guardrailsService,
    required this.alertDispatcher,
    required this.pipelineMode,
    required this.currentUserId,
    required this.voiceServiceFactory,
  }) : super(const VoiceState.initial());

  final AudioRecorder audioRecorder;
  final AudioPlayer audioPlayer;
  final SystemPromptBuilder systemPromptBuilder;
  final MemoryManager memoryManager;
  final GuardrailsService guardrailsService;
  final AlertDispatcher alertDispatcher;
  final PipelineMode pipelineMode;
  final String? currentUserId;
  final VoiceService Function(String systemPrompt, PipelineMode mode) voiceServiceFactory;

  late VoiceService _voiceService;

  /// Starts a voice session
  /// Initializes the voice service, connects audio streams, and begins listening
  Future<void> startVoiceSession() async {
    if (state.isActive) return;

    try {
      state = state.copyWith(isActive: true, isLoading: true);

      // Build system prompt with memory context
      final systemPrompt = await systemPromptBuilder.buildSystemPrompt();

      // Create voice service based on pipeline mode
      _voiceService = voiceServiceFactory(systemPrompt, pipelineMode);

      // Start recording audio
      await audioRecorder.start();

      // Connect audio recorder to voice service
      _setupAudioRecorderStream();

      // Listen to voice service events
      _setupVoiceServiceListeners();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isActive: false,
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Stops the voice session and cleans up resources
  Future<void> stopVoiceSession() async {
    if (!state.isActive) return;

    try {
      state = state.copyWith(isActive: false, isLoading: true);

      await audioRecorder.stop();
      await audioPlayer.stop();
      await _voiceService.stop();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Updates the current user's transcript
  void updateTranscript(String transcript) {
    state = state.copyWith(userTranscript: transcript);

    // Run distress detection on user transcript
    _runDistressDetection(transcript);
  }

  /// Updates the assistant's response transcript
  void updateAssistantTranscript(String transcript) {
    state = state.copyWith(assistantTranscript: transcript);
  }

  /// Updates audio amplitude for orb animation
  void updateAudioAmplitude(double amplitude) {
    state = state.copyWith(audioAmplitude: amplitude);
  }

  /// Switches the pipeline mode and restarts voice service if active
  Future<void> switchPipelineMode(PipelineMode newMode) async {
    if (state.isActive) {
      await stopVoiceSession();
      await Future.delayed(const Duration(milliseconds: 500));
      await startVoiceSession();
    }
  }

  /// Sets up the audio recorder stream to feed into voice service
  void _setupAudioRecorderStream() {
    audioRecorder.onAudioDataStream().listen(
      (audioData) {
        _voiceService.processAudioData(audioData);
      },
      onError: (error) {
        state = state.copyWith(error: 'Audio recording error: $error');
      },
    );
  }

  /// Sets up listeners for voice service events
  void _setupVoiceServiceListeners() {
    _voiceService.onTranscriptUpdated.listen(
      (transcript) {
        updateTranscript(transcript);
      },
    );

    _voiceService.onAssistantResponseUpdated.listen(
      (response) {
        updateAssistantTranscript(response);
      },
    );

    _voiceService.onAudioDataStream.listen(
      (audioData) async {
        // Stream audio to player
        await audioPlayer.playAudioData(audioData);

        // Update amplitude for orb animation
        final amplitude = _calculateAmplitude(audioData);
        updateAudioAmplitude(amplitude);
      },
      onError: (error) {
        state = state.copyWith(error: 'Voice service error: $error');
      },
    );

    _voiceService.onFunctionCallDetected.listen(
      (functionCall) async {
        await _processFunctionCall(functionCall);
      },
    );

    _voiceService.onSessionEnded.listen((_) {
      state = state.copyWith(isActive: false);
    });
  }

  /// Runs distress detection on the user's transcript
  Future<void> _runDistressDetection(String transcript) async {
    try {
      final distressIndicators = await guardrailsService.detectDistress(transcript);

      if (distressIndicators.isNotEmpty) {
        state = state.copyWith(distressDetected: true);
        await _dispatchAlerts(distressIndicators);
      }
    } catch (e) {
      // Log error but don't fail the session
      print('Distress detection error: $e');
    }
  }

  /// Dispatches alerts when distress is detected
  Future<void> _dispatchAlerts(List<String> distressIndicators) async {
    if (currentUserId == null) return;

    try {
      await alertDispatcher.dispatchAlert(
        userId: currentUserId!,
        indicators: distressIndicators,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Alert dispatch error: $e');
    }
  }

  /// Processes function calls from the voice service
  /// Handles memory tool calls and other function invocations
  Future<void> _processFunctionCall(Map<String, dynamic> functionCall) async {
    try {
      final functionName = functionCall['name'] as String?;
      final arguments = functionCall['arguments'] as Map<String, dynamic>?;

      if (functionName == null || arguments == null) return;

      // Handle memory-related function calls through MemoryManager
      final result = await memoryManager.executeFunctionCall(
        functionName: functionName,
        arguments: arguments,
      );

      // Send result back to voice service
      await _voiceService.submitFunctionResult(result);
    } catch (e) {
      print('Function call processing error: $e');
      state = state.copyWith(error: 'Function call error: $e');
    }
  }

  /// Calculates audio amplitude from audio data for visualization
  double _calculateAmplitude(List<int> audioData) {
    if (audioData.isEmpty) return 0.0;

    double sum = 0;
    for (final sample in audioData) {
      sum += (sample.abs() / 32768).abs();
    }

    final rms = sum / audioData.length;
    return (rms.clamp(0.0, 1.0));
  }
}

/// StateNotifierProvider for voice state management
final voiceStateProvider = StateNotifierProvider<VoiceStateNotifier, VoiceState>((ref) {
  final audioRecorder = ref.watch(audioRecorderProvider);
  final audioPlayer = ref.watch(audioPlayerProvider);
  final systemPromptBuilder = ref.watch(systemPromptBuilderProvider);
  final memoryManager = ref.watch(memoryManagerProvider);
  final guardrailsService = ref.watch(guardrailsServiceProvider);
  final alertDispatcher = ref.watch(alertDispatcherProvider);
  final pipelineMode = ref.watch(pipelineModeProvider);
  final currentUserId = ref.watch(currentUserIdProvider).value;

  return VoiceStateNotifier(
    audioRecorder: audioRecorder,
    audioPlayer: audioPlayer,
    systemPromptBuilder: systemPromptBuilder,
    memoryManager: memoryManager,
    guardrailsService: guardrailsService,
    alertDispatcher: alertDispatcher,
    pipelineMode: pipelineMode,
    currentUserId: currentUserId,
    voiceServiceFactory: (systemPrompt, mode) {
      return VoiceService.create(
        systemPrompt: systemPrompt,
        pipelineMode: mode,
      );
    },
  );
});

/// Provider for current user's transcript
final transcriptProvider = StateProvider<String>((ref) => '');

/// Provider for assistant's response transcript
final assistantTranscriptProvider = StateProvider<String>((ref) => '');

/// Provider for audio amplitude used in orb animation
final audioAmplitudeProvider = StateProvider<double>((ref) => 0.0);

/// Provider for current pipeline mode
final pipelineModeProvider = StateProvider<PipelineMode>((ref) {
  return PipelineMode.streaming;
});

/// Provider for AudioRecorder instance
final audioRecorderProvider = Provider<AudioRecorder>((ref) {
  return AudioRecorder();
});

/// Provider for AudioPlayer instance
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  return AudioPlayer();
});

/// Provider for SystemPromptBuilder instance
final systemPromptBuilderProvider = Provider<SystemPromptBuilder>((ref) {
  return SystemPromptBuilder();
});

/// Provider for GuardrailsService instance
final guardrailsServiceProvider = Provider<GuardrailsService>((ref) {
  return GuardrailsService();
});

/// Provider for AlertDispatcher instance
final alertDispatcherProvider = Provider<AlertDispatcher>((ref) {
  return AlertDispatcher();
});
