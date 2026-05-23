# LeadTracker - Agent Instructions

## Project Overview

LeadTracker is a native Android app (Kotlin + Jetpack Compose) for tracking sales leads across U.S. states and counties. Single-module Gradle project under `app/`. No backend, no database — all data is in-memory Compose state.

## Cursor Cloud specific instructions

### Environment

- **JDK**: OpenJDK 21 at `/usr/lib/jvm/java-21-openjdk-amd64`
- **Android SDK**: Installed at `/opt/android-sdk` with platform API 34 and build-tools 34.0.0
- **Env vars** (`JAVA_HOME`, `ANDROID_HOME`, `PATH`) are set in `~/.bashrc`; source it or export manually if needed in non-login shells.

### Key commands

| Task | Command |
|---|---|
| Build debug APK | `./gradlew assembleDebug` |
| Run unit tests | `./gradlew test` |
| Run lint | `./gradlew lint` |
| Clean build | `./gradlew clean` |

### Gotchas

- `gradlew` may need `chmod +x` after a fresh clone.
- This is a **headless cloud VM** — there is no Android emulator or physical device. Instrumented tests (`connectedCheck`) cannot run. Only JVM-based unit tests (`./gradlew test`) are available.
- The first Gradle build downloads the Gradle distribution and all dependencies, which takes ~2 minutes. Subsequent builds are fast (~1-2s) thanks to the Gradle daemon and caches.
- Lint produces only warnings (0 errors); warnings are about newer dependency versions and unused color resources — these are informational.
- The APK output is at `app/build/outputs/apk/debug/app-debug.apk`.
