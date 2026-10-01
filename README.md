# Chess

Production-ready cross-platform chess application with offline and online play.

## Flavors

| Flavor | Entry point | Env config | Android app ID | App name |
|--------|-------------|------------|----------------|----------|
| **dev** | `lib/main_dev.dart` | `config/env/dev.json` | `com.chessapp.chess.dev` | Chess Dev |
| **staging** | `lib/main_staging.dart` | `config/env/staging.json` | `com.chessapp.chess.staging` | Chess Staging |
| **prod** | `lib/main_prod.dart` | `config/env/prod.json` | `com.chessapp.chess` | Chess |

All flavors share Firebase project `chess-347ba`. The **dev** flavor connects to local Firebase emulators when `USE_FIREBASE_EMULATORS` is `true` in `config/env/dev.json`.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.x stable |
| Dart | ^3.11.0 |
| Node.js | 20 LTS (Firebase / Cloud Functions) |
| Java JDK | 17 (Android builds) |

```bash
# Install dependencies
flutter pub get

# Firebase one-time setup (generates firebase_options.dart, google-services.json, etc.)
./scripts/firebase_setup.sh dev
```

See [docs/firebase/SETUP.md](docs/firebase/SETUP.md) for full Firebase configuration.

---

## Run (all flavors)

Helper script (recommended):

```bash
./scripts/run_flavor.sh <flavor> [extra flutter run args]
```

### Dev

```bash
./scripts/run_flavor.sh dev
./scripts/run_flavor.sh dev -d chrome
./scripts/run_flavor.sh dev -d macos
./scripts/run_flavor.sh dev -d <device-id>
```

```bash
flutter run -t lib/main_dev.dart --dart-define-from-file=config/env/dev.json --flavor dev
```

### Staging

```bash
./scripts/run_flavor.sh staging
./scripts/run_flavor.sh staging -d chrome
./scripts/run_flavor.sh staging -d ios
```

```bash
flutter run -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json --flavor staging
```

### Prod

```bash
./scripts/run_flavor.sh prod
./scripts/run_flavor.sh prod -d chrome
./scripts/run_flavor.sh prod -d android
```

```bash
flutter run -t lib/main_prod.dart --dart-define-from-file=config/env/prod.json --flavor prod
```

### Local dev with Firebase emulators

Terminal 1 — start emulators:

```bash
./scripts/run_emulators.sh dev
```

Terminal 2 — run the app:

```bash
./scripts/run_flavor.sh dev
```

Emulator UI: http://localhost:4000

| Service | Port |
|---------|------|
| Auth | 9099 |
| Firestore | 8080 |
| Functions | 5001 |

---

## Build (all flavors)

Helper script:

```bash
./scripts/build_flavor.sh <flavor> <platform>
```

Default platform is `apk` if omitted.

### Android APK

```bash
./scripts/build_flavor.sh dev apk
./scripts/build_flavor.sh staging apk
./scripts/build_flavor.sh prod apk
```

```bash
flutter build apk -t lib/main_dev.dart     --dart-define-from-file=config/env/dev.json     --flavor dev
flutter build apk -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json --flavor staging
flutter build apk -t lib/main_prod.dart    --dart-define-from-file=config/env/prod.json    --flavor prod
```

Output: `build/app/outputs/flutter-apk/app-<flavor>-release.apk`

### Android App Bundle (Play Store)

```bash
./scripts/build_flavor.sh dev appbundle
./scripts/build_flavor.sh staging appbundle
./scripts/build_flavor.sh prod appbundle
```

```bash
flutter build appbundle -t lib/main_dev.dart     --dart-define-from-file=config/env/dev.json     --flavor dev
flutter build appbundle -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json --flavor staging
flutter build appbundle -t lib/main_prod.dart    --dart-define-from-file=config/env/prod.json    --flavor prod
```

### iOS

```bash
./scripts/build_flavor.sh dev ios
./scripts/build_flavor.sh staging ios
./scripts/build_flavor.sh prod ios
```

```bash
flutter build ios -t lib/main_dev.dart     --dart-define-from-file=config/env/dev.json     --flavor dev
flutter build ios -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json --flavor staging
flutter build ios -t lib/main_prod.dart    --dart-define-from-file=config/env/prod.json    --flavor prod
```

iOS flavor xcconfigs live in `ios/Flutter/{dev,staging,prod}.xcconfig`. Open `ios/Runner.xcworkspace` in Xcode to configure signing.

### Web

```bash
./scripts/build_flavor.sh dev web
./scripts/build_flavor.sh staging web
./scripts/build_flavor.sh prod web
```

```bash
flutter build web -t lib/main_dev.dart     --dart-define-from-file=config/env/dev.json
flutter build web -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json
flutter build web -t lib/main_prod.dart    --dart-define-from-file=config/env/prod.json
```

### macOS

```bash
./scripts/build_flavor.sh dev macos
./scripts/build_flavor.sh staging macos
./scripts/build_flavor.sh prod macos
```

```bash
flutter build macos -t lib/main_dev.dart     --dart-define-from-file=config/env/dev.json
flutter build macos -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json
flutter build macos -t lib/main_prod.dart    --dart-define-from-file=config/env/prod.json
```

### Windows

```bash
./scripts/build_flavor.sh dev windows
./scripts/build_flavor.sh staging windows
./scripts/build_flavor.sh prod windows
```

```bash
flutter build windows -t lib/main_dev.dart     --dart-define-from-file=config/env/dev.json
flutter build windows -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json
flutter build windows -t lib/main_prod.dart    --dart-define-from-file=config/env/prod.json
```

### Linux

```bash
./scripts/build_flavor.sh dev linux
./scripts/build_flavor.sh staging linux
./scripts/build_flavor.sh prod linux
```

```bash
flutter build linux -t lib/main_dev.dart     --dart-define-from-file=config/env/dev.json
flutter build linux -t lib/main_staging.dart --dart-define-from-file=config/env/staging.json
flutter build linux -t lib/main_prod.dart    --dart-define-from-file=config/env/prod.json
```

> **Note:** Firebase is not supported on Linux. Linux builds run without Firebase.

---

## Firebase & backend scripts

| Script | Usage | Description |
|--------|-------|-------------|
| `firebase_setup.sh` | `./scripts/firebase_setup.sh [dev\|staging\|prod]` | One-time Firebase / FlutterFire setup |
| `run_emulators.sh` | `./scripts/run_emulators.sh [dev\|staging\|prod]` | Start local Firebase emulators |
| `deploy_firebase.sh` | `./scripts/deploy_firebase.sh [flavor] [targets]` | Deploy Firestore rules, indexes, and/or functions |
| `patch_google_services_flavors.sh` | `./scripts/patch_google_services_flavors.sh` | Patch `google-services.json` for all Android package names |

### Deploy examples

```bash
# Deploy Firestore rules + Cloud Functions (default)
./scripts/deploy_firebase.sh dev
./scripts/deploy_firebase.sh staging
./scripts/deploy_firebase.sh prod

# Deploy specific targets
./scripts/deploy_firebase.sh dev firestore
./scripts/deploy_firebase.sh dev functions
./scripts/deploy_firebase.sh prod firestore,functions
```

### Cloud Functions

```bash
cd functions && npm install
cd functions && npm run build
cd functions && npm test
cd functions && npm run lint
cd functions && npm run serve    # functions + firestore + auth emulators only
```

---

## Test & quality

```bash
# All Flutter unit / widget tests
flutter test

# Integration tests (device or emulator required)
flutter test integration_test/

# Update golden baselines after intentional UI changes
flutter test --update-goldens test/golden/

# Static analysis
flutter analyze

# Cloud Functions tests
cd functions && npm test
```

See [docs/testing/README.md](docs/testing/README.md) for the full testing guide.

---

## Code generation

```bash
# Localization (configured via l10n.yaml — runs automatically on flutter build/run)
flutter gen-l10n

# Freezed / json_serializable (when models change)
dart run build_runner build --delete-conflicting-outputs
```

---

## Useful Flutter commands

```bash
flutter pub get              # Install / update dependencies
flutter pub outdated         # Check for outdated packages
flutter clean                # Clear build artifacts
flutter devices              # List connected devices / emulators
flutter doctor               # Verify toolchain setup

# Profile mode (performance debugging)
./scripts/run_flavor.sh dev --profile

# Release mode on device
./scripts/run_flavor.sh prod --release

# Android signing report (SHA-1 for Firebase)
cd android && ./gradlew signingReport
```

---

## Project scripts reference

| Script | Arguments |
|--------|-----------|
| `scripts/run_flavor.sh` | `[dev\|staging\|prod]` + any `flutter run` flags |
| `scripts/build_flavor.sh` | `[dev\|staging\|prod]` `[apk\|appbundle\|ios\|web\|macos\|windows\|linux]` |
| `scripts/firebase_setup.sh` | `[dev\|staging\|prod]` |
| `scripts/run_emulators.sh` | `[dev\|staging\|prod]` |
| `scripts/deploy_firebase.sh` | `[dev\|staging\|prod]` `[firestore,functions]` |

---

## Documentation

| Topic | Path |
|-------|------|
| Firebase setup | [docs/firebase/SETUP.md](docs/firebase/SETUP.md) |
| Testing | [docs/testing/README.md](docs/testing/README.md) |
| Auth | [docs/auth/README.md](docs/auth/README.md) |
| Game / offline | [docs/game/README.md](docs/game/README.md) |
| Online / multiplayer | [docs/online/README.md](docs/online/README.md) |
| Chess engine | [docs/chess_engine/README.md](docs/chess_engine/README.md) |
# chess
