import 'dart:typed_data';

/// Mono audio as floats in [-1, 1] plus its sample rate.
class Pcm {
  const Pcm(this.samples, this.sampleRate);

  final Float32List samples;
  final int sampleRate;

  Duration get duration => Duration(microseconds: samples.length * Duration.microsecondsPerSecond ~/ sampleRate);
}

class WavFormatException implements Exception {
  const WavFormatException(this.message);

  final String message;

  @override
  String toString() => 'WavFormatException: $message';
}

/// Reads 16-bit PCM WAV (any channel count; channels are averaged to mono).
Pcm decodeWav(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (bytes.length < 12 || _tag(bytes, 0) != 'RIFF' || _tag(bytes, 8) != 'WAVE') {
    throw const WavFormatException('not a RIFF/WAVE file');
  }
  var channels = 0;
  var sampleRate = 0;
  var bits = 0;
  var pos = 12;
  while (pos + 8 <= bytes.length) {
    final id = _tag(bytes, pos);
    var size = data.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (id == 'fmt ') {
      channels = data.getUint16(body + 2, Endian.little);
      sampleRate = data.getUint32(body + 4, Endian.little);
      bits = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      if (channels == 0 || bits != 16) {
        throw WavFormatException('unsupported format: $channels ch, $bits bit');
      }
      // Recorders that are stopped early can leave a wrong or 0xFFFFFFFF size.
      if (size == 0 || body + size > bytes.length) size = bytes.length - body;
      final frames = size ~/ (2 * channels);
      final out = Float32List(frames);
      for (var i = 0; i < frames; i++) {
        var sum = 0;
        for (var c = 0; c < channels; c++) {
          sum += data.getInt16(body + (i * channels + c) * 2, Endian.little);
        }
        out[i] = sum / (channels * 32768);
      }
      return Pcm(out, sampleRate);
    }
    pos = body + size + (size.isOdd ? 1 : 0);
  }
  throw const WavFormatException('no data chunk');
}

/// Writes mono 16-bit PCM WAV, clipping to [-1, 1].
Uint8List encodeWav(Pcm pcm) {
  final n = pcm.samples.length;
  final bytes = Uint8List(44 + n * 2);
  final d = ByteData.sublistView(bytes);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      bytes[at + i] = s.codeUnitAt(i);
    }
  }

  tag(0, 'RIFF');
  d.setUint32(4, 36 + n * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  d
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, pcm.sampleRate, Endian.little)
    ..setUint32(28, pcm.sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  tag(36, 'data');
  d.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final v = pcm.samples[i].clamp(-1.0, 1.0);
    d.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return bytes;
}

String _tag(Uint8List b, int at) => String.fromCharCodes(b, at, at + 4);
