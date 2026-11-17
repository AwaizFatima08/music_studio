/// Approved homidev (Z-Image) art, prepared by tools/prep_art.py from the files in
/// assets/images and assets/icons (see assets/ASSET-REGISTER.md). Approved by Homi
/// on 17 Nov 2026. The emoji stay as fallbacks for any room without art.
class Art {
  const Art._();

  static const String homeBackground = 'assets/art/bg_home.webp';
  static const String stageBackground = 'assets/art/bg_stage.webp';

  static const _rooms = {'piano', 'xylophone', 'guitar', 'drums', 'flute', 'silly', 'beats', 'songs', 'karaoke'};

  /// Cut-out icon for a home-screen room, or null for the emoji.
  static String? room(String id) => _rooms.contains(id) ? 'assets/art/room_$id.webp' : null;
}
