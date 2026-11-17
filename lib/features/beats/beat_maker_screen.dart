import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../core/beats.dart';
import '../../core/music.dart';
import '../../widgets/studio.dart';

/// A 6 x 8 step grid that loops. Children start from a ready-made groove (a
/// "template") and switch squares on and off while it plays.
class BeatMakerScreen extends StatefulWidget {
  const BeatMakerScreen({super.key, required this.services});
  final Services services;

  @override
  State<BeatMakerScreen> createState() => _BeatMakerScreenState();
}

class _BeatMakerScreenState extends State<BeatMakerScreen> {
  late final BeatMachine _m = BeatMachine(onStep: _onStep);
  BeatTemplate _template = beatTemplates.first;

  @override
  void initState() {
    super.initState();
    widget.services.sound.load(padSounds);
  }

  @override
  void dispose() {
    _m.dispose();
    super.dispose();
  }

  void _onStep(int step, List<int> lanes) {
    for (final l in lanes) {
      widget.services.sound.play(beatLanes[l].sound, gain: l == 2 || l == 4 ? 0.6 : 0.9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StudioBackground(
        colors: const [Color(0xFF3B1F7A), Color(0xFF1E8FD1)],
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _m,
            builder: (context, _) => Column(
              children: [
                StudioTopBar(
                  title: 'Beat Maker',
                  settings: widget.services.settings,
                  actions: [
                    for (final sp in BeatSpeed.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Opacity(
                          opacity: sp == _m.speed ? 1 : 0.55,
                          child: RoundIcon(
                            key: Key('speed-${sp.name}'),
                            emoji: sp.emoji,
                            color: const Color(0xFFFFFFFF),
                            size: sp == _m.speed ? 56 : 46,
                            label: '${sp.name} speed',
                            onTap: () => _m.setSpeed(sp),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    RoundIcon(
                      key: const Key('play-beat'),
                      emoji: _m.playing ? '⏹️' : '▶️',
                      color: _m.playing ? const Color(0xFFFF5A5F) : const Color(0xFF6BD425),
                      size: 64,
                      label: _m.playing ? 'Stop' : 'Play',
                      onTap: _m.playing ? _m.stop : _m.play,
                    ),
                  ],
                ),
                SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    children: [
                      for (final t in beatTemplates)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Bouncy(
                            key: Key('template-${t.name}'),
                            semanticLabel: '${t.name} beat',
                            onTap: () {
                              setState(() => _template = t);
                              _m.loadTemplate(t);
                              if (!_m.playing && t.name != 'Empty') _m.play();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: candy(
                                t == _template ? const Color(0xFFFF5DA2) : const Color(0xFF7A6BD1),
                                radius: 26,
                              ),
                              child: Text('${t.emoji} ${t.name}', style: kidLabel),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 12), child: _grid()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    return Column(
      children: [
        for (var l = 0; l < beatLanes.length; l++)
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Bouncy(
                    fireOnDown: true,
                    semanticLabel: beatLanes[l].label,
                    onTap: () => widget.services.sound.play(beatLanes[l].sound),
                    child: Center(
                      child: FittedBox(child: Text(beatLanes[l].emoji, style: const TextStyle(fontSize: 34))),
                    ),
                  ),
                ),
                for (var s = 0; s < beatSteps; s++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: s == 4 ? 10 : 4, right: 2, top: 3, bottom: 3),
                      child: _cell(l, s),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(int lane, int step) {
    final on = _m.grid[lane][step];
    final now = _m.step == step;
    final color = beatLanes[lane].color;
    return GestureDetector(
      key: Key('cell-$lane-$step'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _m.toggle(lane, step);
        if (_m.grid[lane][step]) widget.services.sound.play(beatLanes[lane].sound, gain: 0.7);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: on
            ? candy(color, radius: 14, lit: now)
            : BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: now ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
              ),
        transform: Matrix4.diagonal3Values(on && now ? 1.08 : 1, on && now ? 1.08 : 1, 1),
        transformAlignment: Alignment.center,
      ),
    );
  }
}
