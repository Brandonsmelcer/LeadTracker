# Vision To Legacy - Lead Tracker

## Project Overview

Cross-platform Flutter app (Android, iOS, Web) for Vision To Legacy Group. Tracks sales leads across TN, KY, and WV counties with role-based team management (Master -> Manager -> Associate), Discord-style communications, CSV import, and per-person stats.

## Cursor Cloud specific instructions

### Environment

- **Flutter SDK**: `/opt/flutter` (stable channel)
- **JDK**: OpenJDK 21 at `/usr/lib/jvm/java-21-openjdk-amd64`
- **Android SDK**: `/opt/android-sdk` with platform API 34+36, build-tools
- **Env vars** (`JAVA_HOME`, `ANDROID_HOME`, Flutter in `PATH`) set in `~/.bashrc`

### Key commands

| Task | Command |
|---|---|
| Install deps | `flutter pub get` |
| Run (web) | `flutter run -d chrome --web-port=8080` |
| Build web | `flutter build web` |
| Run tests | `flutter test` |
| Lint/analyze | `flutter analyze` |
| Build APK | `flutter build apk` |

### Gotchas

- This is a **headless cloud VM** — no Android emulator. Use `flutter run -d chrome` for web-based testing.
- The first Flutter build downloads the web SDK and Dart SDK, taking ~30s. Subsequent builds are fast.
- The `CsvToListConverter` from the `csv` package defaults to `\r\n` as row separator. The import code explicitly uses `eol: '\n'` for cross-platform compatibility.
- State management uses Provider (`ChangeNotifierProvider`). The `AppProvider` holds all app state in-memory.
- County data for all 270 counties (TN:95, KY:120, WV:55) is in `lib/data/county_data.dart`.
