import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/settings.dart';

/// Floating music notes, stars and confetti. Every flash is a fade, never a
/// hard strobe, to stay gentle on young eyes. The ticker only runs while
/// something is moving.
class Fx extends ChangeNotifier {
  Fx(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  final _rng = math.Random();
  final particles = <Particle>[];
  LightsLevel level = LightsLevel.party;
  double _now = 0;
  Duration _last = Duration.zero;

  static const _notes = ['♪', '♫', '♩', '♬'];

  /// Notes fly up from [origin] (local coordinates of the [FxLayer]).
  void burst(Offset origin, Color color, {int count = 3, List<String>? glyphs}) {
    if (level == LightsLevel.calm) return;
    final n = level == LightsLevel.gentle ? 1 : count;
    final g = glyphs ?? _notes;
    for (var i = 0; i < n; i++) {
      particles.add(
        Particle(
          glyph: g[_rng.nextInt(g.length)],
          color: color,
          pos: origin + Offset(_rng.nextDouble() * 30 - 15, 0),
          vel: Offset(_rng.nextDouble() * 120 - 60, -140 - _rng.nextDouble() * 120),
          size: 26 + _rng.nextDouble() * 18,
          spin: _rng.nextDouble() * 2 - 1,
          life: 1.3,
          born: _now,
        ),
      );
    }
    _start();
  }

  /// A shower of confetti and stars across [size], for finishing a song.
  void celebrate(Size size) {
    if (level == LightsLevel.calm) return;
    final n = level == LightsLevel.gentle ? 14 : 40;
    const glyphs = ['⭐', '🎉', '✨', '🎈', '♪', '💖'];
    for (var i = 0; i < n; i++) {
      particles.add(
        Particle(
          glyph: glyphs[_rng.nextInt(glyphs.length)],
          color: const Color(0xFFFFFFFF),
          pos: Offset(_rng.nextDouble() * size.width, size.height + 20),
          vel: Offset(_rng.nextDouble() * 160 - 80, -280 - _rng.nextDouble() * 260),
          size: 28 + _rng.nextDouble() * 22,
          spin: _rng.nextDouble() * 2 - 1,
          life: 2.4,
          born: _now + _rng.nextDouble() * 0.6,
        ),
      );
    }
    _start();
  }

  void _start() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    _now += dt;
    for (final p in particles) {
      if (_now < p.born) continue;
      p.vel += Offset(0, 220 * dt);
      p.pos += p.vel * dt;
    }
    particles.removeWhere((p) => _now - p.born > p.life);
    if (particles.isEmpty) _ticker.stop();
    notifyListeners();
  }

  double ageOf(Particle p) => (_now - p.born) / p.life;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class Particle {
  Particle({
    required this.glyph,
    required this.color,
    required this.pos,
    required this.vel,
    required this.size,
    required this.spin,
    required this.life,
    required this.born,
  });

  final String glyph;
  final Color color;
  Offset pos;
  Offset vel;
  final double size;
  final double spin;
  final double life;
  final double born;
}

/// Draws [fx] above its child; ignores touches.
class FxLayer extends StatelessWidget {
  const FxLayer({super.key, required this.fx, required this.child});
  final Fx fx;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      IgnorePointer(child: CustomPaint(painter: _FxPainter(fx))),
    ],
  );
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.fx) : super(repaint: fx);
  final Fx fx;
  final _cache = <String, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in fx.particles) {
      final age = fx.ageOf(p);
      if (age < 0) continue;
      final alpha = (1 - age).clamp(0.0, 1.0);
      final tp = _cache.putIfAbsent(
        '${p.glyph}${p.color.toARGB32()}${p.size.round()}',
        () => TextPainter(
          text: TextSpan(
            text: p.glyph,
            style: TextStyle(
              fontSize: p.size.roundToDouble(),
              color: p.color,
              fontWeight: FontWeight.w700,
              shadows: const [Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.spin * age * 1.5);
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, alpha));
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => false;
}
