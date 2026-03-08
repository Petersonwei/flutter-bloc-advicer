# Golden Testing the CustomButton (with Stable Font Rendering)

## 1) What changed (verified with `git status` and `git diff`)

### `git status --short`

```bash
 M .gitignore
 M lib/2_application/core/widgets/custom_button.dart
?? test/2_application/pages/advicer/widgets/custom_button_golden_test.dart
?? test/2_application/pages/advicer/widgets/goldens/
?? test/flutter_test_config.dart
```

### `git diff --stat`

```bash
 .gitignore                                        | 1 +
 lib/2_application/core/widgets/custom_button.dart | 8 ++++++--
 2 files changed, 7 insertions(+), 2 deletions(-)
```

### New files added (from status)

- `test/2_application/pages/advicer/widgets/custom_button_golden_test.dart`
- `test/2_application/pages/advicer/widgets/goldens/custom_button/custom_button_enabled.png`
- `test/2_application/pages/advicer/widgets/goldens/custom_button/custom_button_disabled.png`
- `test/flutter_test_config.dart`

---

## 2) Conceptual Overview (Why we changed this)

Think of a golden test like a **before/after photo check** for your UI.

- First run: Flutter saves a “master image” (golden file).
- Later runs: Flutter re-renders the widget and compares pixels.
- If the UI changed unexpectedly, test fails.

We also added a test font loader (`Roboto`) so text rendering is more stable across test runs.

---

## 3) Syntax Breakdown (Beginner-friendly)

- `testWidgets(...)`: Creates a UI test.
- `expectLater(..., matchesGoldenFile(...))`: Compares rendered widget to a PNG golden image.
- `find.byType(CustomButton)`: Finds the `CustomButton` on screen.
- `VoidCallback? onTap`: Nullable function. If null, button is disabled.
- `onTap != null`: Simple enabled/disabled check.
- `FontLoader('Roboto')`: Loads a font for tests.
- `testExecutable(...)`: Global Flutter test hook; runs before tests.
- `Platform.environment['FLUTTER_ROOT']`: Reads SDK location so we can load font files.

---

## 4) Code Walkthrough (Updated implementation with extensive comments)

```dart
// File: lib/2_application/core/widgets/custom_button.dart
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.text,
    this.onTap,
    super.key,
  });

  final String text;

  // If this is null, button is treated as disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // "Enabled" means we actually have a callback to run.
    final isEnabled = onTap != null;

    // Visual feedback for enabled vs disabled state.
    final buttonColor = isEnabled ? AppTheme.actionColor : Colors.red.shade300;
    final textColor = isEnabled ? Colors.white : Colors.black45;

    return InkResponse(
      // If onTap is null, InkResponse will not trigger tap behavior.
      onTap: onTap,
      radius: 28,
      splashColor: AppTheme.actionColor.withValues(alpha: 0.2),
      highlightColor: Colors.transparent,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: buttonColor,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
```

```dart
// File: test/2_application/pages/advicer/widgets/custom_button_golden_test.dart
import 'package:advicer/2_application/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to avoid repeating MaterialApp/Scaffold setup.
Widget widgetUnderTest({VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        // Fixed size keeps screenshot output consistent.
        child: SizedBox(
          width: 220,
          height: 56,
          child: CustomButton(
            text: 'Get Advice',
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Golden test', () {
    group('CustomButton', () {
      testWidgets('is enabled', (tester) async {
        // Enabled state: callback is present.
        await tester.pumpWidget(widgetUnderTest(onTap: () {}));

        // Compare rendered button against stored golden image.
        await expectLater(
          find.byType(CustomButton),
          matchesGoldenFile('goldens/custom_button/custom_button_enabled.png'),
        );
      });

      testWidgets('is disabled', (tester) async {
        // Disabled state: no callback.
        await tester.pumpWidget(widgetUnderTest());

        await expectLater(
          find.byType(CustomButton),
          matchesGoldenFile('goldens/custom_button/custom_button_disabled.png'),
        );
      });
    });
  });
}
```

```dart
// File: test/flutter_test_config.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Global setup hook for ALL tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Load Roboto before tests start, so text rendering is more predictable.
  final roboto = FontLoader('Roboto');
  roboto.addFont(_loadMaterialFont('Roboto-Regular.ttf'));
  await roboto.load();

  // Continue running test suite.
  await testMain();
}

Future<ByteData> _loadMaterialFont(String fontName) async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    throw Exception('FLUTTER_ROOT is not set. Cannot load test font.');
  }

  final fontPath = [
    flutterRoot,
    'bin',
    'cache',
    'artifacts',
    'material_fonts',
    fontName,
  ].join(Platform.pathSeparator);

  final bytes = await File(fontPath).readAsBytes();
  return ByteData.view(bytes.buffer);
}
```

```gitignore
# File: .gitignore
# Golden diff failures are generated artifacts; avoid committing them.
/test/failures/
```

---

## 5) Best Practices (The Flutter way)

- Keep test widget size fixed (`SizedBox`) for stable screenshots.
- Test both visual states (enabled + disabled), not only one.
- Use helper builders (`widgetUnderTest`) to reduce repeated setup.
- Load fonts globally for consistent golden output.
- Ignore generated failure artifacts (`/test/failures/`) in Git.

---

## 6) Quick run commands

```bash
# Update/record golden files
flutter test test/2_application/pages/advicer/widgets/custom_button_golden_test.dart --update-goldens

# Run golden test normally
flutter test test/2_application/pages/advicer/widgets/custom_button_golden_test.dart
```
