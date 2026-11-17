import 'dart:io';
import 'dart:typed_data';

import 'package:tiny_tunes/ads/ads.dart';
import 'package:tiny_tunes/app/services.dart';
import 'package:tiny_tunes/audio/mic.dart';
import 'package:tiny_tunes/audio/wav.dart';
import 'package:tiny_tunes/core/songs.dart';
import 'package:tiny_tunes/core/sound_engine.dart';

final testSongs = parseSongs(File('assets/songs/songs.json').readAsStringSync());

class FakeMic implements Mic {
  FakeMic({this.allowed = true});

  final bool allowed;
  bool started = false;
  bool disposed = false;

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<void> start() async => started = true;

  @override
  Stream<double> get levels => const Stream.empty();

  @override
  Future<Pcm?> stop() async => started ? Pcm(Float32List(44100), 44100) : null;

  @override
  Future<void> dispose() async => disposed = true;
}

({Services services, RecordingSoundEngine sound, FakeMic mic}) makeServices({bool micAllowed = true}) {
  final sound = RecordingSoundEngine();
  final mic = FakeMic(allowed: micAllowed);
  return (
    services: Services(
      settings: Settings.memory(),
      sound: sound,
      ads: const NoAdService(),
      songs: testSongs,
      mic: () => mic,
    ),
    sound: sound,
    mic: mic,
  );
}
