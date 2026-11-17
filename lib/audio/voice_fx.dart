import 'dart:isolate';
import 'dart:typed_data';

import 'dsp.dart';
import 'wav.dart';

/// How the child's karaoke voice comes back. Pitch effects keep the length, so
/// the voice stays in time with the backing track.
enum KaraokeVoice {
  star('Pop Star', '🌟', 0xFFFFC93C),
  echo('Big Hall', '🏰', 0xFF8E62FF),
  chipmunk('Chipmunk', '🐿️', 0xFFFF9F43),
  giant('Giant', '🦕', 0xFF4DABF7),
  robot('Robot', '🤖', 0xFF74C0FC);

  const KaraokeVoice(this.title, this.emoji, this.color);

  final String title;
  final String emoji;
  final int color;
}

Float32List applyKaraokeVoice(Float32List x, int sr, KaraokeVoice v) {
  switch (v) {
    case KaraokeVoice.star:
      return reverb(biquad(x, sr, FilterType.highPass, 90), sr, room: 0.6, wet: 0.18, tailSeconds: 0.8);
    case KaraokeVoice.echo:
      final wet = echo(x, sr, delayMs: 220, feedback: 0.35, wet: 0.45);
      return reverb(wet, sr, room: 0.9, damp: 0.4, wet: 0.35, tailSeconds: 1.5);
    case KaraokeVoice.chipmunk:
      return biquad(pitchShift(x, 1.5, sr), sr, FilterType.highPass, 150);
    case KaraokeVoice.giant:
      return reverb(biquad(pitchShift(x, 0.68, sr), sr, FilterType.lowPass, 3200), sr, room: 0.85, wet: 0.22);
    case KaraokeVoice.robot:
      final metal = comb(ringMod(x, sr, 70), sr, 9, 0.5);
      return mix(metal, x, gainA: 0.75, gainB: 0.3);
  }
}

/// Drops [leadSeconds] from the start (the time between the microphone
/// starting and the backing track starting), applies [voice] and normalises.
/// Returns a WAV that lines up with the backing track from 0 s.
Uint8List renderKaraokeVoice(Pcm recording, KaraokeVoice voice, double leadSeconds) {
  final sr = recording.sampleRate;
  final skip = (leadSeconds * sr).round().clamp(0, recording.samples.length);
  final aligned = Float32List.sublistView(recording.samples, skip);
  // Low pass gently first: echo-cancelled phone mics leave hiss.
  final clean = biquad(aligned, sr, FilterType.lowPass, 9000);
  return encodeWav(Pcm(normalize(applyKaraokeVoice(clean, sr, voice), sr, peak: 0.8, maxGain: 12), sr));
}

Future<Uint8List> renderKaraokeVoiceInBackground(Pcm recording, KaraokeVoice voice, double leadSeconds) =>
    Isolate.run(() => renderKaraokeVoice(recording, voice, leadSeconds));
