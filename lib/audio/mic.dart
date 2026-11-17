import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'wav.dart';

/// Microphone for karaoke. The voice is streamed into memory and handed back
/// as WAV bytes: it is never written to storage and never sent anywhere.
abstract interface class Mic {
  /// Asks for the microphone permission if needed; false when refused.
  Future<bool> requestPermission();

  Future<void> start();

  /// Input loudness 0..1 while recording.
  Stream<double> get levels;

  /// Stops and returns the recording, or null when nothing was recorded.
  Future<Pcm?> stop();

  Future<void> dispose();
}

class RecordMic implements Mic {
  static const sampleRate = 44100; // the one rate every Android microphone supports

  final _rec = AudioRecorder();
  BytesBuilder? _bytes;
  StreamSubscription<Uint8List>? _sub;

  @override
  Future<bool> requestPermission() => _rec.hasPermission();

  @override
  Future<void> start() async {
    _bytes = BytesBuilder(copy: false);
    final stream = await _rec.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        // The backing track plays from the speaker while the child sings.
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      ),
    );
    _sub = stream.listen((chunk) => _bytes?.add(chunk));
  }

  // dBFS (-160..0) to 0..1, with -45 dB as the floor so quiet singing still moves the meter.
  @override
  Stream<double> get levels => _rec
      .onAmplitudeChanged(const Duration(milliseconds: 80))
      .map((a) => ((a.current + 45) / 45).clamp(0.0, 1.0))
      .map((v) => math.pow(v, 1.5).toDouble());

  @override
  Future<Pcm?> stop() async {
    try {
      await _rec.stop();
    } on Object catch (e) {
      debugPrint('[mic] stop failed: $e');
    }
    await _sub?.cancel();
    _sub = null;
    final raw = _bytes?.takeBytes();
    _bytes = null;
    if (raw == null || raw.length < 4410) return null;
    final data = ByteData.sublistView(raw);
    final out = Float32List(raw.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768;
    }
    return Pcm(out, sampleRate);
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _rec.dispose();
  }
}
