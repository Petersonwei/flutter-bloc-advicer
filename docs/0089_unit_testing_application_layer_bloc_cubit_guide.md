# Unit Testing the Application Layer with `bloc_test` (BLoC + Cubit)

This guide explains the latest application-layer testing changes

References:
- [0088_unit_testing_usecases_guide.md](./0088_unit_testing_usecases_guide.md)
- [0086_unit_testing_remote_datasource_guide.md](./0086_unit_testing_remote_datasource_guide.md)

## 1) Changes Verified with `git status` and `git diff`

### `git status`
- Modified:
  - `pubspec.yaml`
  - `pubspec.lock`
- New:
  - `test/2_application/pages/advicer/bloc/advicer_bloc_test.dart`
  - `test/2_application/pages/advicer/cubit/advicer_cubit_test.dart`

### `git diff`
- `pubspec.yaml` added test libraries:
  - `bloc_test: ^10.0.0`
  - `mocktail: ^1.0.4`

Important note:
- `git diff` shows tracked edits (here mainly dependency changes).
- New test files are visible in `git status` as untracked until staged/committed.

## 2) Conceptual Overview (Why this change)

You already tested:
- Data layer (datasource/repository)
- Domain layer (usecase)

Now you test the **Application layer**:
- `AdvicerBloc`
- `AdvicerCubit`

Why:
- These classes directly control what UI state gets emitted.
- If they emit wrong state order, UI behavior breaks even when data/domain logic is correct.

Analogy:
- Data/domain tests check engine parts.
- Application-layer tests check the dashboard signals seen by the driver.

## 3) Syntax Breakdown (Beginner-friendly)

- `blocTest<BlocType, StateType>(...)`
  - Helper from `bloc_test` to test emitted state sequences.

- `build: () => ...`
  - Creates fresh bloc/cubit instance for each test.

- `act: (blocOrCubit) => ...`
  - Triggers the behavior being tested (add event/call method).

- `expect: () => [ ...states ]`
  - Ordered list of expected emitted states.

- `wait: Duration(...)`
  - Waits before final assertion (needed when code has delays).

- `setUp(() { ... })`
  - Runs before each test; useful for creating mocks.

- `when(() => mock.method()).thenAnswer(...)`
  - Mocktail syntax to define fake return behavior.

## 4) Code Walkthrough (with extensive comments)

```yaml
# pubspec.yaml (dev dependencies)
dev_dependencies:
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
```

```dart
// test/2_application/pages/advicer/bloc/advicer_bloc_test.dart
import 'package:advicer/2_application/pages/advicer/bloc/advicer_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdvicerBloc', () {
    blocTest<AdvicerBloc, AdvicerState>(
      // Baseline behavior: if nothing happens, no state should be emitted.
      'emits nothing when no event is added',
      build: () => AdvicerBloc(),
      expect: () => <AdvicerState>[],
    );

    blocTest<AdvicerBloc, AdvicerState>(
      // Main flow: event -> loading -> loaded.
      // (In your current bloc implementation, success is emitted after a delay.)
      'emits [AdvicerStateLoading, AdvicerStateLoaded] when AdvicerRequestedEvent is added',
      build: () => AdvicerBloc(),
      act: (bloc) => bloc.add(const AdvicerRequestedEvent()),
      wait: const Duration(seconds: 3), // needed because bloc uses Future.delayed(3s)
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateLoaded(advice: 'Fake advice to test bloc'),
      ],
    );
  });
}
```

```dart
// test/2_application/pages/advicer/cubit/advicer_cubit_test.dart
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mocktail mock for use case dependency.
class MockAdvicerUseCases extends Mock implements AdvicerUseCases {}

void main() {
  group('AdvicerCubit', () {
    late MockAdvicerUseCases mockAdvicerUseCases;

    setUp(() {
      // Fresh mock before each test to avoid state leakage between tests.
      mockAdvicerUseCases = MockAdvicerUseCases();
    });

    blocTest<AdvicerCubit, AdvicerState>(
      'emits nothing when no method is called',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      expect: () => <AdvicerState>[],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      // Success path:
      // getAdvice returns Right(entity) -> cubit emits Loading then Loaded.
      'emits [AdvicerStateLoading, AdvicerStateLoaded] when adviceRequested succeeds',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(() => mockAdvicerUseCases.getAdvice()).thenAnswer(
          (_) async => const Right<Failure, AdvicerEntity>(
            AdvicerEntity(advice: 'advice', id: 1),
          ),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateLoaded(advice: 'advice'),
      ],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      // Server failure mapping path.
      'emits [AdvicerStateLoading, AdvicerStateError] with server message on ServerFailure',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(() => mockAdvicerUseCases.getAdvice()).thenAnswer(
          (_) async => const Left<Failure, AdvicerEntity>(ServerFailure()),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateError(message: serverFailureMessage),
      ],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      // Cache failure mapping path.
      'emits [AdvicerStateLoading, AdvicerStateError] with cache message on CacheFailure',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(() => mockAdvicerUseCases.getAdvice()).thenAnswer(
          (_) async => const Left<Failure, AdvicerEntity>(CacheFailure()),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateError(message: cacheFailureMessage),
      ],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      // Generic fallback failure mapping path.
      'emits [AdvicerStateLoading, AdvicerStateError] with general message on GeneralFailure',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(() => mockAdvicerUseCases.getAdvice()).thenAnswer(
          (_) async => const Left<Failure, AdvicerEntity>(GeneralFailure()),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateError(message: generalFailureMessage),
      ],
    );
  });
}
```

```bash
# Command used
flutter test test/2_application/pages/advicer/bloc/advicer_bloc_test.dart test/2_application/pages/advicer/cubit/advicer_cubit_test.dart
```

## 5) Best Practices (Why this is the Flutter way)

1. Test emitted state sequences, not internal private details.
2. Keep one behavior per test (`should ... when ...` style naming).
3. Mock only dependencies (`AdvicerUseCases`) and focus test on class under test.
4. Add `wait` only when async delay is part of real behavior.
5. Mirror `lib` structure under `test` for easier maintenance.

## 6) Quick takeaway

You now cover all layers with unit tests:
- Data layer
- Domain layer
- Application layer (Bloc + Cubit)

That gives you a strong safety net for future refactors.
