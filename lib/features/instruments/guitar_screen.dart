import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../core/music.dart';
import '../../widgets/fx.dart';
import '../../widgets/studio.dart';

/// Six strings and four chord buttons. Swipe across the strings to strum,
/// tap one to pluck it, or press the big strum button.
class GuitarScreen extends StatefulWidget {
  const GuitarScreen({super.key, required this.services});
  final Services services;

  @override
  State<GuitarScreen> createState() => _GuitarScreenState();
}

class _GuitarScreenState extends State<GuitarScreen> with TickerProviderStateMixin {
  late final Fx _fx = Fx(this)..level = widget.services.settings.lights;
  late final _wobble = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  final _layer = GlobalKey();
  final _strings = GlobalKey();
  final _pointerString = <int, int>{};
  final _plucked = List<double>.filled(6, -10); // time each string was last plucked
  final _clock = Stopwatch()..start();
  Chord _chord = guitarChords.first;

  @override
  void initState() {
    super.initState();
    widget.services.sound.load(Instrument.guitar.allSounds);
  }

  @override
  void dispose() {
    _fx.dispose();
    _wobble.dispose();
    super.dispose();
  }

  double get _now => _clock.elapsedMicroseconds / 1e6;

  void _pluck(int string, Offset global) {
    widget.services.sound.play(Instrument.guitar.sound(_chord.strings[string]), gain: 0.85);
    _plucked[string] = _now;
    final box = _layer.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && string % 2 == 0) _fx.burst(box.globalToLocal(global), _chord.color, count: 1);
  }

  void _strumAll() {
    final box = _strings.currentContext?.findRenderObject() as RenderBox?;
    for (var i = 0; i < 6; i++) {
      Timer(Duration(milliseconds: 28 * i), () {
        if (!mounted) return;
        final y = box == null ? 0.0 : (i + 0.5) / 6 * box.size.height;
        _pluck(i, box?.localToGlobal(Offset(box.size.width * 0.5, y)) ?? Offset.zero);
      });
    }
  }

  void _track(int pointer, Offset global) {
    final box = _strings.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final y = box.globalToLocal(global).dy;
    final s = (y / box.size.height * 6).floor();
    if (s < 0 || s > 5 || s == _pointerString[pointer]) return;
    final from = _pointerString[pointer];
    _pointerString[pointer] = s;
    // A fast swipe can jump over strings between two move events; play those too.
    if (from != null) {
      final step = s > from ? 1 : -1;
      for (var k = from + step; k != s; k += step) {
        _pluck(k, global);
      }
    }
    _pluck(s, global);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StudioBackground(
        colors: const [Color(0xFFFF8A3D), Color(0xFF8E3B7A)],
        child: SafeArea(
          child: FxLayer(
            key: _layer,
            fx: _fx,
            child: Column(
              children: [
                StudioTopBar(title: 'Guitar', settings: widget.services.settings),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 130,
                          child: Column(
                            children: [
                              for (final c in guitarChords)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    child: Bouncy(
                                      key: Key('chord-${c.name}'),
                                      fireOnDown: true,
                                      semanticLabel: 'Chord ${c.name}',
                                      onTap: () {
                                        setState(() => _chord = c);
                                        _strumAll();
                                      },
                                      child: Container(
                                        decoration: candy(c.color, lit: c == _chord),
                                        alignment: Alignment.center,
                                        child: Text(c.name, style: kidLabel.copyWith(fontSize: 34)),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: _neck()),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 110,
                          child: Center(
                            child: RoundIcon(
                              key: const Key('strum'),
                              emoji: '🎸',
                              color: _chord.color,
                              size: 100,
                              label: 'Strum',
                              onTap: _strumAll,
                            ),
                          ),
                        ),
                      ],
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

  Widget _neck() {
    return Listener(
      key: _strings,
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _track(e.pointer, e.position),
      onPointerMove: (e) => _track(e.pointer, e.position),
      onPointerUp: (e) => _pointerString.remove(e.pointer),
      onPointerCancel: (e) => _pointerString.remove(e.pointer),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [Color(0xFF8B5A2B), Color(0xFFC68642), Color(0xFF8B5A2B)]),
          border: Border.all(color: Colors.white70, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 6), blurRadius: 8)],
        ),
        child: AnimatedBuilder(
          animation: _wobble,
          builder: (_, _) => CustomPaint(painter: _StringsPainter(_plucked, _now, _chord.color), size: Size.infinite),
        ),
      ),
    );
  }
}

class _StringsPainter extends CustomPainter {
  _StringsPainter(this.plucked, this.now, this.glow);

  final List<double> plucked;
  final double now;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    // Frets and a sound hole for the toy look.
    final fret = Paint()
      ..color = const Color(0x88FFE9C7)
      ..strokeWidth = 4;
    for (final f in [0.18, 0.36, 0.52]) {
      canvas.drawLine(Offset(size.width * f, 8), Offset(size.width * f, size.height - 8), fret);
    }
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height / 2),
      size.height * 0.28,
      Paint()..color = const Color(0xFF3E2410),
    );
    for (var i = 0; i < 6; i++) {
      final y = (i + 0.5) / 6 * size.height;
      final age = now - plucked[i];
      final amp = age < 1.2 ? 9 * math.exp(-age * 4) * (1 - i * 0.08) : 0.0;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 8) {
        final env = math.sin(math.pi * x / size.width);
        path.lineTo(x, y + amp * env * math.sin(now * 90 + x / 30));
      }
      final width = 6.0 - i * 0.7;
      if (amp > 0.5) {
        canvas.drawPath(
          path,
          Paint()
            ..color = glow.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width + 8
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(const Color(0xFFE8E8E8), const Color(0xFFFFD27A), i / 5)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }
  }

  @override
  bool shouldRepaint(_StringsPainter old) => true;
}
