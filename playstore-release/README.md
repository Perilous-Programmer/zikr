# Zikr Timer: Google Play release kit

Everything needed to create the Play Console listing for the Flutter app in `../zikr_timer`, version 1.0.0 (versionCode 1).

`metadata/android/` follows the fastlane `supply` layout. You can upload it as-is with fastlane, or copy each file into Play Console by hand.

## Contents

| Path | What it is | Play Console field | Spec |
|---|---|---|---|
| `metadata/android/<lang>/title.txt` | App name | Main store listing > App name | ≤ 30 chars |
| `.../short_description.txt` | Short description | Short description | ≤ 80 chars |
| `.../full_description.txt` | Full description | Full description | ≤ 4000 chars |
| `.../changelogs/1.txt` | Release notes for versionCode 1 | Release > Release notes | ≤ 500 chars |
| `.../images/icon.png` | App icon | App icon | 512×512 32-bit PNG, ≤ 1 MB |
| `.../images/featureGraphic.png` | Feature graphic | Feature graphic | 1024×500 PNG, no alpha |
| `en-US/images/phoneScreenshots/` | 6 captioned phone screenshots | Phone screenshots | 1080×1920 |
| `ur/images/phoneScreenshots/` | 4 screenshots, Urdu ones first | Phone screenshots, Urdu listing | 1080×1920 |
| `en-US/images/sevenInchScreenshots/` | 3 tablet screenshots | 7-inch tablet screenshots | 1200×1920 |
| `en-US/images/tenInchScreenshots/` | 3 tablet screenshots | 10-inch tablet screenshots | 1600×2560 |
| `screenshots-raw/` | Uncaptioned app captures | Spares | 1080×2160 |
| `policy/privacy-policy.html` | Privacy policy, English and Urdu | App content > Privacy policy, as a public URL | |
| `policy/data-safety.md` | Data safety answers | App content > Data safety | |
| `policy/content-rating.md` | IARC questionnaire answers | App content > Content rating | |
| `policy/app-content.md` | Target audience, ads, and other declarations | App content | |
| `policy/store-settings.md` | Category, contact, countries, package | Store settings | |
| `source/` | HTML and Playwright scripts that produced the graphics | | |

Screenshots are real captures of the Flutter web build. The session history in them is sample data.

## Before you submit

1. **Decide the package name.** The app ID is still Flutter's placeholder, `com.zikr.zikr_timer`, with a TODO beside it in `zikr_timer/android/app/build.gradle.kts`. It can never change after the first upload. Change `applicationId` and `namespace` now if you want something like `com.yourname.zikrtimer`.
2. **Replace `CONTACT_EMAIL`** in `policy/*` with the support email you will list on Play.
3. **Host the privacy policy.** Play needs a public URL. GitHub Pages works: copy `policy/privacy-policy.html` to a `docs/` folder or `gh-pages` branch and enable Pages. The URL will look like `https://perilous-programmer.github.io/zikr/privacy-policy.html`.
4. **Build the signed bundle in CI.** Run the "Build Android" workflow with "build-aab" ticked and download the `zikr-timer-aab` artifact. The `ANDROID_KEYSTORE_*` secrets must be set, or the bundle is debug-signed and Play rejects it. Keep the `zikr-timer-android-symbols` artifact for every release, since crash stack traces are obfuscated.
5. **Use Play App Signing**, the default for new apps. Your CI keystore becomes the upload key. Back up the keystore and passwords outside GitHub.

## Upload order in Play Console

1. Create app: name, default language en-US, App, Free, then accept the declarations.
2. Fill **App content** with the answers in `policy/`.
3. Fill **Main store listing** for en-US. Add Urdu under "Manage translations" and paste the `ur/` text and images.
4. Fill **Store settings**: category, tags and contact details.
5. Create a release on **Testing > Closed testing** and upload `app-release.aab` with `changelogs/1.txt` as notes.
6. Personal developer accounts created after November 2023 must run a closed test with at least 12 opted-in testers for 14 days before production access is granted. Organisation accounts skip this.
7. Promote to **Production** and send for review.

## Optional: upload with fastlane

From the repo root, after creating the app once in Play Console and getting a service-account JSON key:

```bash
fastlane supply \
  --package_name com.zikr.zikr_timer \
  --json_key path/to/play-service-account.json \
  --metadata_path playstore-release/metadata/android \
  --aab zikr_timer/build/app/outputs/bundle/release/app-release.aab \
  --track internal
```

## Known gaps

- **The tablet layout is not adaptive.** On 7-inch and 10-inch screens the UI stays phone-sized in the middle of the screen, and the tablet screenshots show that honestly. Tablet screenshots are optional. Without them, Play shows the app as not "designed for tablets" but still installs it.
- **Urdu text renders in a Naskh-style system font**, not Nastaliq. This matches what most Android phones show.

## Regenerating the graphics

You need a Flutter web build served at `http://localhost:8765/`, and Python with `playwright` and `Pillow`.

```bash
python source/shot.py <out_dir>                 # raw app screenshots
python source/render.py <design_dir> <out_dir>  # feature graphic + captioned frames
```

`<design_dir>` must contain `feature.html`, `frame.html`, `icon.png` and the `phone_*.png` captures.
