/// Approved homidev (Z-Image) art. Every entry is null until Homi approves the
/// image and it is integrated into assets/images/ (see assets/ASSET-REGISTER.md);
/// until then the screens draw emoji and gradients instead.
class Art {
  const Art._();

  static const String? homeBackground = null;
  static const String? stageBackground = null;

  static const Map<String, String> _rooms = {};

  /// Cut-out icon for a home-screen room, or null for the emoji.
  static String? room(String id) => _rooms[id];
}
