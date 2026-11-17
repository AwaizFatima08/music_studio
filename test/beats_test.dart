import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_tunes/core/beats.dart';

void main() {
  test('templates fill every lane and step', () {
    for (final t in beatTemplates) {
      expect(t.rows, hasLength(beatLanes.length), reason: t.name);
      for (final r in t.rows) {
        expect(r, hasLength(beatSteps), reason: t.name);
      }
    }
  });

  test('the machine loops over the steps and reports the lanes to sound', () {
    final hits = <(int, List<int>)>[];
    void Function(Timer)? tick;
    final m = BeatMachine(
      onStep: (s, l) => hits.add((s, l)),
      periodic: (d, f) {
        tick = f;
        return Timer(const Duration(days: 1), () {});
      },
    );
    m.loadTemplate(beatTemplates.first); // Stomp
    m.play();
    for (var i = 0; i < 8; i++) {
      tick!(Timer(Duration.zero, () {}));
    }
    expect(hits.first.$1, 0);
    expect(hits.first.$2, [0, 2]); // boom + tss on the first step
    expect(hits.last.$1, 0); // wrapped round after 8 steps
    m.toggle(3, 1);
    expect(m.grid[3][1], isTrue);
    m.stop();
    expect(m.playing, isFalse);
    m.dispose();
  });

  test('loading a template does not change the template itself', () {
    final m = BeatMachine(onStep: (_, _) {});
    m.loadTemplate(beatTemplates.last);
    m.toggle(0, 0);
    expect(beatTemplates.last.grid[0][0], isFalse);
    m.dispose();
  });
}
