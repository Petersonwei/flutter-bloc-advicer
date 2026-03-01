# Equatable in BLoC: Compare by Data, Not by Memory Address

Reference:
- See [0076_bloc_state_management_guide.md](./0076_bloc_state_management_guide.md) for the base BLoC concepts.
- See [0077_advicer_page_bloc_integration_guide.md](./0077_advicer_page_bloc_integration_guide.md) for UI + BLoC wiring.

## Conceptual Overview (Why we made this change)

By default, Dart compares two objects by instance identity (where they live in memory), not by internal field values.

That means these two can be treated as different:
- `AdvicerStateLoaded(advice: 'Great advice!')`
- `AdvicerStateLoaded(advice: 'Great advice!')`

Even though the text is the same, they are two separate objects.

Why this hurts:
- In tests, we often assert exact emitted states.
- Without value-based comparison, assertions fail for the wrong reason.

Analogy:
- Instance comparison is like checking whether two books are the exact same physical copy.
- Value comparison is checking whether both books contain the same content.

`equatable` gives us value comparison, which is what we want for BLoC states/events.

## Syntax Breakdown (Simple explanations)

- `equatable` package
  - A utility package that makes object equality depend on fields you choose.

- `extends Equatable`
  - Tells Dart to use Equatable rules for `==` and `hashCode`.

- `props`
  - A getter returning a list of fields to compare.
  - If `props` is empty, all instances of that class are equal (as long as class type is the same).

- `const` constructor
  - Marks objects as immutable-friendly and compile-time friendly.
  - Common and recommended for state/event classes.

- `List<Object?>`
  - `Object?` allows nullable or non-null values in comparison lists.

## Code Walkthrough (Updated implementation with comments)

```dart
// pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  equatable: ^2.0.7 // NEW: enables value-based equality for classes
  flutter_bloc: ^9.1.1
  provider: ^6.1.5
```

```dart
// lib/2_application/pages/advicer/bloc/advicer_bloc.dart
import 'package:equatable/equatable.dart'; // NEW import so part files can use Equatable
import 'package:flutter_bloc/flutter_bloc.dart';

part 'advicer_event.dart';
part 'advicer_state.dart';

class AdvicerBloc extends Bloc<AdvicerEvent, AdvicerState> {
  AdvicerBloc() : super(const AdvicerInitial()) {
    on<AdvicerRequestedEvent>(_onAdvicerRequestedEvent);
  }

  Future<void> _onAdvicerRequestedEvent(
    AdvicerRequestedEvent event,
    Emitter<AdvicerState> emit,
  ) async {
    emit(const AdvicerStateLoading());

    try {
      await Future<void>.delayed(const Duration(seconds: 3));
      emit(const AdvicerStateLoaded(advice: 'Fake advice to test bloc'));
    } catch (_) {
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
// lib/2_application/pages/advicer/bloc/advicer_state.dart
part of 'advicer_bloc.dart';

// Base state now extends Equatable.
// This means all child states can be compared by values in "props".
sealed class AdvicerState extends Equatable {
  const AdvicerState();

  // Base class has no shared data fields to compare.
  @override
  List<Object?> get props => [];
}

// No data fields -> empty props is enough.
final class AdvicerInitial extends AdvicerState {
  const AdvicerInitial();
}

// No data fields -> empty props is enough.
final class AdvicerStateLoading extends AdvicerState {
  const AdvicerStateLoading();
}

// This state carries data (advice text), so include it in props.
final class AdvicerStateLoaded extends AdvicerState {
  const AdvicerStateLoaded({required this.advice});

  // This variable holds the loaded advice string.
  final String advice;

  // Equatable compares this list.
  // If two states have the same advice text, they are considered equal.
  @override
  List<Object?> get props => [advice];
}

// This state carries error text, so include message in props.
final class AdvicerStateError extends AdvicerState {
  const AdvicerStateError({required this.message});

  // This variable holds the user-facing error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
```

```dart
// lib/2_application/pages/advicer/bloc/advicer_event.dart
part of 'advicer_bloc.dart';

// Base event also extends Equatable (future-proofing).
sealed class AdvicerEvent extends Equatable {
  const AdvicerEvent();

  // Current shared event data: none.
  @override
  List<Object?> get props => [];
}

// This event currently has no payload, so empty props is fine.
final class AdvicerRequestedEvent extends AdvicerEvent {
  const AdvicerRequestedEvent();
}
```

## Data Flow Impact (What changes in app behavior)

BLoC flow stays the same:
1. User triggers `AdvicerRequestedEvent`.
2. BLoC emits `Loading`, then `Loaded` or `Error`.

What improves:
1. State/event equality is now value-based.
2. Test assertions become reliable and readable.
3. Debugging duplicate states/events is easier to reason about.

## Best Practices (Why this is the Flutter way)

1. Keep state and event classes immutable (`const` constructors, final fields).
2. Put only meaningful fields in `props`.
3. Use empty `props` for stateless event/state classes.
4. Extend Equatable on base classes so every subclass follows one consistent rule.
5. Prefer value-based equality for BLoC-driven architecture, especially for testing.

## Quick Example Test Mindset

Without Equatable:
- Two loaded states with the same advice might fail `==` comparison.

With Equatable:
- They compare by `advice` and pass when values match.

That is exactly why this small change has a big impact on BLoC test quality.
