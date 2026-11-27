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
- Approved homidev originals (`assets/images`, `assets/icons`, ~55 MB) are NOT bundled (Homi, 27 Nov 2026: keep the
  app lean); the app uses the WebP copies in `assets/art/` from `tools/prep_art.py`. `release-check.sh` therefore
  reports those two folders as not declared — expected.
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
bash scripts/build_release.sh                # real ads; needs .secrets/ad-units.env + upload key 
bash scripts/backup.sh                       # commit first
```
Emulator: AVD `tinytunes_api35` in `/mnt/storage/projects/android-avd` (create when needed), always through `jobq`.

## Status (17 Nov 2026)
- v1.0.0+1: 9 rooms, approved Z-Image art (12 jobs, `assets/ASSET-REGISTER.md`; app art made by `tools/prep_art.py`,
  launcher = smiling-note cutout on purple, Homi's choice), 17 tests pass. Emulator-tested (home, karaoke record +
  chipmunk playback, beat maker); the CPU emulator's System UI ANRs are the emulator, not the app.
- AdMob (homilabs.smc): app `ca-app-pub-2087846699268567~6782017763`, banner `.../5476674951` (`docs/admob.md`).
- Upload key `.secrets/tinytunes-upload.jks` (alias upload; password in `.secrets/tinytunes-upload-keystore-credentials.txt`;
  SHA-256 pinned in `scripts/build_release.sh`). **Losing it blocks Play updates**; local backup copies `.secrets/`.
- Website live 17 Nov: card + privacy#tinytunes + terms#tinytunes (`web/add_tinytunes.py`, server backups
  `*.bak-2026-11-17-tinytunes`).
- Play Console (Homilabs org account 9161588402757830740): app "Tiny Tunes Studio: Kids Music", app id
  4974786490227230640, created 17 Nov. App content done (ads yes, no sign-in, content rating Everyone/All ages,
  target 5 and under + 6-8 = Designed for Families, Teacher Approved requested, no AD_ID, Data safety = AdMob data
  only). Category Music & Audio, contact homilabs.smc@gmail.com. Listing text + icon + feature graphic in
  `docs/store-listing.md` / `store/` (`tools/make_store_assets.py`).
- **v1.0.0 (versionCode 1) sent to Play production review 17 Nov 2026**: full rollout, 178 countries, managed
  publishing off (goes live on approval). AAB `releases/v1.0.0-1/` (gitignored; local backup). Homi uploaded the
  AAB himself (the Chrome tool can't upload >10 MB). Listing assets labelled as AI-generated where they contain
  Z-Image art. Tested on Oppo CPH2743 (release build): all rooms, karaoke record + chipmunk playback.
- Play warning `android.hardware.screen.landscape` required (from sensorLandscape): fixed in 1.0.1 with
  `<uses-feature android:name="android.hardware.screen.landscape" android:required="false"/>`.
- 1.0.1 polish: on short phones the dim next lyric line pokes below the karaoke lyric panel; mic latency
  (`kMicLatencySeconds`) not yet tuned by ear on a real phone.
- After approval: AdMob → Tiny Tunes Studio → Add store; switch the tools.homilabs.org card to the Play link.
- **v1.0.1 (versionCode 2) built 23 Nov 2026**: Grown-ups screen (behind the held gear + sum gate) gets "Rate this
  app on Google Play" and "More from HomiLabs" (Rainbow Keys, TalkyPals, Bumper Buddies; tagged links in
  `lib/features/grownups/more_apps.dart`). No in-app review prompt. AAB `releases/v1.0.1-2/`, copy in
  `play-uploads/2026-11-23-kids/02-tinytunes/`. Not uploaded yet.
- **v1.1.0 (versionCode 3) built 27 Nov 2026**: Z-Image art (approved 26 Nov) for 6 song cards, 5 karaoke voices,
  9 drum/beat pads and 8 silly pads (`ArtOrEmoji`, emoji fallback), Rate/More apps from 1.0.1, new feature graphic
  (animal band). AAB `releases/v1.1.0-3/` (58 MB), copy + feature graphic + notes in
  `/mnt/storage/projects/play-uploads/2026-11-27-tinytunes/`. Supersedes 1.0.1+2 (never uploaded). Not yet tested on
  a phone (Oppo dropped off adb) and store screenshots not retaken.

