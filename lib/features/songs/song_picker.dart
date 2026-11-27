import 'package:flutter/material.dart';

import '../../app/art.dart';
import '../../app/services.dart';
import '../../core/songs.dart';
import '../../widgets/studio.dart';

/// Big song cards. Used by both "Play a Song" and "Karaoke".
class SongPickerScreen extends StatelessWidget {
  const SongPickerScreen({
    super.key,
    required this.services,
    required this.title,
    required this.colors,
    required this.open,
  });

  final Services services;
  final String title;
  final List<Color> colors;
  final Widget Function(Song song) open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StudioBackground(
        colors: colors,
        child: SafeArea(
          child: Column(
            children: [
              StudioTopBar(title: title, settings: services.settings),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 560 ? 3 : 2);
                    return GridView.count(
                      padding: const EdgeInsets.all(14),
                      crossAxisCount: cols,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.35,
                      children: [
                        for (final s in services.songs)
                          Bouncy(
                            key: Key('song-${s.id}'),
                            semanticLabel: s.title,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => open(s))),
                            child: Container(
                              decoration: candy(s.color),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ArtOrEmoji(art: Art.song(s.id), emoji: s.emoji),
                                  ),
                                  Text(
                                    s.title,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: kidLabel.copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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

/// One lyric line with the current syllable lit, for play-along and karaoke.
class LyricLine extends StatelessWidget {
  const LyricLine({
    super.key,
    required this.song,
    required this.line,
    required this.current,
    this.size = 34,
    this.dim = false,
  });

  final Song song;
  final int line;
  final int current;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    if (line < 0 || line >= song.lineCount) return SizedBox(height: size * 1.4);
    final notes = song.notes;
    final spans = <InlineSpan>[];
    for (var i = 0; i < notes.length; i++) {
      final n = notes[i];
      if (n.line != line) continue;
      final sung = i < current;
      final now = i == current;
      // A syllable ending in "-" continues the word ("Twin-", "kle"); single letters keep
      // the hyphen so "E-I-E-I-O" reads as sung.
      final joins = n.syllable.endsWith('-');
      final spelled = RegExp(r'^[A-Z]-$').hasMatch(n.syllable);
      final text = joins && !spelled ? n.syllable.substring(0, n.syllable.length - 1) : n.syllable;
      spans.add(
        TextSpan(
          text: text + (joins ? '' : ' '),
          style: TextStyle(
            color: dim
                ? Colors.white.withValues(alpha: 0.55)
                : now
                ? const Color(0xFFFFE45C)
                : sung
                ? Colors.white
                : Colors.white.withValues(alpha: 0.75),
            fontSize: now && !dim ? size * 1.15 : size,
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
        ),
      );
    }
    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.center, maxLines: 2);
  }
}
