# Functional Error Handling with Custom Failures, `Either`, and Cubit `fold()`


Reference guides:
- [0079_cubit_introduction_and_migration_guide.md](./0079_cubit_introduction_and_migration_guide.md)
- [0080_domain_layer_usecases_entities_guide.md](./0080_domain_layer_usecases_entities_guide.md)

## Changes Confirmed via `git diff`

The following files changed in this feature:

1. `pubspec.yaml` (added `dartz`)
2. `lib/1_domain/failures/failures.dart` (new custom failures)
3. `lib/1_domain/repositories/advicer_repo.dart` (returns `Either`)
4. `lib/1_domain/usecases/advicer_usecases.dart` (returns `Either`)
5. `lib/2_application/pages/advicer/cubit/advicer_cubit.dart` (uses `.fold()` and failure-to-message mapping)

## Conceptual Overview (Why this change)

Traditional error handling often uses `try/catch` everywhere. That can become messy and unpredictable as apps grow.

This update introduces a cleaner pattern:
- Represent errors as **typed failure objects** (`ServerFailure`, `CacheFailure`, etc.).
- Return results as **`Either<Failure, Data>`**:
  - `Left` = failure
  - `Right` = success
- Handle both outcomes in one place using `.fold()`.

Analogy:
- Think of `Either` as a package with two possible compartments:
  - Left compartment contains a problem report.
  - Right compartment contains successful data.
- Cubit opens the package and chooses the correct UI response.

## Syntax Breakdown

- `abstract class Failure {}`
  - Base type for all known error categories.

- `class ServerFailure extends Failure {}`
  - Specific error kind; useful for custom UI messages.

- `dartz` package
  - Provides functional types like `Either`, `Left`, and `Right`.

- `Future<Either<Failure, AdvicerEntity>>`
  - Async function that returns either:
    - a `Failure` (error), or
    - an `AdvicerEntity` (success).

- `Right(value)` / `Left(value)`
  - Wrap success in `Right`.
  - Wrap failure in `Left`.

- `.fold(leftFn, rightFn)`
  - Reads an `Either` safely.
  - Runs `leftFn` when it is `Left`.
  - Runs `rightFn` when it is `Right`.

- `switch (failure) { case ServerFailure _: ... }`
  - Pattern matching on failure type to map to a user-friendly message.

## Code Walkthrough (Updated implementation with detailed comments)

```dart
// pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  dartz: ^0.10.1 // NEW: functional programming tools (Either/Left/Right)
  equatable: ^2.0.7
  flutter_bloc: ^9.1.1
  provider: ^6.1.5
```

```dart
// lib/1_domain/failures/failures.dart
// Base type for all domain failures.
abstract class Failure {}

// API-related failure type.
class ServerFailure extends Failure {}

// Local cache/storage failure type.
class CacheFailure extends Failure {}

// Fallback for unknown/unexpected issues.
class GeneralFailure extends Failure {}
```

```dart
// lib/1_domain/repositories/advicer_repo.dart
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:dartz/dartz.dart';

abstract class AdvicerRepo {
  // IMPORTANT CHANGE:
  // Instead of returning only data, repository now returns Either.
  // Left = Failure, Right = AdvicerEntity.
  Future<Either<Failure, AdvicerEntity>> getAdviceFromDataSource();
}
```

```dart
// lib/1_domain/usecases/advicer_usecases.dart
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:dartz/dartz.dart';

class AdvicerUseCases {
  // IMPORTANT CHANGE:
  // Use case now also returns Either<Failure, AdvicerEntity>.
  Future<Either<Failure, AdvicerEntity>> getAdvice() async {
    // Simulate async work.
    await Future<void>.delayed(const Duration(seconds: 3));

    // Fake success path:
    // Wrap entity with Right(...) to signal success.
    return const Right(
      AdvicerEntity(
        advice: 'Fake advice to test',
        id: 1,
      ),
    );

    // Example fake error path (not active now):
    // return Left(ServerFailure());
  }
}
```

```dart
// lib/2_application/pages/advicer/cubit/advicer_cubit.dart
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// User-friendly messages kept as constants for readability and reuse.
const serverFailureMessage = 'Oops, API Error. Please try again.';
const cacheFailureMessage = 'Oops, Cache failed. Please try again.';
const generalFailureMessage = 'Oops, something went wrong. Please try again.';

class AdvicerCubit extends Cubit<AdvicerState> {
  AdvicerCubit() : super(const AdvicerInitial());

  final AdvicerUseCases advicerUseCases = AdvicerUseCases();

  Future<void> adviceRequested() async {
    // Step 1: show loading immediately in UI.
    emit(const AdvicerStateLoading());

    // Step 2: ask use case for result (Either<Failure, AdvicerEntity>).
    final failureOrAdvice = await advicerUseCases.getAdvice();

    // Step 3: handle both outcomes explicitly with fold.
    failureOrAdvice.fold(
      // Left branch: failure happened -> map failure to user message.
      (failure) =>
          emit(AdvicerStateError(message: _mapFailureToMessage(failure))),

      // Right branch: success happened -> extract advice string from entity.
      (advice) => emit(AdvicerStateLoaded(advice: advice.advice)),
    );
  }

  // Converts technical failure types into clear UI strings.
  String _mapFailureToMessage(Failure failure) {
    switch (failure) {
      case ServerFailure _:
        return serverFailureMessage;
      case CacheFailure _:
        return cacheFailureMessage;
      default:
        return generalFailureMessage;
    }
  }
}
```

## Data Flow (How the new flow works)

1. UI calls `adviceRequested()`.
2. Cubit emits `Loading`.
3. Cubit requests data from Use Case.
4. Use Case returns:
   - `Right(AdvicerEntity)` on success, or
   - `Left(Failure)` on failure.
5. Cubit uses `.fold()`:
   - Failure -> map to message -> emit `Error`.
   - Success -> extract `advice` -> emit `Loaded`.

## Quick Manual Testing Tip

To test the error UI on purpose, open `lib/1_domain/usecases/advicer_usecases.dart` and toggle these lines:

```dart
// return Left(ServerFailure()); // uncomment to force error path

return const Right(
  AdvicerEntity(
    advice: 'Fake advice to test',
    id: 1,
  ),
);
```

When `Left(ServerFailure())` is active, tapping **Get Advice** should show the error message from the Cubit mapper.

## Best Practices (Why this is the Flutter way)

1. Keep failures typed and explicit instead of generic thrown strings.
2. Keep domain contracts clear using `Either<Failure, Entity>`.
3. Keep UI-layer Cubit focused on state emission and message mapping.
4. Centralize error-message mapping in one helper method.
5. Use constants for repeated UI messages to avoid duplication.

## Summary

This refactor makes error handling more predictable, testable, and scalable.
Instead of catching unknown exceptions everywhere, your app now passes controlled `Failure` objects through a clear pipeline and converts them to user-friendly messages at the Cubit level.
