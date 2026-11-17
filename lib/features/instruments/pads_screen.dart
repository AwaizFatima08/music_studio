import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../core/music.dart';
import '../../widgets/fx.dart';
import '../../widgets/studio.dart';

/// Eight big pads (drum kit or silly sounds). Several fingers at once.
class PadsScreen extends StatefulWidget {
  const PadsScreen({super.key, required this.services, required this.title, required this.pads});

  final Services services;
  final String title;
  final List<Pad> pads;

  @override
  State<PadsScreen> createState() => _PadsScreenState();
}

class _PadsScreenState extends State<PadsScreen> with TickerProviderStateMixin {
  late final Fx _fx = Fx(this)..level = widget.services.settings.lights;
  final _layer = GlobalKey();
  final _down = <int>{};

  @override
  void initState() {
    super.initState();
    widget.services.sound.load(padSounds);
  }

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  void _hit(int i, Offset global) {
    final pad = widget.pads[i];
    widget.services.sound.play(pad.sound);
    final box = _layer.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) _fx.burst(box.globalToLocal(global), pad.color, glyphs: [pad.emoji, '♪', '✨']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StudioBackground(
        colors: const [Color(0xFF2B2D6E), Color(0xFFE0457B)],
        child: SafeArea(
          child: FxLayer(
            key: _layer,
            fx: _fx,
            child: Column(
              children: [
                StudioTopBar(title: widget.title, settings: widget.services.settings),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth > c.maxHeight ? 4 : 2;
                      final rows = (widget.pads.length / cols).ceil();
                      const gap = 14.0;
                      final w = (c.maxWidth - 24 - gap * (cols - 1)) / cols;
                      final h = (c.maxHeight - 24 - gap * (rows - 1)) / rows;
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (var i = 0; i < widget.pads.length; i++) SizedBox(width: w, height: h, child: _pad(i)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pad(int i) {
    final pad = widget.pads[i];
    final down = _down.contains(i);
    return Semantics(
      button: true,
      label: pad.label,
      child: Listener(
        key: Key('pad-${pad.sound}'),
        onPointerDown: (e) {
          setState(() => _down.add(i));
          _hit(i, e.position);
        },
        onPointerUp: (_) => setState(() => _down.remove(i)),
        onPointerCancel: (_) => setState(() => _down.remove(i)),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: down ? 0.92 : 1,
          child: Container(
            decoration: candy(pad.color, radius: 32, lit: down),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(child: Text(pad.emoji, style: const TextStyle(fontSize: 56))),
                ),
                FittedBox(child: Text(pad.label, style: kidLabel.copyWith(fontSize: 24))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
