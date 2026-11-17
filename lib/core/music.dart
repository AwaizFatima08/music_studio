import 'dart:ui';

/// Instruments with one synthesized sample per MIDI note (tools/make_sounds.py
/// writes `assets/sounds/<prefix>_<midi>.ogg` for MIDI 43..84).
enum Instrument {
  piano('Piano', '🎹', 'piano', Color(0xFFFF6B9D)),
  xylophone('Xylophone', '🌈', 'xylo', Color(0xFFFFB534)),
  flute('Magic Flute', '🪈', 'flute', Color(0xFF4FC3F7)),
  guitar('Guitar', '🎸', 'guitar', Color(0xFFFF8A3D));

  const Instrument(this.title, this.emoji, this.prefix, this.color);

  final String title;
  final String emoji;
  final String prefix;
  final Color color;

  static const lowest = 43;
  static const highest = 84;

  /// The sample for [midi], clamped to the range that exists on disk.
  String sound(int midi) => '${prefix}_${midi.clamp(lowest, highest)}';

  List<String> get allSounds => [for (var m = lowest; m <= highest; m++) '${prefix}_$m'];
}

/// The eight big keys: C4..C5, one rainbow colour each.
const keyNotes = [60, 62, 64, 65, 67, 69, 71, 72];
const keyColors = [
  Color(0xFFFF5A5F),
  Color(0xFFFF9F1C),
  Color(0xFFFFD23F),
  Color(0xFF6BD425),
  Color(0xFF2EC4B6),
  Color(0xFF3A86FF),
  Color(0xFF8E62FF),
  Color(0xFFFF5DA2),
];
const keyLetters = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'];
const keySolfa = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Ti', 'Do'];
const keyAnimals = ['🐱', '🐶', '🐘', '🦊', '🐸', '🐵', '🐧', '🦁'];

/// Which of the eight keys plays [midi] in a song: the key with the same note
/// name (any octave), with high C on the last key.
int keyForNote(int midi) {
  if (midi >= 72 && midi % 12 == 0) return 7;
  const byPitchClass = {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6};
  return byPitchClass[midi % 12] ?? (byPitchClass[(midi + 1) % 12] ?? 0);
}

/// One drum pad or silly-sound pad.
class Pad {
  const Pad(this.sound, this.label, this.emoji, this.color);

  final String sound;
  final String label;
  final String emoji;
  final Color color;
}

const drumPads = [
  Pad('drum_kick', 'Boom', '🥁', Color(0xFFFF5A5F)),
  Pad('drum_snare', 'Snap', '🪘', Color(0xFFFF9F1C)),
  Pad('drum_hat', 'Tss', '✨', Color(0xFFFFD23F)),
  Pad('drum_clap', 'Clap', '👏', Color(0xFF6BD425)),
  Pad('drum_tomhigh', 'Tom', '🔵', Color(0xFF2EC4B6)),
  Pad('drum_tomlow', 'Bom', '🟣', Color(0xFF3A86FF)),
  Pad('drum_crash', 'Crash', '💥', Color(0xFF8E62FF)),
  Pad('drum_bell', 'Ding', '🔔', Color(0xFFFF5DA2)),
];

const sillyPads = [
  Pad('silly_boing', 'Boing', '🦘', Color(0xFFFF5A5F)),
  Pad('silly_pop', 'Pop', '🎈', Color(0xFFFF9F1C)),
  Pad('silly_quack', 'Quack', '🦆', Color(0xFFFFD23F)),
  Pad('silly_zap', 'Zap', '⚡', Color(0xFF6BD425)),
  Pad('silly_bubbles', 'Bubbles', '🫧', Color(0xFF2EC4B6)),
  Pad('silly_up', 'Wheee', '🚀', Color(0xFF3A86FF)),
  Pad('silly_down', 'Whooo', '🛝', Color(0xFF8E62FF)),
  Pad('silly_trill', 'Tweet', '🐦', Color(0xFFFF5DA2)),
];

/// Guitar chord buttons. Each list is the six strings low to high (MIDI).
class Chord {
  const Chord(this.name, this.strings, this.color);

  final String name;
  final List<int> strings;
  final Color color;
}

const guitarChords = [
  Chord('C', [48, 52, 55, 60, 64, 67], Color(0xFFFF5A5F)),
  Chord('G', [43, 47, 50, 55, 59, 67], Color(0xFF2EC4B6)),
  Chord('F', [53, 57, 60, 65, 69, 72], Color(0xFFFFB534)),
  Chord('Am', [45, 52, 57, 60, 64, 69], Color(0xFF8E62FF)),
];

const rewardSounds = ['cheer', 'fanfare', 'applause', 'tick'];
List<String> get padSounds => [
  for (final p in [...drumPads, ...sillyPads]) p.sound,
  'drum_shaker',
];
