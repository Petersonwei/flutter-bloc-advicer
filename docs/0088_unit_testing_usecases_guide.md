# Unit Testing Domain Use Cases with Mockito

This guide explains the latest changes for testing `AdvicerUseCases`.

References:
- [0086_unit_testing_remote_datasource_guide.md](./0086_unit_testing_remote_datasource_guide.md)
- [0087_bug_reproduction_failure_equality_guide.md](./0087_bug_reproduction_failure_equality_guide.md)

## 1) Changes Verified with `git status` and `git diff`

### `git status`
- `?? test/1_domain/`
  - New test folder and files for use case tests.

### `git diff`
- No tracked diff output for this step yet, because these files are currently untracked.

Why this is normal:
- `git diff` shows tracked file modifications.
- New files appear first in `git status` as `??` until added/committed.

## 2) Conceptual Overview (Why test use cases)

Use cases are part of your Domain layer and represent business actions.

Even if your use case looks simple (just forwarding repo result), it is still important to test:
1. Success flow (`Right` with entity).
2. Failure flow (`Left` with failures).
3. Correct interaction (repo called once, no extra calls).

Analogy:
- A use case is like a traffic controller between app logic and data source.
- Even a simple controller should be tested to confirm it routes correctly.

## 3) Syntax Breakdown (Beginner-friendly)

- `group(...)`
  - Organizes related tests.

- `test(...)`
  - One behavior check.

- `@GenerateNiceMocks([MockSpec<AdvicerRepo>()])`
  - Tells Mockito to generate a mock for repository.

- `when(...).thenAnswer(...)`
  - Defines what mock should return.

- `Right<Failure, AdvicerEntity>(...)`
  - Success value in `Either`.

- `Left<Failure, AdvicerEntity>(...)`
  - Failure value in `Either`.

- `expect(...)`
  - Verifies the result.

- `verify(...).called(1)`
  - Ensures method is called exactly once.

- `verifyNoMoreInteractions(...)`
  - Ensures no hidden extra calls were made.

## 4) Code Walkthrough (with extensive comments)

```dart
// test/1_domain/usecases/advicer_usecases_test.dart
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'advicer_usecases_test.mocks.dart';

// Generate a mock class for AdvicerRepo.
@GenerateNiceMocks([MockSpec<AdvicerRepo>()])
void main() {
  group('AdvicerUseCases', () {
    group('should return AdvicerEntity', () {
      test('when AdvicerRepo returns AdvicerEntity', () async {
        // Arrange:
        // Create a fake repo and inject it into use case.
        final mockAdvicerRepo = MockAdvicerRepo();
        final usecaseUnderTest = AdvicerUseCases(advicerRepo: mockAdvicerRepo);

        // Fake successful data that repo should return.
        const tAdviceEntity = AdvicerEntity(advice: 'test', id: 42);

        // Define mock behavior:
        // when repo.getAdviceFromDataSource() is called,
        // return Right(entity).
        when(
          mockAdvicerRepo.getAdviceFromDataSource(),
        ).thenAnswer((_) async => const Right<Failure, AdvicerEntity>(tAdviceEntity));

        // Act:
        final result = await usecaseUnderTest.getAdvice();

        // Assert:
        // Check successful side and exact content.
        expect(result.isLeft(), false);
        expect(result.isRight(), true);
        expect(result, const Right<Failure, AdvicerEntity>(tAdviceEntity));

        // Assert interaction:
        // repo method called once and only once.
        verify(mockAdvicerRepo.getAdviceFromDataSource()).called(1);
        verifyNoMoreInteractions(mockAdvicerRepo);
      });
    });

    group('should return Failure', () {
      test('when AdvicerRepo returns ServerFailure', () async {
        final mockAdvicerRepo = MockAdvicerRepo();
        final usecaseUnderTest = AdvicerUseCases(advicerRepo: mockAdvicerRepo);

        // Arrange failure return.
        when(
          mockAdvicerRepo.getAdviceFromDataSource(),
        ).thenAnswer(
          (_) async => const Left<Failure, AdvicerEntity>(ServerFailure()),
        );

        final result = await usecaseUnderTest.getAdvice();

        expect(result.isLeft(), true);
        expect(result.isRight(), false);
        expect(result, const Left<Failure, AdvicerEntity>(ServerFailure()));
        verify(mockAdvicerRepo.getAdviceFromDataSource()).called(1);
        verifyNoMoreInteractions(mockAdvicerRepo);
      });

      test('when AdvicerRepo returns GeneralFailure', () async {
        final mockAdvicerRepo = MockAdvicerRepo();
        final usecaseUnderTest = AdvicerUseCases(advicerRepo: mockAdvicerRepo);

        // Arrange another failure type.
        when(
          mockAdvicerRepo.getAdviceFromDataSource(),
        ).thenAnswer(
          (_) async => const Left<Failure, AdvicerEntity>(GeneralFailure()),
        );

        final result = await usecaseUnderTest.getAdvice();

        expect(result.isLeft(), true);
        expect(result.isRight(), false);
        expect(result, const Left<Failure, AdvicerEntity>(GeneralFailure()));
        verify(mockAdvicerRepo.getAdviceFromDataSource()).called(1);
        verifyNoMoreInteractions(mockAdvicerRepo);
      });
    });
  });
}
```

```bash
# Commands used for this step
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/1_domain/usecases/advicer_usecases_test.dart
```

## 5) Best Practices (Why this is the Flutter way)

1. Keep tests in mirrored folder structure (`test/1_domain/usecases/...`).
2. Mock dependencies so each unit test checks one class only.
3. Test both happy path and failure paths.
4. Verify interactions to catch hidden side effects.
5. Keep test names in `should ... when ...` format for readability.

## 6) Quick takeaway

You now have domain-layer use case tests that prove:
- business flow returns expected `Either` values,
- repository dependency is used exactly as intended,
- success and failure paths are both covered.
