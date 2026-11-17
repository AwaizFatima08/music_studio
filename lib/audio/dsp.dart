import 'dart:math' as math;
import 'dart:typed_data';

/// Small, dependency-free DSP building blocks. Every function returns a new buffer
/// (input untouched) and works on mono floats in [-1, 1].

const double _twoPi = 2 * math.pi;

/// Plays [x] [speed] times faster (speed 2 = half as long, one octave up).
Float32List resample(Float32List x, double speed) {
  if (x.isEmpty) return Float32List(0);
  final n = ((x.length - 1) / speed).floor() + 1;
  final y = Float32List(n);
  for (var i = 0; i < n; i++) {
    final p = i * speed;
    final j = p.floor();
    final f = p - j;
    final a = x[j];
    final b = j + 1 < x.length ? x[j + 1] : a;
    y[i] = a + (b - a) * f;
  }
  return y;
}

/// WSOLA time stretch: [stretch] 2 = twice as long, same pitch.
Float32List timeStretch(Float32List x, double stretch, int sampleRate) {
  final frame = (sampleRate * 0.04).round() & ~1;
  final hs = frame ~/ 2;
  if (x.length < frame * 2) return resample(x, 1 / stretch);
  final ha = hs / stretch;
  final tol = (sampleRate * 0.01).round();
  final outLen = (x.length * stretch).round();
  final y = Float32List(outLen + frame);
  final win = Float32List(frame);
  for (var j = 0; j < frame; j++) {
    win[j] = 0.5 - 0.5 * math.cos(_twoPi * j / frame);
  }
  var prev = 0;
  for (var k = 0; ; k++) {
    final out = k * hs;
    if (out + frame > y.length) break;
    final nominal = (k * ha).round();
    var pos = nominal;
    if (k > 0) {
      final target = prev + hs;
      if (target + hs <= x.length) {
        var best = -double.infinity;
        for (var d = -tol; d <= tol; d += 2) {
          final c = nominal + d;
          if (c < 0 || c + frame > x.length) continue;
          var s = 0.0;
          for (var j = 0; j < hs; j += 4) {
            s += x[c + j] * x[target + j];
          }
          if (s > best) {
            best = s;
            pos = c;
          }
        }
      }
    }
    if (pos + frame > x.length) break;
    for (var j = 0; j < frame; j++) {
      y[out + j] += win[j] * x[pos + j];
    }
    prev = pos;
  }
  return Float32List.sublistView(y, 0, outLen);
}

/// Changes pitch by [ratio] (2 = one octave up) and keeps the length.
Float32List pitchShift(Float32List x, double ratio, int sampleRate) =>
    resample(timeStretch(x, ratio, sampleRate), ratio);

enum FilterType { lowPass, highPass }

/// RBJ biquad low/high pass.
Float32List biquad(Float32List x, int sampleRate, FilterType type, double freq, {double q = 0.707}) {
  final w0 = _twoPi * freq / sampleRate;
  final cosW = math.cos(w0);
  final alpha = math.sin(w0) / (2 * q);
  final b1 = type == FilterType.lowPass ? 1 - cosW : -(1 + cosW);
  final b0 = type == FilterType.lowPass ? b1 / 2 : -b1 / 2;
  final b2 = b0;
  final a0 = 1 + alpha;
  final a1 = -2 * cosW;
  final a2 = 1 - alpha;
  final y = Float32List(x.length);
  var x1 = 0.0;
  var x2 = 0.0;
  var y1 = 0.0;
  var y2 = 0.0;
  for (var i = 0; i < x.length; i++) {
    final v = (b0 * x[i] + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0;
    x2 = x1;
    x1 = x[i];
    y2 = y1;
    y1 = v;
    y[i] = v;
  }
  return y;
}

/// Pitch wobble from a modulated delay line.
Float32List vibrato(Float32List x, int sampleRate, double rateHz, double depthMs) {
  final depth = depthMs * sampleRate / 1000;
  final base = depth + 2;
  final y = Float32List(x.length);
  for (var i = 0; i < x.length; i++) {
    final p = i - (base + depth * math.sin(_twoPi * rateHz * i / sampleRate));
    if (p < 0) continue;
    final j = p.floor();
    final f = p - j;
    final b = j + 1 < x.length ? x[j + 1] : x[j];
    y[i] = x[j] + (b - x[j]) * f;
  }
  return y;
}

/// Multiplies by a sine carrier: metallic, robotic, alien.
Float32List ringMod(Float32List x, int sampleRate, double freq, {double mix = 1}) {
  final y = Float32List(x.length);
  for (var i = 0; i < x.length; i++) {
    final c = math.sin(_twoPi * freq * i / sampleRate);
    y[i] = x[i] * (1 - mix) + x[i] * c * mix;
  }
  return y;
}

/// Volume wobble; [depth] 1 goes fully silent at the dips.
Float32List tremolo(Float32List x, int sampleRate, double rateHz, double depth) {
  final y = Float32List(x.length);
  for (var i = 0; i < x.length; i++) {
    final m = 0.5 + 0.5 * math.sin(_twoPi * rateHz * i / sampleRate);
    y[i] = x[i] * (1 - depth * m);
  }
  return y;
}

/// Soft clipping; higher [drive] = dirtier.
Float32List distort(Float32List x, double drive) {
  final norm = _tanh(drive);
  final y = Float32List(x.length);
  for (var i = 0; i < x.length; i++) {
    y[i] = _tanh(drive * x[i]) / norm;
  }
  return y;
}

/// Lower bit depth and sample-and-hold every [hold] samples.
Float32List bitCrush(Float32List x, int bits, int hold) {
  final levels = (1 << (bits - 1)).toDouble();
  final y = Float32List(x.length);
  var held = 0.0;
  for (var i = 0; i < x.length; i++) {
    if (i % hold == 0) held = (x[i] * levels).round() / levels;
    y[i] = held;
  }
  return y;
}

/// Feedback comb: each sample gets [feedback] times the output [delayMs] earlier added.
Float32List comb(Float32List x, int sampleRate, double delayMs, double feedback) {
  final d = math.max(1, (delayMs * sampleRate / 1000).round());
  final y = Float32List(x.length);
  for (var i = 0; i < x.length; i++) {
    y[i] = x[i] + (i >= d ? feedback * y[i - d] : 0);
  }
  return y;
}

/// Repeating echo; the buffer grows so the last repeats are not cut off.
Float32List echo(Float32List x, int sampleRate, {required double delayMs, required double feedback, double wet = 0.6}) {
  final d = (delayMs * sampleRate / 1000).round();
  var tail = 0;
  for (var g = feedback; g > 0.02; g *= feedback) {
    tail += d;
  }
  final y = Float32List(x.length + tail + d);
  final line = Float32List(y.length);
  for (var i = 0; i < y.length; i++) {
    final dry = i < x.length ? x[i] : 0.0;
    final delayed = i >= d ? line[i - d] : 0.0;
    line[i] = dry + feedback * delayed;
    y[i] = dry + wet * delayed;
  }
  return y;
}

/// Freeverb-style room: 8 damped combs into 4 all-passes, with a tail.
Float32List reverb(
  Float32List x,
  int sampleRate, {
  double room = 0.84,
  double damp = 0.2,
  double wet = 0.35,
  double tailSeconds = 1.5,
}) {
  const combTunings = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617];
  const allPassTunings = [556, 441, 341, 225];
  final scale = sampleRate / 44100;
  final n = x.length + (tailSeconds * sampleRate).round();
  final acc = Float32List(n);
  for (final t in combTunings) {
    final size = math.max(1, (t * scale).round());
    final buf = Float32List(size);
    var idx = 0;
    var store = 0.0;
    for (var i = 0; i < n; i++) {
      final input = i < x.length ? x[i] * 0.015 : 0.0;
      final out = buf[idx];
      store = out * (1 - damp) + store * damp;
      buf[idx] = input + store * room;
      acc[i] += out;
      idx = (idx + 1) % size;
    }
  }
  for (final t in allPassTunings) {
    final size = math.max(1, (t * scale).round());
    final buf = Float32List(size);
    var idx = 0;
    for (var i = 0; i < n; i++) {
      final b = buf[idx];
      final out = b - acc[i];
      buf[idx] = acc[i] + b * 0.5;
      acc[i] = out;
      idx = (idx + 1) % size;
    }
  }
  final y = Float32List(n);
  for (var i = 0; i < n; i++) {
    y[i] = (i < x.length ? x[i] * (1 - wet * 0.5) : 0) + acc[i] * wet * 3;
  }
  return y;
}

/// Adds vinyl-style crackle and a little hiss (deterministic for a given [seed]).
Float32List crackle(Float32List x, int sampleRate, {double amount = 1, int seed = 7}) {
  final r = math.Random(seed);
  final y = Float32List.fromList(x);
  final popChance = 6 * amount / sampleRate;
  for (var i = 0; i < y.length; i++) {
    y[i] += (r.nextDouble() * 2 - 1) * 0.012 * amount;
    if (r.nextDouble() < popChance) {
      final len = 8 + r.nextInt(30);
      final amp = (0.1 + r.nextDouble() * 0.25) * amount * (r.nextBool() ? 1 : -1);
      for (var j = 0; j < len && i + j < y.length; j++) {
        y[i + j] += amp * (1 - j / len);
      }
    }
  }
  return y;
}

Float32List reverse(Float32List x) {
  final y = Float32List(x.length);
  for (var i = 0; i < x.length; i++) {
    y[i] = x[x.length - 1 - i];
  }
  return y;
}

/// Weighted sum of two buffers; the result is as long as the longer one.
Float32List mix(Float32List a, Float32List b, {double gainA = 1, double gainB = 1}) {
  final y = Float32List(math.max(a.length, b.length));
  for (var i = 0; i < y.length; i++) {
    y[i] = (i < a.length ? a[i] * gainA : 0) + (i < b.length ? b[i] * gainB : 0);
  }
  return y;
}

/// Cuts leading and trailing silence, keeping [marginMs] around the voice.
Float32List trimSilence(Float32List x, int sampleRate, {double threshold = 0.02, double marginMs = 80}) {
  var start = 0;
  while (start < x.length && x[start].abs() < threshold) {
    start++;
  }
  if (start == x.length) return x;
  var end = x.length - 1;
  while (end > start && x[end].abs() < threshold) {
    end--;
  }
  final m = (marginMs * sampleRate / 1000).round();
  return Float32List.sublistView(x, math.max(0, start - m), math.min(x.length, end + m + 1));
}

double peakOf(Float32List x) {
  var max = 0.0;
  for (final v in x) {
    if (v.abs() > max) max = v.abs();
  }
  return max;
}

/// Scales so the loudest sample hits [peak] (gain capped at [maxGain], so near-silence
/// is not blown up into hiss), with 10 ms fades against clicks.
Float32List normalize(Float32List x, int sampleRate, {double peak = 0.89, double maxGain = 30}) {
  final max = peakOf(x);
  final y = Float32List(x.length);
  if (max < 1e-6) return y;
  final g = math.min(peak / max, maxGain);
  final fade = math.min(x.length ~/ 2, (0.01 * sampleRate).round());
  for (var i = 0; i < x.length; i++) {
    var v = x[i] * g;
    if (i < fade) v *= i / fade;
    if (i >= x.length - fade) v *= (x.length - 1 - i) / fade;
    y[i] = v;
  }
  return y;
}

double _tanh(double v) {
  if (v > 20) return 1;
  if (v < -20) return -1;
  final e = math.exp(2 * v);
  return (e - 1) / (e + 1);
}
