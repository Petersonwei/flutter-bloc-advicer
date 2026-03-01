# State Management with BLoC in Flutter

This guide explains the recent BLoC setup changes in your project in plain English.

Reference: your earlier UI guide is in `docs/flutter_beginner_guide_application_layer.md`. This file continues from that point and focuses on state management.

## Conceptual Overview (Why we added BLoC)

Before this change, your page used a **manual preview enum** to fake states (`initial`, `loading`, `success`, `error`).

That works for UI design, but real apps need a clear flow:
1. User clicks button.
2. App starts loading.
3. App either returns data or an error.

BLoC gives that flow a clean structure.

Think of it like a restaurant:
1. **Event** = customer order.
2. **BLoC logic** = kitchen process.
3. **State** = dish status shown on screen (`preparing`, `served`, `failed`).

This keeps UI widgets simple and moves decision-making to one predictable place.

## What changed in this project

### 1) New dependency
In `pubspec.yaml`:
- Added `flutter_bloc: ^9.1.1`

Why: This package gives us `Bloc`, `on<Event>`, `emit(...)`, `BlocBuilder`, etc.

### 2) New BLoC files
Created folder: `lib/2_application/pages/advicer/bloc/`

Files:
1. `advicer_event.dart` (inputs to bloc)
2. `advicer_state.dart` (outputs from bloc)
3. `advicer_bloc.dart` (business flow: event -> state)

## Syntax Breakdown (simple explanations)

### `class X extends Bloc<Event, State>`
```dart
class AdvicerBloc extends Bloc<AdvicerEvent, AdvicerState>
```
- `AdvicerEvent` = all possible inputs.
- `AdvicerState` = all possible outputs.

### `on<Event>((event, emit) async { ... })`
- Registers an event handler.
- Runs when that event is added to the bloc.
- `emit(...)` pushes new state to UI listeners.

### `async/await`
- `async` means the function can pause for async work.
- `await` waits for work to finish (e.g., API call or `Future.delayed`).

### `sealed class`
```dart
sealed class AdvicerState {}
```
- Means this is a base class meant for a fixed family of child types.
- Good for predictable state modeling.

### `part` and `part of`
In `advicer_bloc.dart`:
```dart
part 'advicer_event.dart';
part 'advicer_state.dart';
```
In event/state files:
```dart
part of 'advicer_bloc.dart';
```
- Splits one logical unit into multiple files.
- Common style in bloc-generated structure.

### `super(AdvicerInitial())`
- Sets starting state when bloc is created.

### `final`
- Value set once, then read-only.
- Example: `final String advice;`

## Full Code Walkthrough (with beginner comments)

### `advicer_bloc.dart`
```dart
import 'package:flutter_bloc/flutter_bloc.dart';

// These two files become part of this bloc library.
part 'advicer_event.dart';
part 'advicer_state.dart';

// Bloc<EventType, StateType>
// Means: this bloc accepts AdvicerEvent and outputs AdvicerState.
class AdvicerBloc extends Bloc<AdvicerEvent, AdvicerState> {
  // Constructor
  // super(...) defines the first state the UI should see.
  AdvicerBloc() : super(AdvicerInitial()) {
    // Whenever AdvicerRequestedEvent is added, run this method.
    on<AdvicerRequestedEvent>(_onAdvicerRequestedEvent);
  }

  // Event handler method
  // Future<void> + async because we simulate network delay.
  Future<void> _onAdvicerRequestedEvent(
    AdvicerRequestedEvent event,
    Emitter<AdvicerState> emit,
  ) async {
    // 1) Immediately tell UI: we are loading now.
    emit(AdvicerStateLoading());

    try {
      // 2) Fake backend delay (later this becomes repository/API call).
      await Future<void>.delayed(const Duration(seconds: 3));

      // 3) Success state with data payload (advice text).
      emit(AdvicerStateLoaded(advice: 'Fake advice to test bloc'));
    } catch (_) {
      // 4) Error fallback state if something fails.
      emit(
        AdvicerStateError(
          message: 'Oops, something went wrong. Please try again.',
        ),
      );
    }
  }
}
```

### `advicer_event.dart`
```dart
part of 'advicer_bloc.dart';

// Base class for all possible user/system events for this bloc.
sealed class AdvicerEvent {}

// Event fired when user requests advice (button click).
final class AdvicerRequestedEvent extends AdvicerEvent {}
```

### `advicer_state.dart`
```dart
part of 'advicer_bloc.dart';

// Base class for all UI states this bloc can emit.
sealed class AdvicerState {}

// Initial screen state (before user does anything).
final class AdvicerInitial extends AdvicerState {}

// Loading state (show spinner).
final class AdvicerStateLoading extends AdvicerState {}

// Success state (show advice text).
final class AdvicerStateLoaded extends AdvicerState {
  // Required value means UI always gets actual advice text.
  AdvicerStateLoaded({required this.advice});

  final String advice;
}

// Error state (show error message).
final class AdvicerStateError extends AdvicerState {
  // Required value means UI always gets a real message.
  AdvicerStateError({required this.message});

  final String message;
}
```

## Data Flow (Step-by-step)

1. UI triggers `AdvicerRequestedEvent`.
2. BLoC receives event in `on<AdvicerRequestedEvent>(...)`.
3. BLoC emits `AdvicerStateLoading`.
4. BLoC waits 3 seconds (fake call).
5. BLoC emits either:
   - `AdvicerStateLoaded(advice: ...)`, or
   - `AdvicerStateError(message: ...)`.
6. UI (next step with `BlocBuilder`) rebuilds based on current state.

## Why this is considered Flutter best practice

1. **Separation of concerns**
   - UI draws widgets.
   - BLoC handles logic and state transitions.

2. **Predictable and testable flow**
   - Given event X, expect states Y -> Z.

3. **Scalable structure**
   - Easy to add more events (refresh, retry, etc.) and states.

4. **Cleaner code reviews and debugging**
   - One place to inspect state transitions.

## How this connects to your previous guide

In `docs/flutter_beginner_guide_application_layer.md`, the page used `_previewState` to manually switch widgets.

Now you have the real state engine.

Next integration step (when you want):
1. Provide `AdvicerBloc` above `AdvicerPage` (using `BlocProvider`).
2. Replace manual `_previewState` with `BlocBuilder<AdvicerBloc, AdvicerState>`.
3. Dispatch `AdvicerRequestedEvent` from the button tap.

That will make your UI fully reactive to real BLoC states.
