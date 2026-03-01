# Flutter Beginner Guide: Application Layer UI (This Project)


## 1. Big Picture

You currently have:
1. A root app (`main.dart`) that sets up `Provider` and theme switching.
2. A page (`AdvicerPage`) that shows UI only (no real API/business logic yet).
3. Small reusable widgets (`CustomButton`, `AdviceField`, `ErrorMessage`).
4. A theme state service (`ThemeService`) that controls dark/light mode.

## 2. Folder Structure and Why It Exists

```text
lib/
  0_data/                      # Data layer (APIs, local DB) - not built yet
  1_domain/                    # Domain layer (business rules) - not built yet
  2_application/               # UI + state management
    core/
      services/
        theme_service.dart     # app-wide theme state
      widgets/
        custom_button.dart     # reusable widget for many pages
    pages/
      advicer/
        advicer_page.dart      # the page layout
        widgets/
          advice_field.dart    # used only by AdvicerPage
          error_message.dart   # used only by AdvicerPage
  main.dart
  theme.dart
```

Rule of thumb:
1. `core/widgets`: reusable in multiple pages.
2. `pages/<page_name>/widgets`: specific to one page.

## 3. Dart Syntax Basics Used Here

## `import`
```dart
import 'package:flutter/material.dart';
```
Loads code from another file/package.

## `class ... extends StatelessWidget`
```dart
class AdvicerPage extends StatelessWidget {
```
Creates a UI widget with no internal mutable state.

## `const`
```dart
const AdvicerPage({super.key});
```
`const` tells Dart this object can be compile-time constant (better performance and rebuild behavior).

## Named parameters with `required`
```dart
const AdviceField({required this.advice, super.key});
```
When creating `AdviceField`, caller must pass `advice`.

## Nullable type `?`
```dart
final VoidCallback? onTap;
```
`onTap` can be null or a function.

## Arrow syntax `=>`
```dart
bool get isDarkMode => _currentThemeMode == ThemeMode.dark;
```
Short function/getter for single-expression return.

## Private names with `_`
```dart
enum _AdvicerUiState { ... }
```
Leading underscore means private to this file.

## 4. `main.dart` Explained

File: `lib/main.dart`

```dart
import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/pages/advicer/advicer_page.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const AdvicerApp(),
    ),
  );
}
```

What this does:
1. `runApp(...)` starts Flutter UI.
2. `ChangeNotifierProvider` creates one `ThemeService` and shares it with all child widgets.
3. `create: (_) => ThemeService()` means instantiate service once.
4. `child: AdvicerApp()` is your real app.

Then:

```dart
return Consumer<ThemeService>(
  builder: (context, themeService, child) => MaterialApp(
    title: 'Advicer',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: themeService.currentThemeMode,
    home: const AdvicerPage(),
  ),
);
```

What this does:
1. `Consumer<ThemeService>` listens to theme changes.
2. When theme changes, `MaterialApp` rebuilds with new `themeMode`.
3. `home` is the first screen (`AdvicerPage`).

## 5. `theme_service.dart` Explained

File: `lib/2_application/core/services/theme_service.dart`

```dart
class ThemeService extends ChangeNotifier {
  ThemeMode _currentThemeMode = ThemeMode.system;

  ThemeMode get currentThemeMode => _currentThemeMode;
  bool get isDarkMode => _currentThemeMode == ThemeMode.dark;
```

1. `ChangeNotifier` gives `notifyListeners()`.
2. Private field `_currentThemeMode` stores current mode.
3. Getters expose read-only values to UI.

```dart
  void setThemeMode(ThemeMode mode) {
    if (_currentThemeMode == mode) {
      return;
    }

    _currentThemeMode = mode;
    notifyListeners();
  }
```

1. Guard clause avoids unnecessary rebuild.
2. `notifyListeners()` tells Provider listeners to rebuild.

```dart
  void toggleTheme() {
    _currentThemeMode =
        _currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
```

Ternary operator syntax:
`condition ? value_if_true : value_if_false`

## 6. `advicer_page.dart` Explained

File: `lib/2_application/pages/advicer/advicer_page.dart`

### A) Preview state enum

```dart
static const _previewState = _AdvicerUiState.initial;

enum _AdvicerUiState {
  initial,
  loading,
  success,
  error,
}
```

This is temporary UI preview logic. Change `initial` to other values to preview each state.

### B) Getting provider value

```dart
final themeService = context.watch<ThemeService>();
```

1. `watch` means rebuild this widget when `ThemeService` changes.
2. Use this for values displayed in UI.

### C) AppBar switch

```dart
Switch(
  value: themeService.isDarkMode,
  onChanged: (_) => context.read<ThemeService>().toggleTheme(),
),
```

1. `value` controls switch on/off state.
2. `onChanged` runs when user toggles.
3. `read` gets provider without subscribing to rebuilds.

### D) Body layout

```dart
Column(
  children: [
    Expanded(
      child: Center(
        child: _buildStateArea(context),
      ),
    ),
    SizedBox(
      width: double.infinity,
      height: 56,
      child: CustomButton(...),
    ),
    const SizedBox(height: 24),
  ],
)
```

1. `Expanded` takes remaining vertical space.
2. Button area has fixed height.
3. This matches your design: dynamic top content + fixed bottom CTA.

### E) State area switch

```dart
switch (_previewState) {
  case _AdvicerUiState.initial:
    return const Text('Your advice is waiting for you');
  case _AdvicerUiState.loading:
    return const CircularProgressIndicator(color: AppTheme.actionColor);
  case _AdvicerUiState.success:
    return const AdviceField(advice: '...');
  case _AdvicerUiState.error:
    return const ErrorMessage(message: '...');
}
```

This is how one area returns different widgets depending on state.

## 7. `custom_button.dart` Explained

File: `lib/2_application/core/widgets/custom_button.dart`

```dart
class CustomButton extends StatelessWidget {
  const CustomButton({required this.text, super.key, this.onTap});

  final String text;
  final VoidCallback? onTap;
```

1. Reusable button widget.
2. Accepts button text and optional tap callback.

```dart
return InkResponse(
  onTap: onTap,
  radius: 28,
  splashColor: AppTheme.actionColor.withValues(alpha: 0.2),
  highlightColor: Colors.transparent,
  child: Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(16),
    color: AppTheme.actionColor,
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(...),
    ),
  ),
);
```

Why this composition:
1. `InkResponse`: tap + ripple effect.
2. `Material`: elevation and proper material rendering.
3. `Container`: spacing and size behavior.
4. `Text`: visual label with themed style.

## 8. `advice_field.dart` Explained

File: `lib/2_application/pages/advicer/widgets/advice_field.dart`

```dart
Text(
  '"$advice"',
  textAlign: TextAlign.center,
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    fontSize: 22,
    height: 1.35,
  ),
)
```

1. `"$advice"` uses string interpolation and quote escaping.
2. `Theme.of(context)` reads active theme.
3. `?.copyWith(...)` safely modifies text style if not null.

## 9. `error_message.dart` Explained

File: `lib/2_application/pages/advicer/widgets/error_message.dart`

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const Icon(Icons.error, color: Colors.red, size: 56),
    const SizedBox(height: 16),
    Text(message, textAlign: TextAlign.center),
  ],
)
```

1. Vertical icon + text stack.
2. `mainAxisSize: MainAxisSize.min` keeps column only as tall as content.

## 10. Commented Mini Example (What to write as a beginner)

```dart
class ExampleCard extends StatelessWidget {
  const ExampleCard({required this.title, super.key});

  // final = set once, then read-only
  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2, // shadow depth
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16), // inner spacing
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
```

## 11. How to Practice Quickly

1. In `advicer_page.dart`, change `_previewState` to `loading`, `success`, `error`, then run app and observe.
2. Change `CustomButton` color and border radius to see visual impact.
3. Add a second reusable widget in `core/widgets` and use it in `AdvicerPage`.
4. Replace `debugPrint(...)` with a temporary `SnackBar` to practice callbacks.

## 12. Next Step (What will replace preview state)

Later with BLoC:
1. Remove `_previewState` enum.
2. Add BLoC states: `Initial`, `Loading`, `Loaded(advice)`, `Error(message)`.
3. Use `BlocBuilder` to return the same 4 UI widgets based on real state.

You already have the correct UI structure for that migration.
