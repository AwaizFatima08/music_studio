# Tiny Tunes Studio (HomiLabs)

A colourful music studio for small children. Flutter, Android (landscape, also works in portrait on tablets).
No login, no accounts, nothing leaves the phone. Package `com.homilabs.tinytunes`.

## Rooms
- 🎹 **Piano**, 🌈 **Xylophone**, 🪈 **Magic Flute**: eight rainbow keys (C4–C5); many fingers at once, slide to
  glide. Switch instrument from the top bar. Key labels: animals, C D E, Do Re Mi or colours only.
- 🎸 **Guitar**: four chord buttons (C, G, F, Am) and six strings; swipe across to strum, tap to pluck.
- 🥁 **Drums** and 🤪 **Silly Sounds**: eight big pads each.
- 🎛️ **Beat Maker**: a 6 × 8 grid that loops; start from a template (Stomp, Dance, Parade, Bounce, Rain, Empty),
  change squares while it plays, three speeds.
- 🎶 **Play a Song**: the next note's key shines; any key plays the song's next note, so a child can't get it wrong.
  "Play for me" plays it alone.
- 🎤 **Karaoke**: backing track + bouncing-ball lyrics with a 4-beat count-in. The voice is recorded into memory;
  afterwards the child hears it over the music as Pop Star, Big Hall, Chipmunk, Giant or Robot.
- ⚙️ **Grown-ups** (hold the gear for one second, then answer a sum): volume and loudest volume, karaoke microphone
  on/off, key labels, sparkles (Party / Gentle / Calm), keep screen on, privacy, terms, credits. The only ad is a
  banner here.

Songs (traditional, public domain): Twinkle Twinkle Little Star, Mary Had a Little Lamb, Row Row Row Your Boat,
Old MacDonald Had a Farm, London Bridge, Hot Cross Buns, Are You Sleeping?

## Sounds
`tools/make_sounds.py` synthesizes everything (numpy/scipy, OGG via ffmpeg): 4 instruments × MIDI 43–84, drums,
silly sounds, rewards, and one backing track per song rendered from `assets/songs/songs.json` (melody guide, bass,
chords, drums). Playback: `flutter_soloud` (low latency, 32 voices). Font: Quicksand (OFL, `assets/fonts/OFL.txt`).

## Code map
- `lib/core/` — `music.dart` (instruments, keys, pads, chords), `songs.dart` (song model + timing), `beats.dart`
  (templates + step machine), `sound_engine.dart` (SoLoud + test fake), `settings.dart`
- `lib/audio/` — `mic.dart` (record → memory), `voice_fx.dart` (karaoke voices), `dsp.dart`/`wav.dart` (from Giggle Voice)
- `lib/features/` — home, instruments (keys, guitar, pads), beats, songs (picker, play-along), karaoke, grown-ups
- `lib/widgets/` — studio look (background, candy buttons, top bar), keyboard, particle fx
- `lib/ads/` — AdMob behind `AdService` (from Rainbow Keys)
- `lib/app/art.dart` — approved homidev art
