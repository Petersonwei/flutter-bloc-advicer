# Introduction to Cubit: Migrating from Event-Based BLoC to Function-Based State Changes

This guide explains the recent code change where your `Advicer` feature moved to **Cubit** style state management.

References:
- [0076_bloc_state_management_guide.md](./0076_bloc_state_management_guide.md)
- [0077_advicer_page_bloc_integration_guide.md](./0077_advicer_page_bloc_integration_guide.md)
- [0078_equatable_for_bloc_events_and_states.md](./0078_equatable_for_bloc_events_and_states.md)

## Conceptual Overview (Why this change)

Think of state management like ordering food:
- **BLoC way:** You fill an order form (Event), hand it to staff, then wait for status updates (State).
- **Cubit way:** You directly tell the chef what to do by calling a function, then still receive status updates (State).

Both approaches are valid and both come from `flutter_bloc`.

Why Cubit was a good fit here:
1. Your flow is simple: one action (`Get Advice`) and a few states (`Initial`, `Loading`, `Loaded`, `Error`).
2. Cubit removes Event-class boilerplate.
3. Code becomes easier to read for beginners while keeping clean architecture.

## What changed in this project

1. Added a new Cubit folder and files:
- `lib/2_application/pages/advicer/cubit/advicer_cubit.dart`
- `lib/2_application/pages/advicer/cubit/advicer_state.dart`

2. Updated UI wiring in `advicer_page.dart`:
- `BlocProvider` now creates `AdvicerCubit` instead of `AdvicerBloc`.
- `BlocBuilder` now listens to `AdvicerCubit`.

3. Updated button action in `custom_button.dart`:
- Old BLoC style: `.add(AdvicerRequestedEvent())`
- New Cubit style: `.adviceRequested()`

## Syntax Breakdown

- `class AdvicerCubit extends Cubit<AdvicerState>`
  - Creates a Cubit that emits `AdvicerState` objects.

- `super(const AdvicerInitial())`
  - Sets the starting state when Cubit is created.

- `Future<void> adviceRequested() async`
  - Normal Dart function (not an Event class).
  - `async` allows waiting for asynchronous work.

- `emit(...)`
  - Pushes a new state to listeners (UI).

- `BlocProvider`
  - Makes Cubit available to widgets below it in the tree.

- `BlocBuilder<AdvicerCubit, AdvicerState>`
  - Rebuilds UI whenever Cubit emits a new state.

- `BlocProvider.of<AdvicerCubit>(context).adviceRequested()`
  - Reads Cubit instance from context and calls its function directly.

- `Equatable` + `props`
  - Keeps value-based equality for states, useful for tests.

## Code Walkthrough (Updated implementation with extensive comments)

```dart
// lib/2_application/pages/advicer/cubit/advicer_state.dart
import 'package:equatable/equatable.dart';

// Base class for all states emitted by AdvicerCubit.
sealed class AdvicerState extends Equatable {
  const AdvicerState();

  // Default comparison list (empty for base class).
  @override
  List<Object?> get props => [];
}

// Initial UI state before user taps anything.
final class AdvicerInitial extends AdvicerState {
  const AdvicerInitial();
}

// Loading state while simulated request is running.
final class AdvicerStateLoading extends AdvicerState {
  const AdvicerStateLoading();
}

// Success state with payload.
final class AdvicerStateLoaded extends AdvicerState {
  const AdvicerStateLoaded({required this.advice});

  // This variable stores the advice text shown in UI.
  final String advice;

  // Include advice in props so equality uses the value.
  @override
  List<Object?> get props => [advice];
}

// Error state with payload.
final class AdvicerStateError extends AdvicerState {
  const AdvicerStateError({required this.message});

  // This variable stores an error message for the UI.
  final String message;

  // Include message in props for value-based equality.
  @override
  List<Object?> get props => [message];
}
```

```dart
// lib/2_application/pages/advicer/cubit/advicer_cubit.dart
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Cubit emits AdvicerState values.
class AdvicerCubit extends Cubit<AdvicerState> {
  // Start in initial state.
  AdvicerCubit() : super(const AdvicerInitial());

  // This is the main action method called by the UI button.
  // Unlike BLoC, we do NOT create an Event class for this.
  Future<void> adviceRequested() async {
    // 1) Tell UI to show loading spinner.
    emit(const AdvicerStateLoading());

    try {
      // 2) Simulate network/business logic delay.
      await Future<void>.delayed(const Duration(seconds: 3));

      // 3) Emit success state with advice payload.
      emit(const AdvicerStateLoaded(advice: 'Fake advice from Cubit'));
    } catch (_) {
      // 4) Emit error state if something fails.
      emit(
        const AdvicerStateError(
          message: 'Oops, something went wrong. Please try again.',
        ),
      );
    }
  }
}
```

```dart
// lib/2_application/pages/advicer/advicer_page.dart
import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/core/widgets/custom_button.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:advicer/2_application/pages/advicer/widgets/error_message.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvicerPageWrapperProvider extends StatelessWidget {
  const AdvicerPageWrapperProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Provide Cubit to all widgets under AdvicerPage.
      create: (context) => AdvicerCubit(),
      child: const AdvicerPage(),
    );
  }
}

class AdvicerPage extends StatelessWidget {
  const AdvicerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advicer'),
        actions: [
          Switch(
            value: themeService.isDarkMode,
            onChanged: (_) => context.read<ThemeService>().toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                // Rebuild UI whenever AdvicerCubit emits a new state.
                child: BlocBuilder<AdvicerCubit, AdvicerState>(
                  builder: (context, state) {
                    if (state is AdvicerInitial) {
                      return const Text(
                        'Your advice is waiting for you',
                        textAlign: TextAlign.center,
                      );
                    } else if (state is AdvicerStateLoading) {
                      return const CircularProgressIndicator(
                        color: AppTheme.actionColor,
                      );
                    } else if (state is AdvicerStateLoaded) {
                      return AdviceField(advice: state.advice);
                    } else if (state is AdvicerStateError) {
                      return ErrorMessage(message: state.message);
                    }

                    // Fallback for unexpected state.
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: const CustomButton(text: 'Get Advice'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/2_application/core/widgets/custom_button.dart
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        // BIG CUBIT DIFFERENCE:
        // We call a regular method directly, instead of bloc.add(Event()).
        BlocProvider.of<AdvicerCubit>(context).adviceRequested();
      },
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

## Data Flow (How it works now)

1. User taps **Get Advice**.
2. Button calls `adviceRequested()` on `AdvicerCubit`.
3. Cubit emits `AdvicerStateLoading`.
4. UI shows spinner via `BlocBuilder`.
5. Cubit emits `AdvicerStateLoaded` or `AdvicerStateError`.
6. UI automatically updates to advice text or error message.

## Best Practices (Why this is the Flutter way)

1. Keep UI focused on rendering, not business logic.
2. Use Cubit for simple flows to reduce boilerplate.
3. Keep states explicit (`Initial`, `Loading`, `Loaded`, `Error`) for readable UI logic.
4. Use `Equatable` for test-friendly value comparisons.
5. Provide Cubit near the page that uses it to keep scope clean.

## Summary

Your app now uses a cleaner Cubit approach:
- Same state power as before.
- Less ceremony than event-based BLoC.
- Clear path for scaling later (you can move back to full BLoC only if complexity grows).
