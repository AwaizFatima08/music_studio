import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum KeyLabels { animals, letters, solfa, colours }

/// How much the lights move. Calm keeps only a soft glow on what was pressed.
enum LightsLevel { party, gentle, calm }

/// Everything the grown-ups can change, saved on the device with
/// shared_preferences. Nothing is sent anywhere.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  /// In-memory settings for tests.
  Settings.memory() : _prefs = null;

  final SharedPreferences? _prefs;

  KeyLabels labels = KeyLabels.animals;
  LightsLevel lights = LightsLevel.party;
  bool keepAwake = false;
  bool muted = false;

  /// Karaoke may record the child's voice (kept in memory only). Off = sing-along only.
  bool karaokeMic = true;

  /// 0..1, the child-facing volume. Never above [maxVolume].
  double volume = 0.7;

  /// 0.2..1, the loudest allowed (grown-ups only).
  double maxVolume = 0.85;

  double get effectiveVolume => muted ? 0 : volume.clamp(0, maxVolume);

  static Future<Settings> load() async {
    final p = await SharedPreferences.getInstance();
    final s = Settings._(p);
    T pick<T extends Enum>(List<T> values, String key, T fallback) =>
        values.where((v) => v.name == p.getString(key)).firstOrNull ?? fallback;
    s
      ..labels = pick(KeyLabels.values, 'labels', s.labels)
      ..lights = pick(LightsLevel.values, 'lights', s.lights)
      ..keepAwake = p.getBool('keepAwake') ?? false
      ..muted = p.getBool('muted') ?? false
      ..karaokeMic = p.getBool('karaokeMic') ?? true
      ..maxVolume = (p.getDouble('maxVolume') ?? s.maxVolume).clamp(0.2, 1.0)
      ..volume = (p.getDouble('volume') ?? s.volume).clamp(0.0, 1.0);
    return s;
  }

  /// Change one or more fields, then save and notify.
  void update(void Function(Settings s) change) {
    change(this);
    volume = volume.clamp(0, maxVolume);
    notifyListeners();
    _save();
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString('labels', labels.name);
    p.setString('lights', lights.name);
    p.setBool('keepAwake', keepAwake);
    p.setBool('muted', muted);
    p.setBool('karaokeMic', karaokeMic);
    p.setDouble('maxVolume', maxVolume);
    p.setDouble('volume', volume);
  }
}
