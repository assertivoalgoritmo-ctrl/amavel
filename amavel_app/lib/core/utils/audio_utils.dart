import 'dart:convert';
import 'dart:typed_data';

/// Audio utilities for PCM encoding/decoding used by the voice pipeline.
class AudioUtils {
  AudioUtils._();

  /// Convert raw PCM bytes to base64 for sending via WebSocket
  static String pcmToBase64(Uint8List pcmBytes) {
    return base64Encode(pcmBytes);
  }

  /// Convert base64-encoded PCM data back to raw bytes
  static Uint8List base64ToPcm(String base64Audio) {
    return base64Decode(base64Audio);
  }

  /// Convert Int16List (PCM 16-bit) to Uint8List (raw bytes)
  static Uint8List int16ToBytes(Int16List samples) {
    return Uint8List.view(samples.buffer);
  }

  /// Convert raw bytes to Int16List (PCM 16-bit samples)
  static Int16List bytesToInt16(Uint8List bytes) {
    return Int16List.view(bytes.buffer);
  }

  /// Calculate RMS (Root Mean Square) amplitude for voice activity detection
  static double calculateRms(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty) return 0.0;

    final samples = Int16List.view(pcmBytes.buffer);
    if (samples.isEmpty) return 0.0;

    double sumSquares = 0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }

    return (sumSquares / samples.length).abs();
  }

  /// Normalize audio amplitude to 0.0 - 1.0 range
  static double normalizeAmplitude(double rms) {
    // Int16 max value is 32767
    const maxAmplitude = 32767.0 * 32767.0;
    return (rms / maxAmplitude).clamp(0.0, 1.0);
  }

  /// Create a WAV header for PCM data
  static Uint8List createWavHeader({
    required int dataLength,
    int sampleRate = 24000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final totalLength = dataLength + 36;

    final header = ByteData(44);

    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalLength, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // Chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataLength, Endian.little);

    return header.buffer.asUint8List();
  }

  /// Wrap raw PCM bytes in a WAV container
  static Uint8List pcmToWav(
    Uint8List pcmData, {
    int sampleRate = 24000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final header = createWavHeader(
      dataLength: pcmData.length,
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
    );

    final wav = Uint8List(header.length + pcmData.length);
    wav.setRange(0, header.length, header);
    wav.setRange(header.length, wav.length, pcmData);
    return wav;
  }
}
