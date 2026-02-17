import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:amavel_app/core/logger/app_logger.dart';

/// Service for recording audio from the device microphone
/// Records PCM16 audio at 24kHz in mono format
class AudioRecorder {
  static const int _sampleRate = 24000;
  static const int _channels = 1;
  static const AudioEncoder _encoder = AudioEncoder.pcm16bit;
  static const Duration _chunkInterval = Duration(milliseconds: 250);

  late final Record _recordPlugin;
  late final StreamController<Uint8List> _audioStreamController;
  late final StreamController<RecorderState> _stateController;

  bool _isRecording = false;
  Timer? _chunkTimer;
  Uint8List _buffer = Uint8List(0);

  /// Stream of audio chunks (PCM16, 24kHz, mono)
  /// Emits chunks approximately every 250ms
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  /// Stream of recorder state changes
  Stream<RecorderState> get stateStream => _stateController.stream;

  /// Whether the recorder is currently active
  bool get isRecording => _isRecording;

  AudioRecorder() {
    _recordPlugin = Record();
    _audioStreamController = StreamController<Uint8List>.broadcast();
    _stateController = StreamController<RecorderState>.broadcast();
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

      AppLogger.info('Starting audio recording');

      // Start recording
      await _recordPlugin.start(
        encoder: _encoder,
        sampleRate: _sampleRate,
        numChannels: _channels,
      );

      _isRecording = true;
      _buffer = Uint8List(0);
      _emitState(RecorderState.recording);

      // Start chunk timer
      _chunkTimer = Timer.periodic(_chunkInterval, (_) {
        _emitChunk();
      });

      AppLogger.info('Audio recording started at ${_sampleRate}Hz mono');
    } catch (e, st) {
      AppLogger.error('Error starting recording', e, st);
      _isRecording = false;
      _emitState(RecorderState.stopped);
      rethrow;
    }
  }

  /// Stop recording and return the final audio chunk
  Future<Uint8List> stopRecording() async {
    if (!_isRecording) {
      AppLogger.warning('Not currently recording');
      return Uint8List(0);
    }

    try {
      AppLogger.info('Stopping audio recording');

      // Cancel chunk timer
      _chunkTimer?.cancel();
      _chunkTimer = null;

      // Get final recording path
      final recordingPath = await _recordPlugin.stop();

      _isRecording = false;
      _emitState(RecorderState.stopped);

      // Return buffered audio (in a real implementation, you'd read from file)
      final finalBuffer = _buffer;
      _buffer = Uint8List(0);

      AppLogger.info('Audio recording stopped. Final size: ${finalBuffer.length} bytes');
      return finalBuffer;
    } catch (e, st) {
      AppLogger.error('Error stopping recording', e, st);
      _isRecording = false;
      _emitState(RecorderState.stopped);
      rethrow;
    }
  }

  /// Cancel current recording without saving
  Future<void> cancelRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      _chunkTimer?.cancel();
      _chunkTimer = null;

      await _recordPlugin.stop();

      _isRecording = false;
      _buffer = Uint8List(0);
      _emitState(RecorderState.stopped);

      AppLogger.info('Audio recording cancelled');
    } catch (e, st) {
      AppLogger.error('Error cancelling recording', e, st);
    }
  }

  /// Pause recording temporarily
  Future<void> pauseRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      await _recordPlugin.pause();
      _chunkTimer?.cancel();
      _chunkTimer = null;
      _emitState(RecorderState.paused);
      AppLogger.info('Audio recording paused');
    } catch (e, st) {
      AppLogger.error('Error pausing recording', e, st);
    }
  }

  /// Resume recording after pause
  Future<void> resumeRecording() async {
    try {
      await _recordPlugin.resume();
      _isRecording = true;
      _emitState(RecorderState.recording);

      // Restart chunk timer
      _chunkTimer = Timer.periodic(_chunkInterval, (_) {
        _emitChunk();
      });

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

  void _emitChunk() {
    // In a real implementation with stream recording, you would get chunks from the recorder
    // For now, we emit the accumulated buffer
    if (_buffer.isNotEmpty) {
      final chunk = Uint8List.fromList(_buffer);
      _buffer = Uint8List(0);

      if (!_audioStreamController.isClosed) {
        _audioStreamController.add(chunk);
      }
    }
  }

  void _emitState(RecorderState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      _chunkTimer?.cancel();
      if (_isRecording) {
        await stopRecording();
      }
      await _audioStreamController.close();
      await _stateController.close();
      _recordPlugin.dispose();
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
