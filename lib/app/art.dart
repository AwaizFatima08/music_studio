/// Approved homidev (Z-Image) art, prepared by tools/prep_art.py from the files in
/// assets/images and assets/icons (see assets/ASSET-REGISTER.md). The emoji stay as
/// fallbacks for anything without approved art.
class Art {
  const Art._();

  static const String homeBackground = 'assets/art/bg_home.webp';
  static const String stageBackground = 'assets/art/bg_stage.webp';

  // Approved by Homi 17 Nov 2026.
  static const _rooms = {'piano', 'xylophone', 'guitar', 'drums', 'flute', 'silly', 'beats', 'songs', 'karaoke'};

  // Second batch, approved by Homi 26 Nov 2026 (London Bridge rejected: it keeps its emoji).
  static const _songs = {'twinkle', 'mary', 'row', 'macdonald', 'buns', 'sleeping'};
  static const _voices = {'star', 'echo', 'chipmunk', 'giant', 'robot'};
  static const _pads = {
    'pad_kick',
    'pad_snare',
    'pad_hat',
    'pad_clap',
    'pad_tomhigh',
    'pad_tomlow',
    'pad_crash',
    'pad_bell',
    'pad_shaker',
    'silly_boing',
    'silly_pop',
    'silly_quack',
    'silly_zap',
    'silly_bubbles',
    'silly_up',
    'silly_down',
    'silly_trill',
  };

  /// Cut-out icon for a home-screen room (or instrument button), or null for the emoji.
  static String? room(String id) => _rooms.contains(id) ? 'assets/art/room_$id.webp' : null;

  /// Picture for a song card (song id from songs.json).
  static String? song(String id) => _songs.contains(id) ? 'assets/art/song_$id.webp' : null;

  /// Picture for a karaoke voice (KaraokeVoice.name).
  static String? voice(String name) => _voices.contains(name) ? 'assets/art/voice_$name.webp' : null;

  /// Picture for a drum, beat-maker or silly pad, keyed by its sound ('drum_kick' -> pad_kick, 'silly_pop').
  static String? pad(String sound) {
    final name = sound.startsWith('drum_') ? 'pad_${sound.substring(5)}' : sound;
    return _pads.contains(name) ? 'assets/art/$name.webp' : null;
  }
}
