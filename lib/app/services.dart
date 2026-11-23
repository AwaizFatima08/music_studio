import '../ads/ads.dart';
import '../audio/mic.dart';
import '../core/settings.dart';
import '../core/songs.dart';
import '../core/sound_engine.dart';

export '../core/settings.dart';

/// App-wide objects, handed down from main() to every screen.
class Services {
  const Services({
    required this.settings,
    required this.sound,
    required this.ads,
    required this.songs,
    required this.mic,
  });

  final Settings settings;
  final SoundEngine sound;
  final AdService ads;
  final List<Song> songs;

  /// Makes a fresh microphone for one karaoke session.
  final Mic Function() mic;
}

const kAppName = 'Tiny Tunes Studio';
const kAppVersion = '1.0.1';
const kPrivacyUrl = 'https://tools.homilabs.org/privacy#tinytunes';
const kTermsUrl = 'https://tools.homilabs.org/terms#tinytunes';
