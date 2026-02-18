import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:amavel_app/core/logger/app_logger.dart';

/// Service for recording audio from the device microphone
/// Records PCM16 audio at 24kHz in mono format using flutter_sound
class AudioRecorder {
  static const int _sampleRate = 24000;
  static const int _channels = 1;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<RecorderState> _stateController =
      StreamController<RecorderState>.broadcast();

  bool _isRecording = false;
  bool _isInitialized = false;
  StreamSubscription? _recordingDataSubscription;

  /// Stream of audio chunks (PCM16, 24kHz, mono)
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  /// Alias used by voice_providers.dart
  Stream<Uint8List> onAudioDataStream() => audioStream;

  /// Stream of recorder state changes
  Stream<RecorderState> get stateStream => _stateController.stream;

  /// Whether the recorder is currently active
  bool get isRecording => _isRecording;

  /// Initialize the recorder — must be called before start
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
    _isInitialized = true;
  }

  /// Start recording from the microphone
  /// Requests microphone permission if needed
  Future<void> startRecording() async {
    if (_isRecording) {
      AppLogger.warning('Already recording');
      return;
    }

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission denied');
      }

      await _ensureInitialized();

      AppLogger.info('Starting audio recording');

      // Create a StreamController to receive PCM data from the recorder
      final recordingDataController = StreamController<Food>();

      recordingDataController.stream.listen((food) {
        if (food is FoodData && food.data != null) {
          final data = Uint8List.fromList(food.data!);
          if (!_audioStreamController.isClosed) {
            _audioStreamController.add(data);
          }
        }
      });

      // Start recording to stream (PCM16, 24kHz, mono)
      await _recorder.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        sampleRate: _sampleRate,
        numChannels: _channels,
      );

      _isRecording = true;
      _emitState(RecorderState.recording);

      AppLogger.info('Audio recording started at ${_sampleRate}Hz mono');
    } catch (e, st) {
      AppLogger.error('Error starting recording', e, st);
      _isRecording = false;
      _emitState(RecorderState.stopped);
      rethrow;
    }
  }

  /// Alias used by voice_providers.dart
  Future<void> start() => startRecording();

  /// Stop recording and return empty buffer
  Future<Uint8List> stopRecording() async {
    if (!_isRecording) {
      AppLogger.warning('Not currently recording');
      return Uint8List(0);
    }

    try {
      AppLogger.info('Stopping audio recording');

      await _recorder.stopRecorder();
      _recordingDataSubscription?.cancel();
      _recordingDataSubscription = null;

      _isRecording = false;
      _emitState(RecorderState.stopped);

      AppLogger.info('Audio recording stopped');
      return Uint8List(0);
    } catch (e, st) {
      AppLogger.error('Error stopping recording', e, st);
      _isRecording = false;
      _emitState(RecorderState.stopped);
      rethrow;
    }
  }

  /// Alias used by voice_providers.dart
  Future<void> stop() => stopRecording();

  /// Cancel current recording without saving
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();
      _recordingDataSubscription?.cancel();
      _recordingDataSubscription = null;
      _isRecording = false;
      _emitState(RecorderState.stopped);
      AppLogger.info('Audio recording cancelled');
    } catch (e, st) {
      AppLogger.error('Error cancelling recording', e, st);
    }
  }

  /// Pause recording temporarily
  Future<void> pauseRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.pauseRecorder();
      _emitState(RecorderState.paused);
      AppLogger.info('Audio recording paused');
    } catch (e, st) {
      AppLogger.error('Error pausing recording', e, st);
    }
  }

  /// Resume recording after pause
  Future<void> resumeRecording() async {
    try {
      await _recorder.resumeRecorder();
      _emitState(RecorderState.recording);
      AppLogger.info('Audio recording resumed');
    } catch (e, st) {
      AppLogger.error('Error resuming recording', e, st);
    }
  }

  /// Check microphone permission status
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void _emitState(RecorderState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      _recordingDataSubscription?.cancel();
      await _audioStreamController.close();
      await _stateController.close();
      if (_isInitialized) {
        await _recorder.closeRecorder();
        _isInitialized = false;
      }
      AppLogger.info('AudioRecorder disposed');
    } catch (e, st) {
      AppLogger.error('Error disposing AudioRecorder', e, st);
    }
  }
}

/// Enumeration of recorder states
enum RecorderState {
  recording,
  paused,
  stopped,
}
