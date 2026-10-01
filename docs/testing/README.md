# Testing Guide

Complete test suite for the Chess app covering unit, widget, golden, integration, repository, performance, and regression tests.

## Quick start

```bash
# All Flutter tests
flutter test

# Cloud Functions tests
cd functions && npm test

# Integration tests (device or emulator required)
flutter test integration_test/

# Update golden baselines after intentional UI changes
flutter test --update-goldens test/golden/
```

## Structure

```
test/
├── flutter_test_config.dart   # Disables Google Fonts network in tests
├── helpers/
│   ├── test_harness.dart      # Hive, GetX, themed MaterialApp wrappers
│   └── fakes.dart             # Fake connectivity, Firestore, Functions, online spy
├── unit/
│   ├── auth/                  # Validator, repository, failures
│   ├── chess_engine/          # Rules, perft, AI, performance
│   ├── game/                  # Offline logic, cloud sync, sync queue, repository
│   ├── leaderboard/           # Entities, repository
│   ├── online/                # Matchmaking, multiplayer, reconnect, repository
│   └── regression/            # Fixed edge cases from prior phases
├── widget/                    # Auth form, splash, breakpoints, motion, leaderboard
├── golden/                    # Visual regression (auth card, splash)
└── performance/               # Engine perft and move-gen budgets

integration_test/
├── app_flow_test.dart         # App launch smoke
└── offline_reconnect_test.dart # Offline engine + reconnect profile

functions/test/                # Server-side validation, matchmaking, leaderboard
```

## Coverage by domain

| Domain | Test types | Key files |
|--------|------------|-----------|
| **Authentication** | Unit, widget | `auth_validator_test.dart`, `auth_repository_test.dart`, `auth_form_card_test.dart` |
| **Chess rules** | Unit, performance | `chess_rules_test.dart`, `perft_test.dart`, `chess_engine_perf_test.dart` |
| **Leaderboard** | Unit, repository, widget | `leaderboard_test.dart`, `leaderboard_repository_test.dart`, `leaderboard_tab_test.dart` |
| **Matchmaking** | Unit | `matchmaking_test.dart`, `matchmaking_edge_cases_test.dart` |
| **Multiplayer** | Unit, repository | `online_game_entity_test.dart`, `online_game_repository_test.dart`, `online_game_model_test.dart` |
| **Offline** | Unit, integration | `offline_game_logic_test.dart`, `game_repository_test.dart`, `offline_reconnect_test.dart` |
| **Reconnect** | Unit, integration | `reconnect_test.dart`, `auth_repository_test.dart` (activeGameId) |
| **Cloud save** | Unit | `cloud_sync_test.dart`, `cloud_sync_service_test.dart`, `sync_queue_test.dart` |
| **Edge cases** | Unit, regression | `matchmaking_edge_cases_test.dart`, `regression_test.dart` |
| **Regression** | Unit | `regression_test.dart` (pins, sync version, profile) |

## Conventions

- **Hive isolation**: Each test file uses `TestHarness.uniqueHivePath()` to avoid lock conflicts when tests run in parallel.
- **Fakes over mocks**: Repository tests inject `FakeFunctionsService`, `SpyOnlineGameRemoteDataSource`, and `FakeConnectivityService`.
- **Golden tests**: Run with `--update-goldens` only when UI changes are intentional. Baselines live beside tests in `test/golden/*.png`.
- **Integration tests**: Require a connected device/emulator; they bootstrap real bindings but do not hit production Firebase.

## CI recommendations

```yaml
- run: flutter test
- run: flutter test --update-goldens  # only on golden-update jobs
- run: cd functions && npm test
```

## Adding tests

1. Place tests under the matching `test/` subdirectory.
2. Use `TestHarness.initHive(path: TestHarness.uniqueHivePath('prefix'))` in `setUp`.
3. Wrap widgets with `TestHarness.themed()` or `TestHarness.getThemed()` for GetX screens.
4. For new goldens, add `test/golden/<name>_golden_test.dart` and run `flutter test --update-goldens test/golden/`.
