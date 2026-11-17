import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'music.dart';

/// The beat maker's rows, top to bottom.
const beatLanes = [
  Pad('drum_kick', 'Boom', '🥁', Color(0xFFFF5A5F)),
  Pad('drum_snare', 'Snap', '🪘', Color(0xFFFF9F1C)),
  Pad('drum_hat', 'Tss', '✨', Color(0xFFFFD23F)),
  Pad('drum_clap', 'Clap', '👏', Color(0xFF6BD425)),
  Pad('drum_shaker', 'Shake', '🎉', Color(0xFF2EC4B6)),
  Pad('drum_bell', 'Ding', '🔔', Color(0xFF8E62FF)),
];

const beatSteps = 8;

/// Ready-made grooves ("play templates") a child can start from and change.
class BeatTemplate {
  const BeatTemplate(this.name, this.emoji, this.rows);

  final String name;
  final String emoji;

  /// One string per lane, 'x' = hit.
  final List<String> rows;

  List<List<bool>> get grid => [
    for (final r in rows) [for (var i = 0; i < beatSteps; i++) r[i] == 'x'],
  ];
}

const beatTemplates = [
  BeatTemplate('Stomp', '🦖', ['x...x.x.', '..x...x.', 'x.x.x.x.', '........', '........', '........']),
  BeatTemplate('Dance', '🪩', ['x.x.x.x.', '..x...x.', '.x.x.x.x', '..x...x.', 'xxxxxxxx', '........']),
  BeatTemplate('Parade', '🎺', ['x...x...', 'x.xxx.xx', '........', '........', '........', 'x.......']),
  BeatTemplate('Bounce', '🐸', ['x..x..x.', '..x...x.', 'xxxxxxxx', '......x.', '........', '.....x..']),
  BeatTemplate('Rain', '🌧️', ['x.......', '........', '..x...x.', '........', 'x.x.x.x.', 'x...x...']),
  BeatTemplate('Empty', '⬜', ['........', '........', '........', '........', '........', '........']),
];

enum BeatSpeed {
  slow('🐢', 84),
  medium('🐰', 104),
  fast('🐆', 128);

  const BeatSpeed(this.emoji, this.bpm);
  final String emoji;
  final int bpm;

  /// One step is an eighth note.
  Duration get step => Duration(microseconds: 60000000 ~/ (bpm * 2));
}

/// The grid plus the play head. [onStep] fires with the lanes to sound.
class BeatMachine extends ChangeNotifier {
  BeatMachine({required this.onStep, Timer Function(Duration, void Function(Timer))? periodic})
    : _periodic = periodic ?? Timer.periodic;

  final void Function(int step, List<int> lanes) onStep;
  final Timer Function(Duration, void Function(Timer)) _periodic;

  List<List<bool>> grid = beatTemplates.first.grid;
  BeatSpeed speed = BeatSpeed.medium;
  int step = -1;
  Timer? _timer;

  bool get playing => _timer != null;

  void loadTemplate(BeatTemplate t) {
    grid = t.grid;
    notifyListeners();
  }

  void toggle(int lane, int s) {
    grid[lane][s] = !grid[lane][s];
    notifyListeners();
  }

  void setSpeed(BeatSpeed s) {
    speed = s;
    if (playing) {
      _timer!.cancel();
      _timer = _periodic(speed.step, (_) => _advance());
    }
    notifyListeners();
  }

  void play() {
    if (playing) return;
    step = -1;
    _advance();
    _timer = _periodic(speed.step, (_) => _advance());
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    step = -1;
    notifyListeners();
  }

  void _advance() {
    step = (step + 1) % beatSteps;
    onStep(step, [
      for (var l = 0; l < grid.length; l++)
        if (grid[l][step]) l,
    ]);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
