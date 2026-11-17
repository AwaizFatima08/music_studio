# AdMob — Tiny Tunes Studio

AdMob account: **homilabs.smc@gmail.com** (publisher `pub-2087846699268567`), same as the other HomiLabs apps.

| What | ID |
|---|---|
| App (Android) "Tiny Tunes Studio" | `ca-app-pub-2087846699268567~6782017763` |
| Banner `tinytunes_grownups_banner` | `ca-app-pub-2087846699268567/5476674951` |

Created 17 Nov 2026. Debug builds use Google's test ids; the real ids are in `.secrets/ad-units.env` (copy
`.secrets/ad-units.env.example`); only `scripts/build_release.sh` passes them in, and it refuses test ids.

Test devices (labelled test
ads even in release): Oppo Reno14 F, Galaxy Tab S9 FE — see `testDeviceIds` in `lib/ads/admob_ad_service.dart`.
**Caveat:** without the AD_ID permission the SDK's hashed device id changes when the app is reinstalled
(Tab S9 was `84F0…` on the debug install, `516B…` on the release install), so the list does not reliably cover a
release build. When testing a release APK on our own devices, open Grown-ups rarely and never tap the ad.

## Rules for a toddler app (Google Play Families policy)
- Only one placement: a **banner on the Grown-ups screen**, behind the hold-the-gear + sum parent gate.
  No ads on the play screen, no interstitials, no rewarded ads.
- Every request: `AgeRestrictedTreatment.child`, max content rating **G**, `nonPersonalizedAds: true`.
  UMP consent request tagged under the age of consent.
- `com.google.android.gms.permission.AD_ID` is removed in the manifest; the release script checks it.
- In AdMob, when creating the app: mark it as **directed to children** (App settings → "Child-directed").
- Play Console: Target audience = ages 5 and under (and possibly 6–8); the app must join the Families
  programme; AdMob is a Families self-certified ad SDK.

## To do
1. Create the AdMob app (Android, not yet on Play) and the banner unit; mark the app child-directed.
2. After the Play listing is live: AdMob → app → **Add store**.

