import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:amavel_app/core/logger/app_logger.dart';
import 'package:amavel_app/core/utils/audio_utils.dart';

/// Service for playing audio streamed from the voice service
/// Handles PCM16 audio accumulation and playback
class AudioPlayer {
  static const int _chunkSize = 8192;

  late final AudioPlayer _audioPlayer;
  late final StreamController<double> _amplitudeController;

  bool _isPlaying = false;
  bool _isClosed = false;
  Uint8List _audioBuffer = Uint8List(0);
  Timer? _amplitudeTimer;
  File? _currentTempFile;

  /// Stream of amplitude values for visualization (0.0 to 1.0)
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Whether audio is currently playing
  bool get isPlaying => _isPlaying;

  AudioPlayer() {
    _audioPlayer = AudioPlayer();
    _amplitudeController = StreamController<double>.broadcast();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playbackEventStream.listen(
      (event) {
        if (event.processingState == ProcessingState.completed) {
          _isPlaying = false;
          AppLogger.info('Audio playback completed');
        }
      },
      onError: (error) {
        AppLogger.error('Audio player error: $error');
        _isPlaying = false;
      },
    );
  }

  /// Play PCM16 audio data
  /// Accumulates chunks and plays when audio becomes available
  Future<void> play(Uint8List pcmAudio) async {
    if (_isClosed) {
      throw Exception('AudioPlayer is closed');
    }

    try {
      // Accumulate audio
      _audioBuffer = Uint8List(_audioBuffer.length + pcmAudio.length);
      _audioBuffer.setRange(0, _audioBuffer.length - pcmAudio.length, _audioBuffer);
      _audioBuffer.setRange(
        _audioBuffer.length - pcmAudio.length,
        _audioBuffer.length,
        pcmAudio,
      );

      // Start playing if we have enough data and not already playing
      if (!_isPlaying && _audioBuffer.length >= _chunkSize) {
        await _startPlayback();
      }
    } catch (e, st) {
      AppLogger.error('Error playing audio', e, st);
      rethrow;
    }
  }

  /// Add audio chunk to playback buffer
  Future<void> addAudioChunk(Uint8List pcmAudio) async {
    if (_isClosed) {
      throw Exception('AudioPlayer is closed');
    }

    try {
      // Append to buffer
      final newBuffer = Uint8List(_audioBuffer.length + pcmAudio.length);
      newBuffer.setRange(0, _audioBuffer.length, _audioBuffer);
      newBuffer.setRange(_audioBuffer.length, newBuffer.length, pcmAudio);
      _audioBuffer = newBuffer;

      // If not playing and we have enough data, start playback
      if (!_isPlaying && _audioBuffer.length >= _chunkSize) {
        await _startPlayback();
      }
    } catch (e, st) {
      AppLogger.error('Error adding audio chunk', e, st);
      rethrow;
    }
  }

  /// Called when audio generation is complete
  /// Plays any remaining buffered audio
  Future<void> finalizeAudio() async {
    if (_audioBuffer.isNotEmpty) {
      await _playBuffer();
    }
  }

  Future<void> _startPlayback() async {
    if (_isPlaying) {
      return;
    }

    try {
      _isPlaying = true;
      AppLogger.info('Starting audio playback (buffer: ${_audioBuffer.length} bytes)');

      // Convert PCM to WAV
      final wavData = AudioUtils.pcmToWav(_audioBuffer, 24000, 1);

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      _currentTempFile = File('${tempDir.path}/audio_playback_${DateTime.now().millisecondsSinceEpoch}.wav');
      await _currentTempFile!.writeAsBytes(wavData);

      AppLogger.info('Created temp audio file: ${_currentTempFile!.path}');

      // Set audio source and play
      await _audioPlayer.setFilePath(_currentTempFile!.path);
      await _audioPlayer.play();

      // Start amplitude monitoring
      _startAmplitudeMonitoring();

      _audioBuffer = Uint8List(0);
    } catch (e, st) {
      AppLogger.error('Error starting playback', e, st);
      _isPlaying = false;
      rethrow;
    }
  }

  Future<void> _playBuffer() async {
    if (_audioBuffer.isEmpty || _isPlaying) {
      return;
    }

    try {
      await _startPlayback();
    } catch (e, st) {
      AppLogger.error('Error playing buffer', e, st);
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (_isPlaying) {
          // Estimate amplitude from playback position
          final position = _audioPlayer.position;
          final duration = _audioPlayer.duration ?? Duration.zero;

          if (duration.inMilliseconds > 0) {
            final progress = position.inMilliseconds / duration.inMilliseconds;
            final amplitude = (progress < 0.5 ? progress * 2 : (1 - progress) * 2).clamp(0.0, 1.0);

            if (!_amplitudeController.isClosed) {
              _amplitudeController.add(amplitude);
            }
          }
        }
      },
    );
  }

  /// Stop audio playback
  Future<void> stop() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
        _audioBuffer = Uint8List(0);
        _amplitudeTimer?.cancel();
        AppLogger.info('Audio playback stopped');
      }

      // Clean up temp file
      if (_currentTempFile != null && await _currentTempFile!.exists()) {
        await _currentTempFile!.delete();
        _currentTempFile = null;
      }
    } catch (e, st) {
      AppLogger.error('Error stopping playback', e, st);
    }
  }

  /// Pause audio playback
  Future<void> pause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        AppLogger.info('Audio playback paused');
      }
    } catch (e, st) {
      AppLogger.error('Error pausing playback', e, st);
    }
  }

  /// Resume audio playback
  Future<void> resume() async {
    try {
      if (_isPlaying && _audioPlayer.paused) {
        await _audioPlayer.play();
        AppLogger.info('Audio playback resumed');
      }
    } catch (e, st) {
      AppLogger.error('Error resuming playback', e, st);
    }
  }

  /// Set the volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e, st) {
      AppLogger.error('Error setting volume', e, st);
    }
  }

  /// Get current playback position
  Duration get position => _audioPlayer.position;

  /// Get total audio duration
  Duration? get duration => _audioPlayer.duration;

  /// Clean up resources
  Future<void> dispose() async {
    _isClosed = true;

    try {
      _amplitudeTimer?.cancel();

      if (_isPlaying) {
        await stop();
      }

      await _audioPlayer.dispose();
      await _amplitudeController.close();

      // Clean up temp file
      if (_currentTempFile != null && await _currentTempFile!.exists()) {
        await _currentTempFile!.delete();
      }

      AppLogger.info('AudioPlayer disposed');
    } catch (e, st) {
      AppLogger.error('Error disposing AudioPlayer', e, st);
    }
  }
}
