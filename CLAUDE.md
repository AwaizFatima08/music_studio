# Tiny Tunes Studio — notes for Claude Code

Flutter Android music studio for small children (package `com.homilabs.tinytunes`, Dart package `tiny_tunes`,
launcher name "Tiny Tunes"). Started 17 Nov 2026 by Homi. See README.md for features and the code map.

## Locked (Homi, 17 Nov 2026)
- Root `/mnt/storage/projects/Tools/music_studio`. Backup `bash scripts/backup.sh` → local copies in
  `/mnt/storage/project_backups/Tools/music_studio_backup/` + push to GitHub `AwaizFatima08/music_studio`
  (**PUBLIC** — never commit `.secrets/`, keystores or `key.properties`).
- Package `com.homilabs.tinytunes`: never change it after the first Play upload.
- Ads: AdMob account **homilabs.smc@gmail.com**, child-directed, **banner on the Grown-ups screen only** (behind the
  held gear + sum gate). No ads on any play screen, no interstitials, no rewarded. See `docs/admob.md`.
- Karaoke records the child's voice **into memory only** (PCM stream, never a file, never sent), for playback
  with silly voices. Grown-ups can switch the microphone off (sing-along only).
- Website: slug `tinytunes` on tools.homilabs.org (privacy#tinytunes, terms#tinytunes). Blocks in `web/`, applied to
  pages fetched from the live site (never overwrite live pages with local copies).
- Graphics: Z-Image on homidev through the asset pipeline (`~/.claude/homidev.md`); ask Homi before every request.
  Approved art is wired in `lib/app/art.dart`; emoji and gradients stand in until then.
- Sounds and music come only from `tools/make_sounds.py` (synthesized; no samples to license). Songs are
  traditional/public-domain only (`assets/songs/songs.json`); the script renders the karaoke backing tracks from
  that same file, so re-run it after any song change.
- Sparkles are fades, never fast strobes (photosensitive children).
- Every HomiLabs app shows the HomiLabs logo with **Created By: HomiLabs** and **Managed By: Awaiz Fatima** (Grown-ups).

## Commands
```bash
python3 tools/make_sounds.py                 # regenerate sounds + backing tracks (~2 min)
flutter analyze && flutter test
jobq run --name tinytunes-debug-apk -- bash -c 'flutter build apk --debug && cd android && ./gradlew --stop'
bash scripts/build_release.sh                # real ads; needs .secrets/ad-units.env + upload key (not made yet)
bash scripts/backup.sh                       # commit first
```
Emulator: AVD `tinytunes_api35` in `/mnt/storage/projects/android-avd` (create when needed), always through `jobq`.

## Status (17 Nov 2026)
- v1.0.0+1 code complete with placeholder (emoji) art: 9 rooms (piano, xylophone, guitar, drums, flute, silly
  sounds, beat maker, play-a-song, karaoke), grown-ups screen, parent gate. 17 tests pass. Not yet run on a phone.
- Open: Z-Image art (prompts proposed to Homi), AdMob app + banner unit, upload key, launcher icon, store listing,
  website upload, device test of mic latency (`kMicLatencySeconds` in karaoke_screen.dart).
