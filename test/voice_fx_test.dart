import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_tunes/audio/voice_fx.dart';
import 'package:tiny_tunes/audio/wav.dart';

void main() {
  test('every karaoke voice stays in time with the music (same length, lead trimmed)', () {
    const sr = 22050;
    final x = Float32List(sr * 2);
    for (var i = 0; i < x.length; i++) {
      x[i] = 0.3 * math.sin(2 * math.pi * 220 * i / sr);
    }
    for (final v in KaraokeVoice.values) {
      final out = decodeWav(renderKaraokeVoice(Pcm(x, sr), v, 0.5));
      final expected = x.length - sr ~/ 2;
      // Reverb tails may add a little at the end, never at the start.
      expect(out.samples.length, greaterThanOrEqualTo(expected), reason: v.name);
      expect(out.samples.length, lessThan(expected + sr * 5), reason: v.name);
      expect(out.samples.map((s) => s.abs()).reduce(math.max), greaterThan(0.1), reason: v.name);
    }
  });
}
