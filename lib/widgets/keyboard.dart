import 'package:flutter/material.dart';

import '../core/music.dart';
import '../core/settings.dart';
import 'studio.dart';

enum KeyStyle { piano, bars, bubbles }

List<String> labelsFor(KeyLabels l) => switch (l) {
  KeyLabels.animals => keyAnimals,
  KeyLabels.letters => keyLetters,
  KeyLabels.solfa => keySolfa,
  KeyLabels.colours => List.filled(8, ''),
};

/// The eight rainbow keys. Many fingers at once, and sliding a finger across
/// the keys plays each one it reaches (a glissando).
class Keyboard extends StatefulWidget {
  const Keyboard({super.key, required this.style, required this.labels, required this.onKey, this.highlight});

  final KeyStyle style;
  final List<String> labels;

  /// Called on finger down (or slide onto a key) with the key and where it is
  /// in global coordinates, for particles.
  final void Function(int key, Offset globalCenter) onKey;

  /// A key that softly pulses (the next note of a play-along song).
  final int? highlight;

  @override
  State<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<Keyboard> with SingleTickerProviderStateMixin {
  final _pointerKey = <int, int>{};
  final _keys = List.generate(8, (_) => GlobalKey());
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  int? _hit(Offset global) {
    for (var i = 0; i < 8; i++) {
      final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final local = box.globalToLocal(global);
      if (box.paintBounds.contains(local)) return i;
    }
    return null;
  }

  void _move(int pointer, Offset global) {
    final k = _hit(global);
    if (k == _pointerKey[pointer]) return;
    setState(() {
      if (k == null) {
        _pointerKey.remove(pointer);
      } else {
        _pointerKey[pointer] = k;
      }
    });
    if (k != null) {
      final box = _keys[k].currentContext!.findRenderObject() as RenderBox;
      widget.onKey(k, box.localToGlobal(box.size.center(Offset.zero)));
    }
  }

  void _up(int pointer) => setState(() => _pointerKey.remove(pointer));

  @override
  Widget build(BuildContext context) {
    final down = _pointerKey.values.toSet();
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _move(e.pointer, e.position),
      onPointerMove: (e) => _move(e.pointer, e.position),
      onPointerUp: (e) => _up(e.pointer),
      onPointerCancel: (e) => _up(e.pointer),
      child: LayoutBuilder(
        builder: (context, c) {
          final gap = c.maxWidth < 500 ? 4.0 : 8.0;
          return Row(
            crossAxisAlignment: widget.style == KeyStyle.bars ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 8; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gap / 2),
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) => _Key(
                        key: _keys[i],
                        index: i,
                        style: widget.style,
                        label: widget.labels[i],
                        pressed: down.contains(i),
                        glow: widget.highlight == i ? 0.45 + 0.55 * _pulse.value : 0,
                        height: c.maxHeight,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.index,
    required this.style,
    required this.label,
    required this.pressed,
    required this.glow,
    required this.height,
  });

  final int index;
  final KeyStyle style;
  final String label;
  final bool pressed;
  final double glow;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = keyColors[index];
    final lit = pressed || glow > 0;
    final text = Text(label, style: kidLabel.copyWith(fontSize: 30));
    final star = glow > 0
        ? Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: glow,
              child: const Text('⭐', textAlign: TextAlign.center, style: TextStyle(fontSize: 30)),
            ),
          )
        : null;
    final deco = candy(color, radius: style == KeyStyle.bubbles ? 200 : 24, lit: lit).copyWith(
      border: Border.all(
        color: glow > 0 ? Colors.white : Colors.white.withValues(alpha: 0.7),
        width: glow > 0 ? 3 + 4 * glow : 3,
      ),
    );
    switch (style) {
      case KeyStyle.piano:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, pressed ? 6 : 0, 0),
          decoration: deco,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 18),
          child: Stack(alignment: Alignment.bottomCenter, children: [text, ?star]),
        );
      case KeyStyle.bars:
        // Xylophone: bars get shorter as the notes get higher.
        return AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: height * (0.98 - index * 0.06),
          transform: Matrix4.translationValues(0, pressed ? 5 : 0, 0),
          decoration: deco,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final dy in [-0.78, 0.78])
                Align(
                  alignment: Alignment(0, dy),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(color: Color(0xCCFFFFFF), shape: BoxShape.circle),
                  ),
                ),
              text,
              ?star,
            ],
          ),
        );
      case KeyStyle.bubbles:
        return Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 90),
              scale: pressed ? 0.9 : 1,
              child: Container(
                decoration: deco,
                alignment: Alignment.center,
                child: Stack(alignment: Alignment.center, children: [text, ?star]),
              ),
            ),
          ),
        );
    }
  }
}
