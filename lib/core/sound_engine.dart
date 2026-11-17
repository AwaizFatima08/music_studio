import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// A playing backing track (and, when listening back, the child's voice on top).
abstract class Track {
  /// Seconds into the backing track.
  double get position;

  double get length;

  bool get finished;

  Future<void> stop();
}

/// Plays the pre-made sounds in assets/sounds/ and the karaoke tracks. Behind
/// an interface so tests can record what was played instead of making noise.
abstract class SoundEngine {
  Future<void> init();

  /// Loads short sounds (names from assets/sounds/, without .ogg) into memory.
  /// Already-loaded names are skipped, so screens can call it on every visit.
  Future<void> load(Iterable<String> names);

  void play(String name, {double gain = 1, double pan = 0});

  /// Starts a backing track, optionally with a recorded voice WAV mixed on top,
  /// both starting at the same instant. Null if it could not be played.
  Future<Track?> playTrack(String asset, {Uint8List? voiceWav, double voiceGain = 1, double trackGain = 1});

  /// 0..1 as shown on the slider; the engine applies a loudness curve.
  set volume(double v);
}

/// Low-latency, many-voices-at-once playback with SoLoud (children press
/// several keys at a time).
class SoLoudEngine implements SoundEngine {
  final _sources = <String, AudioSource>{};
  final _loading = <String, Future<void>>{};
  double _volume = 0.7;

  @override
  Future<void> init() async {
    try {
      final s = SoLoud.instance;
      if (!s.isInitialized) await s.init(bufferSize: 512, sampleRate: 44100);
      s.setMaxActiveVoiceCount(32);
      s.setGlobalVolume(_curve(_volume));
    } on Object catch (e) {
      debugPrint('[sound] init failed: $e'); // the app still works, just silent
    }
  }

  @override
  Future<void> load(Iterable<String> names) async {
    if (!SoLoud.instance.isInitialized) return;
    await Future.wait([for (final n in names) _loading[n] ??= _loadOne(n)]);
  }

  Future<void> _loadOne(String name) async {
    try {
      _sources[name] = await SoLoud.instance.loadAsset('assets/sounds/$name.ogg');
    } on Object catch (e) {
      debugPrint('[sound] load $name failed: $e');
    }
  }

  @override
  void play(String name, {double gain = 1, double pan = 0}) {
    final src = _sources[name];
    if (src == null) return;
    try {
      SoLoud.instance.play(src, volume: gain, pan: pan);
    } on Object catch (e) {
      debugPrint('[sound] play $name failed: $e');
    }
  }

  @override
  Future<Track?> playTrack(String asset, {Uint8List? voiceWav, double voiceGain = 1, double trackGain = 1}) async {
    final s = SoLoud.instance;
    if (!s.isInitialized) return null;
    try {
      final track = await s.loadAsset(asset);
      final voice = voiceWav == null ? null : await s.loadMem('voice-${identityHashCode(voiceWav)}.wav', voiceWav);
      final h = s.play(track, volume: trackGain, paused: true);
      final v = voice == null ? null : s.play(voice, volume: voiceGain, paused: true);
      s.setPause(h, false);
      if (v != null) s.setPause(v, false);
      return _SoLoudTrack(track, h, voice, v);
    } on Object catch (e) {
      debugPrint('[sound] track $asset failed: $e');
      return null;
    }
  }

  @override
  set volume(double v) {
    _volume = v;
    if (SoLoud.instance.isInitialized) SoLoud.instance.setGlobalVolume(_curve(v));
  }

  /// Ears hear loudness roughly logarithmically; a power curve makes the
  /// slider feel even from quiet to loud.
  static double _curve(double v) => math.pow(v.clamp(0, 1), 1.8).toDouble();
}

class _SoLoudTrack implements Track {
  _SoLoudTrack(this._track, this._handle, this._voice, this._voiceHandle)
    : length = SoLoud.instance.getLength(_track).inMicroseconds / 1e6;

  final AudioSource _track;
  final SoundHandle _handle;
  final AudioSource? _voice;
  final SoundHandle? _voiceHandle;
  bool _stopped = false;

  @override
  final double length;

  @override
  double get position {
    if (finished) return length;
    return SoLoud.instance.getPosition(_handle).inMicroseconds / 1e6;
  }

  @override
  bool get finished => _stopped || !SoLoud.instance.getIsValidVoiceHandle(_handle);

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    final s = SoLoud.instance;
    try {
      await s.stop(_handle);
      if (_voiceHandle != null) await s.stop(_voiceHandle);
      await s.disposeSource(_track);
      if (_voice != null) await s.disposeSource(_voice);
    } on Object catch (e) {
      debugPrint('[sound] stop failed: $e');
    }
  }
}

/// Records sounds instead of playing them (tests).
class RecordingSoundEngine implements SoundEngine {
  final played = <String>[];
  final tracks = <FakeTrack>[];
  final loaded = <String>{};
  double lastVolume = -1;

  @override
  Future<void> init() async {}

  @override
  Future<void> load(Iterable<String> names) async => loaded.addAll(names);

  @override
  void play(String name, {double gain = 1, double pan = 0}) => played.add(name);

  @override
  Future<Track?> playTrack(String asset, {Uint8List? voiceWav, double voiceGain = 1, double trackGain = 1}) async {
    final t = FakeTrack(asset, voiceWav);
    tracks.add(t);
    return t;
  }

  @override
  set volume(double v) => lastVolume = v;
}

class FakeTrack implements Track {
  FakeTrack(this.asset, this.voiceWav);

  final String asset;
  final Uint8List? voiceWav;

  @override
  double position = 0;

  @override
  double length = 30;

  bool stopped = false;

  @override
  bool get finished => stopped || position >= length;

  @override
  Future<void> stop() async => stopped = true;
}
