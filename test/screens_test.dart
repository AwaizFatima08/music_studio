import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_tunes/core/sound_engine.dart';
import 'package:tiny_tunes/features/home/home_screen.dart';
import 'package:tiny_tunes/features/karaoke/karaoke_screen.dart';
import 'package:tiny_tunes/features/songs/play_along_screen.dart';

import 'helpers.dart';

Future<void> landscape(WidgetTester t) async {
  t.view.physicalSize = const Size(1600, 720);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// The studio background animates forever, so pumpAndSettle never returns.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Widget app(Widget home) => MaterialApp(home: home);

void main() {
  testWidgets('home shows every studio room and opens the piano', (t) async {
    await landscape(t);
    final s = makeServices();
    await t.pumpWidget(app(HomeScreen(services: s.services)));
    for (final r in rooms) {
      expect(find.byKey(Key('room-${r.id}')), findsOneWidget);
    }
    await t.tap(find.byKey(const Key('room-piano')));
    await settle(t);
    expect(find.text('Piano'), findsWidgets);
    expect(s.sound.loaded, contains('piano_60'));
    await t.tap(find.text('🐱')); // first key, animal labels
    await t.pump(const Duration(milliseconds: 100));
    expect(s.sound.played.last, 'piano_60');
  });

  testWidgets('home works in portrait too (tablets may ignore landscape)', (t) async {
    t.view.physicalSize = const Size(720, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(HomeScreen(services: makeServices().services)));
    expect(t.takeException(), isNull);
  });

  testWidgets('every room opens without errors', (t) async {
    await landscape(t);
    for (final r in rooms) {
      final s = makeServices();
      await t.pumpWidget(app(r.open(s.services)));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: r.id);
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets('grown-ups gear needs a hold and then the sum', (t) async {
    await landscape(t);
    await t.pumpWidget(app(HomeScreen(services: makeServices().services)));
    await t.tap(find.byKey(const Key('grownups-gear')));
    await settle(t);
    expect(find.byKey(const Key('parent-gate')), findsNothing);
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('grownups-gear'))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1100));
    await g.up();
    await settle(t);
    expect(find.byKey(const Key('parent-gate')), findsOneWidget);
  });

  testWidgets('play-along: any key plays the next note of the song', (t) async {
    await landscape(t);
    final s = makeServices();
    final song = testSongs.firstWhere((x) => x.id == 'mary');
    await t.pumpWidget(app(PlayAlongScreen(services: s.services, song: song)));
    await t.tap(find.text('🦁')); // last key, but the song starts on E
    await t.pump(const Duration(milliseconds: 100));
    expect(s.sound.played.last, 'piano_64');
    await t.tap(find.text('🐱'));
    await t.pump(const Duration(milliseconds: 100));
    expect(s.sound.played.last, 'piano_62');
  });

  testWidgets('karaoke: sing, then hear yourself with a silly voice', (t) async {
    await landscape(t);
    final s = makeServices();
    final song = testSongs.firstWhere((x) => x.id == 'buns');
    final rendered = <String>[];
    await t.pumpWidget(
      app(
        KaraokeScreen(
          services: s.services,
          song: song,
          render: (rec, v, lead) async {
            rendered.add(v.name);
            return Uint8List(8);
          },
        ),
      ),
    );
    await t.tap(find.byKey(const Key('sing')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(s.mic.started, isTrue);
    final track = s.sound.tracks.single;
    expect(track.asset, 'assets/backing/buns.ogg');
    expect(find.byKey(const Key('countdown')), findsOneWidget);
    track.position = song.startOf(song.notes[2]) + 0.01;
    await t.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('buns'), findsWidgets);
    track.position = track.length;
    await settle(t);
    expect(s.sound.played, contains('applause'));
    await t.tap(find.byKey(const Key('voice-chipmunk')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(rendered, ['chipmunk']);
    final playback = s.sound.tracks.last;
    expect(playback.voiceWav, isNotNull);
    await t.tap(find.byKey(const Key('stop')));
    await t.pump(const Duration(milliseconds: 50));
    expect(playback.stopped, isTrue);
    await t.pumpWidget(const SizedBox());
    expect(s.mic.disposed, isTrue);
  });

  testWidgets('karaoke without the microphone is sing-along only', (t) async {
    await landscape(t);
    final s = makeServices();
    s.services.settings.karaokeMic = false;
    await t.pumpWidget(app(KaraokeScreen(services: s.services, song: testSongs.first)));
    expect(find.text('Sing along! (No recording)'), findsOneWidget);
    await t.tap(find.byKey(const Key('sing')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(s.mic.started, isFalse);
    final FakeTrack track = s.sound.tracks.single;
    track.position = track.length;
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('sing')), findsOneWidget); // back to the start, nothing to listen to
    await t.pumpWidget(const SizedBox());
  });
}
