import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/art.dart';
import '../../app/services.dart';
import '../../core/music.dart';
import '../../widgets/keyboard.dart';
import '../../widgets/studio.dart';
import '../beats/beat_maker_screen.dart';
import '../grownups/grownups_screen.dart';
import '../grownups/parent_gate.dart';
import '../instruments/guitar_screen.dart';
import '../instruments/keys_screen.dart';
import '../instruments/pads_screen.dart';
import '../karaoke/karaoke_screen.dart';
import '../songs/play_along_screen.dart';
import '../songs/song_picker.dart';

/// One room of the studio on the home screen.
class Room {
  const Room(this.id, this.title, this.emoji, this.color, this.open);

  final String id;
  final String title;
  final String emoji;
  final Color color;
  final Widget Function(Services s) open;
}

final rooms = <Room>[
  Room(
    'piano',
    'Piano',
    '🎹',
    Instrument.piano.color,
    (s) => KeysScreen(services: s, instrument: Instrument.piano, style: KeyStyle.piano),
  ),
  Room(
    'xylophone',
    'Xylophone',
    '🌈',
    Instrument.xylophone.color,
    (s) => KeysScreen(services: s, instrument: Instrument.xylophone, style: KeyStyle.bars),
  ),
  Room('guitar', 'Guitar', '🎸', Instrument.guitar.color, (s) => GuitarScreen(services: s)),
  Room('drums', 'Drums', '🥁', const Color(0xFFFF5A5F), (s) => PadsScreen(services: s, title: 'Drums', pads: drumPads)),
  Room(
    'flute',
    'Magic Flute',
    '🪈',
    Instrument.flute.color,
    (s) => KeysScreen(services: s, instrument: Instrument.flute, style: KeyStyle.bubbles),
  ),
  Room(
    'silly',
    'Silly Sounds',
    '🤪',
    const Color(0xFF6BD425),
    (s) => PadsScreen(services: s, title: 'Silly Sounds', pads: sillyPads),
  ),
  Room('beats', 'Beat Maker', '🎛️', const Color(0xFF8E62FF), (s) => BeatMakerScreen(services: s)),
  Room(
    'songs',
    'Play a Song',
    '🎶',
    const Color(0xFF2EC4B6),
    (s) => SongPickerScreen(
      services: s,
      title: 'Play a Song',
      colors: const [Color(0xFF1FB5A5), Color(0xFF7ADFC9)],
      open: (song) => PlayAlongScreen(services: s, song: song),
    ),
  ),
  Room(
    'karaoke',
    'Karaoke',
    '🎤',
    const Color(0xFFFF5DA2),
    (s) => SongPickerScreen(
      services: s,
      title: 'Karaoke',
      colors: const [Color(0xFFB0307A), Color(0xFFFF7EB3)],
      open: (song) => KaraokeScreen(services: s, song: song),
    ),
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.services});
  final Services services;

  Future<void> _openGrownups(BuildContext context) async {
    if (!await showParentGate(context) || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GrownupsScreen(services: services)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StudioBackground(
        colors: const [Color(0xFF5B3CC4), Color(0xFFFF7EB3)],
        image: Art.homeBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                child: Row(
                  children: [
                    const Text('🎵', style: TextStyle(fontSize: 34)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        kAppName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                      ),
                    ),
                    HoldToOpen(key: const Key('grownups-gear'), onOpen: () => _openGrownups(context)),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    // Landscape: 5 x 2 so all nine rooms fit without scrolling; portrait: 3 x 3.
                    final cols = c.maxWidth > c.maxHeight ? 5 : 3;
                    final rows = (rooms.length / cols).ceil();
                    final tileW = (c.maxWidth - 24 - (cols - 1) * 14) / cols;
                    final fitH = (c.maxHeight - 24 - (rows - 1) * 14) / rows;
                    final ratio = (tileW / fitH).clamp(0.75, 1.6);
                    return GridView.count(
                      padding: const EdgeInsets.all(12),
                      crossAxisCount: cols,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: ratio,
                      children: [for (final r in rooms) _RoomCard(room: r, services: services)],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.services});
  final Room room;
  final Services services;

  @override
  Widget build(BuildContext context) {
    final art = Art.room(room.id);
    return Bouncy(
      key: Key('room-${room.id}'),
      semanticLabel: room.title,
      onTap: () {
        services.sound.play('silly_pop', gain: 0.5);
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => room.open(services)));
      },
      child: Container(
        decoration: candy(room.color),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: art == null
                    ? FittedBox(child: Text(room.emoji, style: const TextStyle(fontSize: 64)))
                    : Image.asset(art, fit: BoxFit.contain),
              ),
            ),
            FittedBox(child: Text(room.title, style: kidLabel)),
          ],
        ),
      ),
    );
  }
}

/// The grown-ups gear: it opens only after being held for one second, so a
/// toddler's tap does nothing.
class HoldToOpen extends StatefulWidget {
  const HoldToOpen({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  State<HoldToOpen> createState() => _HoldToOpenState();
}

class _HoldToOpenState extends State<HoldToOpen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _c.reset();
          widget.onOpen();
        }
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Grown-ups: press and hold',
      child: Listener(
        onPointerDown: (_) => unawaited(_c.forward()),
        onPointerUp: (_) => _c.reverse(),
        onPointerCancel: (_) => _c.reverse(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: _c.value, strokeWidth: 4, color: Colors.white),
                Opacity(
                  opacity: 0.75,
                  child: Text('⚙️', style: TextStyle(fontSize: 28 + 6 * _c.value)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
