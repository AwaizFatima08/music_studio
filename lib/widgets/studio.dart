import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/services.dart';

/// A soft two-colour gradient with music notes drifting slowly upwards, behind
/// every screen. If [image] is given (approved homidev art) it is shown under
/// a light tint instead of the plain gradient.
class StudioBackground extends StatefulWidget {
  const StudioBackground({super.key, required this.colors, this.image, required this.child});

  final List<Color> colors;
  final String? image;
  final Widget child;

  @override
  State<StudioBackground> createState() => _StudioBackgroundState();
}

class _StudioBackgroundState extends State<StudioBackground> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.colors),
        image: widget.image == null
            ? null
            : DecorationImage(
                image: AssetImage(widget.image!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(widget.colors.first.withValues(alpha: 0.25), BlendMode.srcATop),
              ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!reduceMotion) IgnorePointer(child: CustomPaint(painter: _DriftPainter(_anim))),
          widget.child,
        ],
      ),
    );
  }
}

class _DriftPainter extends CustomPainter {
  _DriftPainter(this.t) : super(repaint: t);
  final Animation<double> t;
  static final _glyphs = [
    for (final g in ['♪', '♫', '♩', '♬', '✦'])
      TextPainter(
        text: TextSpan(
          text: g,
          style: const TextStyle(fontSize: 34, color: Color(0x33FFFFFF)),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const n = 14;
    for (var i = 0; i < n; i++) {
      final seed = i * 0.6180339;
      final x = (seed % 1) * size.width + math.sin((t.value * 2 + seed) * math.pi * 2) * 20;
      final y = size.height - ((t.value * (0.6 + (i % 4) * 0.15) + seed) % 1) * (size.height + 60) + 30;
      _glyphs[i % _glyphs.length].paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_DriftPainter old) => false;
}

/// A big round button that squashes when pressed. Fires on finger down, since
/// small children often slide off before lifting.
class Bouncy extends StatefulWidget {
  const Bouncy({super.key, required this.onTap, required this.child, this.semanticLabel, this.fireOnDown = false});

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final bool fireOnDown;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 260),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _c.forward();
          if (widget.fireOnDown) widget.onTap?.call();
        },
        onTapUp: (_) {
          _c.reverse();
          if (!widget.fireOnDown) widget.onTap?.call();
        },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.scale(scale: 1 - 0.08 * Curves.easeOut.transform(_c.value), child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A glossy candy-coloured circle with an emoji, for the top bars.
class RoundIcon extends StatelessWidget {
  const RoundIcon({super.key, required this.emoji, required this.color, this.size = 56, this.onTap, this.label});

  final String emoji;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: onTap,
    semanticLabel: label,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: candy(color, radius: size / 2),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    ),
  );
}

/// The glossy "toy" look shared by cards, pads and buttons.
BoxDecoration candy(Color c, {double radius = 28, bool lit = false}) {
  final hsl = HSLColor.fromColor(c);
  final light = hsl.withLightness((hsl.lightness + 0.16).clamp(0, 1)).toColor();
  final dark = hsl.withLightness((hsl.lightness - 0.18).clamp(0, 1)).toColor();
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [light, c]),
    border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
    boxShadow: [
      BoxShadow(color: dark, offset: const Offset(0, 6)),
      if (lit) BoxShadow(color: c.withValues(alpha: 0.8), blurRadius: 28, spreadRadius: 4),
    ],
  );
}

/// Back button, title and the mute toggle, at the top of every play screen.
class StudioTopBar extends StatelessWidget {
  const StudioTopBar({super.key, required this.title, required this.settings, this.actions = const []});

  final String title;
  final Settings settings;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          RoundIcon(
            key: const Key('back'),
            emoji: '🏠',
            color: const Color(0xFFFFFFFF),
            label: 'Back to the studio',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
          ),
          ...actions,
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: settings,
            builder: (_, _) => RoundIcon(
              key: const Key('mute'),
              emoji: settings.muted ? '🔇' : '🔊',
              color: const Color(0xFFFFFFFF),
              label: settings.muted ? 'Sound on' : 'Sound off',
              onTap: () => settings.update((s) => s.muted = !s.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Text style for big friendly labels on coloured buttons.
const kidLabel = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  shadows: [Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
);
