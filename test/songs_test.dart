import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_tunes/core/music.dart';
import 'package:tiny_tunes/core/songs.dart';

import 'helpers.dart';

void main() {
  test('there are seven songs, each with notes and a rendered backing track', () {
    expect(testSongs, hasLength(7));
    for (final s in testSongs) {
      expect(s.notes, isNotEmpty, reason: s.id);
      expect(File(s.backingAsset).existsSync(), isTrue, reason: '${s.backingAsset} missing: run tools/make_sounds.py');
    }
  });

  test('chords last exactly as long as the melody (the backing track would drift otherwise)', () {
    final raw = File('assets/songs/songs.json').readAsStringSync();
    for (final s in testSongs) {
      final chordTicks = RegExp('"id": "${s.id}"[\\s\\S]*?"chords": (\\[[^\\n]*\\])').firstMatch(raw)!.group(1)!;
      final total = RegExp(
        r'\["[A-G][a-z0-9]*", (\d+)\]',
      ).allMatches(chordTicks).fold(0, (a, m) => a + int.parse(m.group(1)!));
      expect(total, s.notes.last.startTick + s.notes.last.ticks, reason: s.id);
    }
  });

  test('every note can be played by the instruments and shown on the eight keys', () {
    for (final s in testSongs) {
      for (final n in s.notes) {
        expect(n.midi, inInclusiveRange(Instrument.lowest, Instrument.highest));
        expect(keyForNote(n.midi), inInclusiveRange(0, 7));
        expect(File('assets/sounds/${Instrument.piano.sound(n.midi)}.ogg').existsSync(), isTrue);
      }
    }
  });

  test('keyForNote maps note names to the rainbow keys', () {
    expect(keyForNote(60), 0);
    expect(keyForNote(67), 4);
    expect(keyForNote(55), 4); // low G uses the G key
    expect(keyForNote(72), 7);
  });

  test('lyrics read as words: hyphenated syllables join up', () {
    final twinkle = testSongs.firstWhere((s) => s.id == 'twinkle');
    final line = twinkle.lineNotes(0).map((n) => n.syllable).join(' ').replaceAll('- ', '');
    expect(line, 'Twinkle twinkle little star,');
  });

  test('noteIndexAt follows the backing track timing', () {
    final s = testSongs.first;
    expect(s.noteIndexAt(0), -1); // count-in
    expect(s.noteIndexAt(s.countInSeconds + 0.01), 0);
    expect(s.noteIndexAt(s.startOf(s.notes[5]) + 0.01), 5);
    expect(s.noteIndexAt(9999), s.notes.length - 1);
    expect(countInBeats, 4);
  });
}
