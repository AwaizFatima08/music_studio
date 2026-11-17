import 'dart:convert';
import 'package:flutter/services.dart';

/// Every karaoke backing track starts with this many beats of ticks.
const countInBeats = 4;

/// One sung syllable.
class SongNote {
  const SongNote({
    required this.syllable,
    required this.midi,
    required this.startTick,
    required this.ticks,
    required this.line,
  });

  final String syllable;
  final int midi;
  final int startTick;
  final int ticks;

  /// Index of the lyric line this syllable belongs to.
  final int line;
}

/// A traditional song from assets/songs/songs.json. The same file drives the
/// rendered karaoke backing track (tools/make_sounds.py), so timings match.
class Song {
  Song({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
    required this.bpm,
    required this.ticksPerBeat,
    required this.beatsPerBar,
    required this.notes,
    required this.lineCount,
  });

  factory Song.fromJson(Map<String, dynamic> j) {
    final notes = <SongNote>[];
    var tick = 0;
    final lines = j['lines'] as List;
    for (var li = 0; li < lines.length; li++) {
      for (final n in lines[li] as List) {
        final ticks = n[2] as int;
        notes.add(SongNote(syllable: n[0] as String, midi: n[1] as int, startTick: tick, ticks: ticks, line: li));
        tick += ticks;
      }
    }
    final hex = (j['color'] as String).substring(1);
    return Song(
      id: j['id'] as String,
      title: j['title'] as String,
      emoji: j['emoji'] as String,
      color: Color(int.parse('FF$hex', radix: 16)),
      bpm: (j['bpm'] as num).toDouble(),
      ticksPerBeat: j['tpb'] as int,
      beatsPerBar: j['beatsPerBar'] as int,
      notes: notes,
      lineCount: lines.length,
    );
  }

  final String id;
  final String title;
  final String emoji;
  final Color color;
  final double bpm;
  final int ticksPerBeat;
  final int beatsPerBar;
  final List<SongNote> notes;
  final int lineCount;

  String get backingAsset => 'assets/backing/$id.ogg';

  double get secondsPerTick => 60 / bpm / ticksPerBeat;
  double get countInSeconds => countInBeats * 60 / bpm;

  /// When [note] starts in the backing track, in seconds.
  double startOf(SongNote note) => countInSeconds + note.startTick * secondsPerTick;
  double endOf(SongNote note) => startOf(note) + note.ticks * secondsPerTick;

  double get singingEnds => endOf(notes.last);

  List<SongNote> lineNotes(int line) => [
    for (final n in notes)
      if (n.line == line) n,
  ];

  /// The syllable being sung at [seconds] into the backing track: -1 during the
  /// count-in, then the latest note that has started (it stays lit through rests).
  int noteIndexAt(double seconds) {
    var lo = 0, hi = notes.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (startOf(notes[mid]) <= seconds) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }
}

List<Song> parseSongs(String json) => [
  for (final s in (jsonDecode(json) as Map<String, dynamic>)['songs'] as List) Song.fromJson(s as Map<String, dynamic>),
];

Future<List<Song>> loadSongs([AssetBundle? bundle]) async =>
    parseSongs(await (bundle ?? rootBundle).loadString('assets/songs/songs.json'));
