# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zikr Timer is an interval/level countdown timer for zikr (dhikr) with English/Urdu localization, RTL support, light/dark themes, and session history. It exists in two implementations that must be kept feature-equivalent:

1. **Root directory** — the original dependency-free PWA (plain HTML/CSS/JS, no build system).
2. **[zikr_timer/](zikr_timer/)** — the Flutter port (Android + web).

## Flutter App (zikr_timer/)

**Environment gotcha:** this repo lives in WSL, but the Flutter SDK is a *Windows* install (`/mnt/d/software/flutter-sdk`) whose shell scripts cannot run from bash. Run Flutter commands through `cmd.exe`, and because cmd.exe cannot cd into `\\wsl.localhost` UNC paths, first rsync the project to the Windows filesystem, run there, and copy results back:

```bash
WT=/mnt/c/Users/X1EXTR~1/AppData/Local/Temp/zikr_timer
rsync -a --delete /home/kali/abd/zikr/zikr_timer/ "$WT/"
cmd.exe /c "cd /d %TEMP%\zikr_timer && flutter analyze"
cmd.exe /c "cd /d %TEMP%\zikr_timer && flutter test"
cmd.exe /c "cd /d %TEMP%\zikr_timer && flutter build web"   # or: flutter build apk
```

- The whole app is [zikr_timer/lib/main.dart](zikr_timer/lib/main.dart): `translations` map (en/ur), `Palette` (mirrors the PWA's CSS variables), `Session` model, `ZikrApp` (theme + language state), `TimerPage` (timer, settings, history).
- Persistence is all `shared_preferences`: individual keys for settings/lang/dark, and a JSON array under `zikrSessions` for history.
- Beeps play `assets/beep.wav` (generated 880 Hz sine) via `audioplayers`.
- Launcher icons are generated with `dart run flutter_launcher_icons` from `assets/icon-512.png` (Android, iOS, and web).
- **CI:** [.github/workflows/android.yml](.github/workflows/android.yml) and [ios.yml](.github/workflows/ios.yml) are manual-only (`workflow_dispatch`). Android release signing reads `android/key.properties`, which CI writes from the `ANDROID_KEYSTORE_*` secrets (base64 keystore, store password, key alias, key password); without it, builds fall back to debug signing. The Android workflow also publishes the APK/AAB as a GitHub release tagged `v<pubspec version name>-<run number>` (toggle with the `create-release` input). The iOS workflow produces an unsigned IPA — no Apple signing secrets are configured. The Windows machine has no Android SDK, so APK builds only work in CI.

## Original PWA (root)

Serve locally — service workers require HTTP (not `file://`):

```bash
python3 -m http.server 8000
# then open http://localhost:8000/ZikrTimer.html
```

## PWA Architecture

- **[ZikrTimer.html](ZikrTimer.html)** — the entire application: all CSS (in `<style>`), all markup, and all JS (in `<script>`). Key sections of the script, in order: `translations` dict (en/ur), timer state variables, IndexedDB session log (`zikrTimerDB` / `sessions` store), history modal rendering, Web Audio beeps, ring/display rendering, language & theme handling, settings steppers, and timer control (`startTimer`/`pauseTimer`/`resetTimer`/`finishTimer`).
- **[sw.js](sw.js)** — service worker with cache-first strategy. `CACHE_NAME` (`zikr-timer-vN`) must be bumped whenever ZikrTimer.html or other cached assets change, or installed PWAs will keep serving the stale version.
- **[manifest.json](manifest.json)** — PWA manifest; `start_url` is `./ZikrTimer.html`, not `index.html`.

## Persistence

Two separate mechanisms:
- **localStorage** (`zikrTimer` key) — user preferences: interval, level count, language, dark mode. Saved via `savePrefs()` on every change.
- **IndexedDB** (`zikrTimerDB`) — completed/stopped session records, written by `logSession()` from `finishTimer()` and `resetTimer()`.

## i18n Conventions

Static UI text uses `data-i18n="key"` attributes resolved by `setLanguage()`; dynamically-built strings (buttons, history entries) pull from `translations[currentLang]` at render time. Any new user-facing string needs both an `en` and `ur` entry, and layout should be checked in RTL mode (`body.rtl` is toggled when Urdu is active).
