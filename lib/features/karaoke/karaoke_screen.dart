import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/art.dart';
import '../../app/services.dart';
import '../../audio/mic.dart';
import '../../audio/voice_fx.dart';
import '../../audio/wav.dart';
import '../../core/songs.dart';
import '../../core/sound_engine.dart';
import '../../widgets/fx.dart';
import '../../widgets/studio.dart';
import '../songs/song_picker.dart';

/// Rough input latency of a phone microphone; the recording is shifted by it
/// so the voice lands on the beat when played back with the music.
const kMicLatencySeconds = 0.1;

typedef VoiceRenderer = Future<Uint8List> Function(Pcm recording, KaraokeVoice voice, double leadSeconds);

enum KaraokePhase { ready, singing, choosing, rendering, listening }

/// Sing along with a backing track and bouncing lyrics. When the microphone
/// is allowed (grown-ups setting + Android permission) the child's voice is
/// recorded into memory and can be played back over the music with a silly
/// voice. Nothing is saved: leaving the screen throws the recording away.
class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({
    super.key,
    required this.services,
    required this.song,
    this.render = renderKaraokeVoiceInBackground,
  });

  final Services services;
  final Song song;
  final VoiceRenderer render;

  @override
  State<KaraokeScreen> createState() => KaraokeScreenState();
}

class KaraokeScreenState extends State<KaraokeScreen> with TickerProviderStateMixin {
  late final Fx _fx = Fx(this)..level = widget.services.settings.lights;
  late final Ticker _ticker = createTicker((_) => _poll());
  final _layer = GlobalKey();
  final _clock = Stopwatch()..start();

  KaraokePhase phase = KaraokePhase.ready;
  Track? _track;
  Mic? _mic;
  StreamSubscription<double>? _levelSub;
  double _level = 0;
  Pcm? _recording;
  double _lead = 0;
  final _rendered = <KaraokeVoice, Uint8List>{};
  KaraokeVoice? _voice;
  double _pos = 0;
  bool _micRefused = false;

  Song get song => widget.song;

  @override
  void initState() {
    super.initState();
    widget.services.sound.load(['applause', 'cheer']);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _track?.stop();
    _levelSub?.cancel();
    _mic?.dispose();
    _recording = null;
    _fx.dispose();
    super.dispose();
  }

  Future<void> sing() async {
    await _stopTrack();
    _recording = null;
    _rendered.clear();
    _voice = null;
    double? micStarted;
    if (widget.services.settings.karaokeMic) {
      final mic = _mic ??= widget.services.mic();
      if (await mic.requestPermission()) {
        try {
          await mic.start();
          micStarted = _clock.elapsedMicroseconds / 1e6;
          _levelSub = mic.levels.listen((v) => _level = v);
        } on Object catch (e) {
          debugPrint('[karaoke] mic start failed: $e');
        }
      } else {
        _micRefused = true;
      }
    }
    if (!mounted) return;
    final track = await widget.services.sound.playTrack(song.backingAsset, trackGain: 0.85);
    if (micStarted != null) _lead = _clock.elapsedMicroseconds / 1e6 - micStarted + kMicLatencySeconds;
    if (!mounted) {
      await track?.stop();
      return;
    }
    setState(() {
      _track = track;
      _pos = 0;
      phase = KaraokePhase.singing;
    });
    if (!_ticker.isActive) _ticker.start();
  }

  void _poll() {
    final t = _track;
    if (t == null) return;
    setState(() => _pos = t.position);
    if (t.finished || _pos >= song.singingEnds + 1.2) unawaited(_trackDone());
  }

  Future<void> _trackDone() async {
    _ticker.stop();
    await _stopTrack();
    if (phase == KaraokePhase.singing) {
      unawaited(_levelSub?.cancel());
      _levelSub = null;
      _level = 0;
      _recording = await _mic?.stop();
      widget.services.sound.play('applause');
      final box = _layer.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) _fx.celebrate(box.size);
    }
    if (!mounted) return;
    setState(() => phase = _recording != null ? KaraokePhase.choosing : KaraokePhase.ready);
  }

  Future<void> _stopTrack() async {
    final t = _track;
    _track = null;
    await t?.stop();
  }

  Future<void> listen(KaraokeVoice v) async {
    final rec = _recording;
    if (rec == null) return;
    await _stopTrack();
    setState(() {
      _voice = v;
      phase = KaraokePhase.rendering;
    });
    final wav = _rendered[v] ??= await widget.render(rec, v, _lead);
    if (!mounted || _voice != v) return;
    final track = await widget.services.sound.playTrack(song.backingAsset, voiceWav: wav, trackGain: 0.5, voiceGain: 1);
    if (!mounted) {
      await track?.stop();
      return;
    }
    setState(() {
      _track = track;
      _pos = 0;
      phase = KaraokePhase.listening;
    });
    if (!_ticker.isActive) _ticker.start();
  }

  Future<void> stop() async {
    if (phase == KaraokePhase.singing) {
      await _trackDone();
      return;
    }
    _ticker.stop();
    await _stopTrack();
    if (mounted) setState(() => phase = _recording != null ? KaraokePhase.choosing : KaraokePhase.ready);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StudioBackground(
        colors: const [Color(0xFF2A0E4F), Color(0xFFB0307A)],
        image: Art.stageBackground,
        child: SafeArea(
          child: FxLayer(
            key: _layer,
            fx: _fx,
            child: Column(
              children: [
                StudioTopBar(title: '🎤 ${song.title}', settings: widget.services.settings),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (phase) {
      case KaraokePhase.ready:
        return _centre([
          Text(song.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          _bigButton(const Key('sing'), '🎤  Sing!', const Color(0xFFFF5DA2), sing),
          if (_micRefused || !widget.services.settings.karaokeMic)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Sing along! (No recording)', style: kidLabel.copyWith(fontSize: 16)),
            ),
        ]);
      case KaraokePhase.singing:
      case KaraokePhase.listening:
        return _stage();
      case KaraokePhase.choosing:
      case KaraokePhase.rendering:
        return _centre([
          Text('Listen to you!', style: kidLabel.copyWith(fontSize: 30)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              for (final v in KaraokeVoice.values)
                Bouncy(
                  key: Key('voice-${v.name}'),
                  semanticLabel: v.title,
                  onTap: phase == KaraokePhase.rendering ? null : () => listen(v),
                  child: Container(
                    width: 130,
                    height: 120,
                    decoration: candy(Color(v.color), lit: v == _voice),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (phase == KaraokePhase.rendering && v == _voice)
                          const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 5),
                          )
                        else
                          Text(v.emoji, style: const TextStyle(fontSize: 44)),
                        const SizedBox(height: 6),
                        FittedBox(child: Text(v.title, style: kidLabel.copyWith(fontSize: 18))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _bigButton(const Key('sing-again'), '🔁  Sing again', const Color(0xFF2EC4B6), sing, small: true),
        ]);
    }
  }

  Widget _stage() {
    final idx = song.noteIndexAt(_pos);
    final beat = 60 / song.bpm;
    final countdown = _pos < song.countInSeconds ? countInBeats - (_pos / beat).floor() : 0;
    final line = idx < 0 ? 0 : song.notes[idx].line;
    final singing = phase == KaraokePhase.singing;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (countdown > 0)
                    Text(
                      '$countdown',
                      key: const Key('countdown'),
                      style: kidLabel.copyWith(fontSize: 72, color: const Color(0xFFFFE45C)),
                    )
                  else
                    _BouncingBall(song: song, index: idx, position: _pos),
                  LyricLine(song: song, line: line, current: idx, size: 38),
                  const SizedBox(height: 8),
                  LyricLine(song: song, line: line + 1, current: -1, size: 26, dim: true),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (singing && _mic != null && _levelSub != null)
                AnimatedScale(
                  duration: const Duration(milliseconds: 80),
                  scale: 1 + _level * 0.5,
                  child: const Text('🎤', style: TextStyle(fontSize: 48)),
                ),
              if (!singing && _voice != null) Text(_voice!.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 20),
              RoundIcon(
                key: const Key('stop'),
                emoji: '⏹️',
                color: const Color(0xFFFF5A5F),
                size: 64,
                label: 'Stop',
                onTap: stop,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _centre(List<Widget> children) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );

  Widget _bigButton(Key key, String label, Color color, VoidCallback onTap, {bool small = false}) => Bouncy(
    key: key,
    semanticLabel: label,
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 26 : 44, vertical: small ? 12 : 20),
      decoration: candy(color, radius: 40),
      child: Text(label, style: kidLabel.copyWith(fontSize: small ? 24 : 36)),
    ),
  );
}

/// A ball that hops from syllable to syllable, landing on each one's start.
class _BouncingBall extends StatelessWidget {
  const _BouncingBall({required this.song, required this.index, required this.position});

  final Song song;
  final int index;
  final double position;

  @override
  Widget build(BuildContext context) {
    double hop = 0;
    if (index >= 0) {
      final n = song.notes[index];
      final start = song.startOf(n);
      final len = (song.endOf(n) - start).clamp(0.15, 2.0);
      final p = ((position - start) / len).clamp(0.0, 1.0);
      hop = 4 * p * (1 - p); // a parabola: up and back down per syllable
    }
    return SizedBox(
      height: 72,
      child: Align(
        alignment: Alignment(0, 1 - hop * 2),
        child: const Text('🟡', style: TextStyle(fontSize: 30)),
      ),
    );
  }
}
