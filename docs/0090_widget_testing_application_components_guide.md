# Widget Testing the Application UI: `AdviceField`, `CustomButton`, and `AdvicerPage`

This guide explains the latest widget-testing changes and the small UI refactors made for testability.

References:
- [0089_unit_testing_application_layer_bloc_cubit_guide.md](./0089_unit_testing_application_layer_bloc_cubit_guide.md)
- [0088_unit_testing_usecases_guide.md](./0088_unit_testing_usecases_guide.md)

## 1) Changes Verified with `git status` and `git diff`

### `git status` showed:
- Modified:
  - `lib/2_application/core/widgets/custom_button.dart`
  - `lib/2_application/pages/advicer/widgets/advice_field.dart`
  - `lib/2_application/pages/advicer/advicer_page.dart`
- New:
  - `test/2_application/pages/advicer/widgets/advice_field_widget_test.dart`
  - `test/2_application/pages/advicer/widgets/custom_button_widget_test.dart`
  - `test/2_application/pages/advicer/advicer_page_widget_test.dart`

### `git diff` showed:
- `CustomButton` changed from Cubit-coupled tap action to callback-based `onTap`.
- `AdviceField` now has `emptyAdvice` fallback for empty text.
- `AdvicerPage` now passes callback to `CustomButton` (`context.read<AdvicerCubit>().adviceRequested()`).

## 2) Conceptual Overview (Why these changes)

Widget tests become easier and cleaner when UI widgets are as “dumb” as possible.

Before:
- `CustomButton` directly accessed Cubit internally.
- Harder to test button tap behavior in isolation.

After:
- `CustomButton` receives a callback from parent.
- Parent decides business action.
- Button becomes reusable and easy to test.

Analogy:
- A remote control button should only send a signal.
- It should not contain the whole TV logic inside itself.

## 3) Syntax Breakdown (Beginner-friendly)

- `testWidgets(...)`
  - Flutter test function for widget behavior.

- `WidgetTester`
  - Utility to pump UI, tap widgets, find text/types, etc.

- `pumpWidget(...)`
  - Builds the test widget tree.

- `pumpAndSettle()`
  - Waits for frames/animations to settle.

- `find.text(...)`, `find.textContaining(...)`, `find.byType(...)`
  - Finders used to locate UI elements.

- `tester.widget<T>(finder)`
  - Accesses widget instance and its public fields.

- `whenListen(...)` + `MockCubit`
  - Simulates Cubit state stream in widget tests.

- `BlocProvider.value(...)`
  - Injects existing mock cubit into widget tree.

- `ChangeNotifierProvider(...)`
  - Provides required `ThemeService` dependency for page test.

## 4) Code Walkthrough (with extensive comments)

```dart
// lib/2_application/core/widgets/custom_button.dart
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.text,
    this.onTap, // NEW: callback comes from parent
    super.key,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      // CHANGED:
      // Button no longer knows about Cubit directly.
      // It just executes callback if parent provides one.
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
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
// lib/2_application/pages/advicer/widgets/advice_field.dart
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';

class AdviceField extends StatelessWidget {
  const AdviceField({
    required this.advice,
    super.key,
  });

  // NEW fallback text for empty advice case.
  static const emptyAdvice = 'No advice available yet.';

  final String advice;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).colorScheme.primary,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.iconColor.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          // CHANGED:
          // Empty input now renders a friendly fallback string.
          advice.isNotEmpty ? '"$advice"' : emptyAdvice,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                height: 1.35,
              ),
        ),
      ),
    );
  }
}
```

```dart
// lib/2_application/pages/advicer/advicer_page.dart (relevant part)
SizedBox(
  width: double.infinity,
  height: 56,
  child: CustomButton(
    text: 'Get Advice',
    // Parent owns business logic.
    // Button only receives callback.
    onTap: () => context.read<AdvicerCubit>().adviceRequested(),
  ),
),
```

```dart
// test/2_application/pages/advicer/widgets/advice_field_widget_test.dart
// Highlights:
// - tests short text, long text, empty text fallback
// - uses tester.widget<AdviceField>(...) to read `advice` field directly
```

```dart
// test/2_application/pages/advicer/widgets/custom_button_widget_test.dart
// Highlights:
// - verifies label appears
// - verifies callback called exactly once on tap (Mocktail verify)
```

```dart
// test/2_application/pages/advicer/advicer_page_widget_test.dart
// Highlights:
// - uses MockCubit + whenListen to simulate page view states
// - wraps page with required providers:
//   1) ChangeNotifierProvider<ThemeService>
//   2) BlocProvider<AdvicerCubit>.value(mock)
// - verifies each state renders expected widget:
//   initial text, loading spinner, AdviceField, ErrorMessage
```

## 5) Best Practices (Why this is the Flutter way)

1. Keep reusable widgets business-logic-agnostic (callback in, action out).
2. Wrap test widgets with only required dependencies (MaterialApp, providers).
3. Test UI states explicitly using mocked Cubit streams.
4. Use finders + widget instance access for both visual and data assertions.
5. Prefer small focused widget tests over one huge end-to-end test.

## 6) Quick takeaway

You now have:
- component-level widget tests (`AdviceField`, `CustomButton`)
- page-level state-view tests (`AdvicerPage` with Cubit states)
- cleaner UI architecture through callback-based button design

This gives you faster feedback when refactoring UI and state-render logic.
