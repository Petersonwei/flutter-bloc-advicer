# Advicer

Clean-architecture Flutter app that fetches advice from a remote API and demonstrates:
- Cubit state management (`flutter_bloc`)
- Domain/Data/Application layer separation
- Functional error handling (`dartz` + `Either`)
- Dependency injection (`get_it`)
- Unit/widget/golden/integration testing

## Project Structure

```text
lib/
  1_domain/
  2_application/
  3_data/
  injection.dart
  main.dart

test/
integration_test/
docs/
```

## Requirements

- Flutter stable (check with `flutter --version`)
- Dart SDK compatible with `pubspec.yaml`
- Xcode/iOS Simulator for iOS runs

## Setup

```bash
flutter pub get
flutter analyze
```

Run app:

```bash
flutter run -d "iPhone 16"
```

## Testing

Run all unit/widget tests:

```bash
flutter test
```

Run integration tests only:

```bash
flutter test integration_test
```

Run one integration test file:

```bash
flutter test integration_test/app_test.dart
```

Update golden files:

```bash
flutter test test/2_application/pages/advicer/widgets/custom_button_golden_test.dart --update-goldens
```

## Current SSL/API Note (Debug)

The course API certificate may be invalid/expired at times.

For local debug testing, `lib/main.dart` currently includes a **debug-only** `HttpOverrides` bypass behind `kDebugMode`.

Important:
- Keep this for local debug only.
- Do **not** ship certificate bypass logic to production/App Store builds.

## Flutter Version Updates (Important)

Before following any upgrade tutorial, always check:

1. Your installed version:
```bash
flutter --version
```
2. Official release notes:
- https://docs.flutter.dev/release/release-notes
3. Project health:
```bash
flutter analyze
flutter test
flutter test integration_test
```

Detailed upgrade/check playbook:
- [`docs/0095_flutter_update_check_and_upgrade_playbook.md`](docs/0095_flutter_update_check_and_upgrade_playbook.md)

## Docs

Step-by-step guides for this project are under `docs/`.
