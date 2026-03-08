# Integration Testing: End-to-End Advice Flow (with Debug SSL Bypass)

## 1) What changed (verified with Git)

### `git status --short`

```bash
 M ios/Flutter/Debug.xcconfig
 M ios/Flutter/Release.xcconfig
 M ios/Runner.xcodeproj/project.pbxproj
 M ios/Runner.xcworkspace/contents.xcworkspacedata
 M lib/main.dart
 M macos/Flutter/Flutter-Debug.xcconfig
 M macos/Flutter/Flutter-Release.xcconfig
 M pubspec.lock
 M pubspec.yaml
?? integration_test/
?? ios/Podfile
?? ios/Podfile.lock
?? macos/Podfile
```

### `git diff --stat`

```bash
ios/Flutter/Debug.xcconfig                      |   1 +
ios/Flutter/Release.xcconfig                    |   1 +
ios/Runner.xcodeproj/project.pbxproj            | 112 ++++++++++++++++++++++++
ios/Runner.xcworkspace/contents.xcworkspacedata |   3 +
lib/main.dart                                   |  22 ++++-
macos/Flutter/Flutter-Debug.xcconfig            |   1 +
macos/Flutter/Flutter-Release.xcconfig          |   1 +
pubspec.lock                                    |  47 ++++++++++
pubspec.yaml                                    |   2 +
9 files changed, 187 insertions(+), 3 deletions(-)
```

### New source file added

- `integration_test/app_test.dart`

### Why there are extra iOS/macOS file changes

Running integration tests triggered CocoaPods + workspace updates (`Podfile`, `Podfile.lock`, Xcode project/workspace references). These are tooling-generated and common when enabling/running integration tests on Apple platforms.

---

## 2) Conceptual Overview (Why this was added)

You already wrote unit tests and widget tests. Integration testing is the next layer: it checks that the app works **end-to-end**.

Think of it like this:
- Unit test = test one Lego piece.
- Widget test = test a small Lego section.
- Integration test = test the full Lego model while pressing real buttons.

Here, we test the real app startup, tap the **Get Advice** button, and verify the UI reaches the loaded state (`AdviceField`).

Because your API currently has certificate issues, debug TLS override was temporarily enabled so local test flows can still run.

---

## 3) Syntax Breakdown (Simple explanations)

- `integration_test` (package): Flutter’s official package for end-to-end app testing.
- `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`: prepares Flutter test binding for integration runs.
- `app.main()`: starts your real app from test code.
- `tester.pumpAndSettle()`: waits until UI settles.
- `tester.tap(...)`: simulates a real user tap.
- `find.text(...)` / `find.byType(...)`: finds widgets on screen.
- `expect(..., findsOneWidget)`: asserts exactly one matching widget exists.
- `kDebugMode`: true only in debug builds.
- `HttpOverrides`: lets you customize HTTP behavior globally (used here only for debug certificate bypass).

---

## 4) Code Walkthrough (updated implementation)

```dart
// File: pubspec.yaml (dev_dependencies section)
// We add integration_test so Flutter can run integration tests.
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

```dart
// File: lib/main.dart

import 'dart:io'; // Needed for HttpOverrides and HttpClient.

import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/pages/advicer/advicer_page.dart';
import 'package:advicer/injection.dart' as di;
import 'package:advicer/theme.dart';
import 'package:flutter/foundation.dart'; // Needed for kDebugMode.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  // DEBUG ONLY: If API SSL certificate is invalid/expired,
  // this allows local simulator/device testing to continue.
  // Never keep this enabled for production release builds.
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }

  // Make sure Flutter engine/bindings are ready before async setup.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection container.
  await di.init();

  // Start app with ThemeService provider at top level.
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const AdvicerApp(),
    ),
  );
}

// Global debug HTTP override class.
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    // Accept bad cert only for known course API hosts.
    client.badCertificateCallback = (cert, host, port) {
      return host == 'api.flutter-community.de' ||
          host == 'api.flutter-community.com';
    };

    return client;
  }
}
```

```dart
// File: integration_test/app_test.dart

import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:advicer/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // Required for integration test environment setup.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('tap on custom button, verify advice will be loaded', (
      tester,
    ) async {
      // Start real app entrypoint.
      app.main();

      // Wait for initial app rendering + startup async work.
      await tester.pumpAndSettle();

      // 1) Verify initial state text is shown.
      expect(find.text('Your advice is waiting for you'), findsOneWidget);

      // 2) Find and tap the real button as a user would do.
      final customButtonFinder = find.text('Get Advice');
      expect(customButtonFinder, findsOneWidget);

      await tester.tap(customButtonFinder);

      // 3) Wait for network + state transition.
      // We use polling because some Flutter SDK versions don't support
      // timeout named param on pumpAndSettle.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));

        // Break early once loaded UI appears.
        if (find.byType(AdviceField).evaluate().isNotEmpty) {
          break;
        }
      }

      // 4) Final assert: advice content widget should be visible.
      expect(find.byType(AdviceField), findsOneWidget);
    });
  });
}
```

---

## 5) Best Practices (Flutter way)

- Keep integration tests in `integration_test/` (separate from fast unit/widget tests).
- Test real user actions (`tap`, navigation, text visibility), not internals.
- Use stable finders (`byType` where useful) to reduce test fragility.
- Keep TLS bypass strictly debug-only and temporary.
- In CI/CD, run integration tests on schedule or protected pipelines because they are slower.

---

## 6) How to run

```bash
# Install deps
flutter pub get

# Run only integration tests folder
flutter test integration_test

# Or run this specific test
flutter test integration_test/app_test.dart
```

If SSL problems return, confirm debug mode is active and the host in `DevHttpOverrides` matches the API domain exactly.
