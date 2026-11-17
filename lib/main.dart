import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ads/ads.dart';
import 'app/services.dart';
import 'audio/mic.dart';
import 'core/music.dart';
import 'core/songs.dart';
import 'core/sound_engine.dart';
import 'features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final settings = await Settings.load();
  final sound = SoLoudEngine();
  await sound.init();
  final services = Services(
    settings: settings,
    sound: sound,
    ads: AdService.fromEnvironment(),
    songs: await loadSongs(),
    mic: RecordMic.new,
  );
  unawaited(sound.load([...padSounds, ...rewardSounds]));
  runApp(TinyTunesApp(services: services));
  // Consent and ad SDK start after the first frame; ads only ever show on the Grown-ups screen.
  unawaited(services.ads.init());
}

class TinyTunesApp extends StatefulWidget {
  const TinyTunesApp({super.key, required this.services});
  final Services services;

  @override
  State<TinyTunesApp> createState() => _TinyTunesAppState();
}

class _TinyTunesAppState extends State<TinyTunesApp> {
  Settings get s => widget.services.settings;

  @override
  void initState() {
    super.initState();
    s.addListener(_apply);
    _apply();
  }

  @override
  void dispose() {
    s.removeListener(_apply);
    super.dispose();
  }

  void _apply() {
    widget.services.sound.volume = s.effectiveVolume;
    unawaited(WakelockPlus.toggle(enable: s.keepAwake).catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Quicksand',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E62FF)),
        useMaterial3: true,
      ),
      home: HomeScreen(services: widget.services),
    );
  }
}
