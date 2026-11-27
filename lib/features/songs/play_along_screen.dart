import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/art.dart';
import '../../app/services.dart';
import '../../core/music.dart';
import '../../core/songs.dart';
import '../../widgets/fx.dart';
import '../../widgets/keyboard.dart';
import '../../widgets/studio.dart';
import 'song_picker.dart';

/// The next key of the song shines; any key plays the song's next note, so a
/// small child always "gets it right" and hears the tune grow. "Play for me"
/// plays the whole song with the keys lighting up.
class PlayAlongScreen extends StatefulWidget {
  const PlayAlongScreen({super.key, required this.services, required this.song});
  final Services services;
  final Song song;

  @override
  State<PlayAlongScreen> createState() => _PlayAlongScreenState();
}

class _PlayAlongScreenState extends State<PlayAlongScreen> with TickerProviderStateMixin {
  late final Fx _fx = Fx(this)..level = widget.services.settings.lights;
  final _layer = GlobalKey();
  Instrument _instrument = Instrument.piano;
  KeyStyle _style = KeyStyle.piano;
  int _next = 0;
  Timer? _auto;

  Song get song => widget.song;

  @override
  void initState() {
    super.initState();
    widget.services.sound.load([..._instrument.allSounds, 'fanfare']);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _fx.dispose();
    super.dispose();
  }

  void _playNext({Offset? at}) {
    final note = song.notes[_next];
    final k = keyForNote(note.midi);
    widget.services.sound.play(_instrument.sound(note.midi));
    final box = _layer.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && at != null) _fx.burst(box.globalToLocal(at) - const Offset(0, 40), keyColors[k]);
    setState(() => _next++);
    if (_next >= song.notes.length) _finish();
  }

  void _finish() {
    _auto?.cancel();
    _auto = null;
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      widget.services.sound.play('fanfare');
      final box = _layer.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) _fx.celebrate(box.size);
      setState(() => _next = 0);
    });
  }

  void _toggleAuto() {
    if (_auto != null) {
      _auto!.cancel();
      setState(() => _auto = null);
      return;
    }
    if (_next >= song.notes.length) _next = 0;
    void step() {
      if (!mounted || _next >= song.notes.length) return;
      final ticks = song.notes[_next].ticks;
      _playNext();
      if (_auto == null) return;
      _auto = Timer(Duration(microseconds: (ticks * song.secondsPerTick * 1e6).round()), step);
    }

    setState(() => _auto = Timer(Duration.zero, step));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services.settings;
    final done = _next >= song.notes.length;
    final current = done ? -1 : _next;
    final line = done ? song.lineCount - 1 : song.notes[_next].line;
    return Scaffold(
      body: StudioBackground(
        colors: [song.color, const Color(0xFF3B1F7A)],
        child: SafeArea(
          child: FxLayer(
            key: _layer,
            fx: _fx,
            child: Column(
              children: [
                StudioTopBar(
                  title: '${song.emoji} ${song.title}',
                  settings: s,
                  actions: [
                    for (final (i, st) in const [
                      (Instrument.piano, KeyStyle.piano),
                      (Instrument.xylophone, KeyStyle.bars),
                      (Instrument.flute, KeyStyle.bubbles),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Opacity(
                          opacity: i == _instrument ? 1 : 0.55,
                          child: RoundIcon(
                            emoji: i.emoji,
                            art: Art.room(i.name),
                            color: i.color,
                            size: i == _instrument ? 54 : 44,
                            label: i.title,
                            onTap: () {
                              widget.services.sound.load(i.allSounds);
                              setState(() {
                                _instrument = i;
                                _style = st;
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    RoundIcon(
                      key: const Key('play-for-me'),
                      emoji: _auto == null ? '▶️' : '⏸️',
                      color: const Color(0xFF6BD425),
                      size: 60,
                      label: _auto == null ? 'Play for me' : 'Pause',
                      onTap: _toggleAuto,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: LyricLine(song: song, line: line, current: current, size: 30),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Keyboard(
                      style: _style,
                      labels: labelsFor(s.labels),
                      highlight: done ? null : keyForNote(song.notes[_next].midi),
                      onKey: (k, at) {
                        if (_auto != null || done) return;
                        _playNext(at: at);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
