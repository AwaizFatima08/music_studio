import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../core/music.dart';
import '../../widgets/fx.dart';
import '../../widgets/keyboard.dart';
import '../../widgets/studio.dart';

/// Piano, xylophone or magic flute: eight rainbow keys, free play. The
/// instrument buttons at the top swap the sound without leaving the screen.
class KeysScreen extends StatefulWidget {
  const KeysScreen({super.key, required this.services, required this.instrument, required this.style});

  final Services services;
  final Instrument instrument;
  final KeyStyle style;

  @override
  State<KeysScreen> createState() => _KeysScreenState();
}

class _KeysScreenState extends State<KeysScreen> with TickerProviderStateMixin {
  late final Fx _fx = Fx(this)..level = widget.services.settings.lights;
  late Instrument _instrument = widget.instrument;
  late KeyStyle _style = widget.style;
  final _layer = GlobalKey();

  static const _choices = [
    (Instrument.piano, KeyStyle.piano),
    (Instrument.xylophone, KeyStyle.bars),
    (Instrument.flute, KeyStyle.bubbles),
  ];

  @override
  void initState() {
    super.initState();
    widget.services.sound.load(_instrument.allSounds);
  }

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  void _key(int k, Offset global) {
    widget.services.sound.play(_instrument.sound(keyNotes[k]), pan: (k - 3.5) / 8);
    final box = _layer.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) _fx.burst(box.globalToLocal(global) - const Offset(0, 40), keyColors[k]);
  }

  void _switch(Instrument i, KeyStyle s) {
    widget.services.sound.load(i.allSounds);
    setState(() {
      _instrument = i;
      _style = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services.settings;
    return Scaffold(
      body: StudioBackground(
        colors: [_instrument.color, const Color(0xFF5B3CC4)],
        child: SafeArea(
          child: FxLayer(
            key: _layer,
            fx: _fx,
            child: Column(
              children: [
                StudioTopBar(
                  title: _instrument.title,
                  settings: s,
                  actions: [
                    for (final (i, st) in _choices)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Opacity(
                          opacity: i == _instrument ? 1 : 0.6,
                          child: RoundIcon(
                            key: Key('inst-${i.name}'),
                            emoji: i.emoji,
                            color: i.color,
                            size: i == _instrument ? 60 : 50,
                            label: i.title,
                            onTap: () => _switch(i, st),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Keyboard(style: _style, labels: labelsFor(s.labels), onKey: _key),
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
