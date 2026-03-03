# Reproducing the Failure Equality Bug in Repository Unit Tests

This guide explains the latest change where we intentionally reproduce a common unit-test bug:  
`ServerFailure()` vs `ServerFailure()` looking the same but failing equality checks.

References:
- [0083_data_layer_exception_handling_guide.md](./0083_data_layer_exception_handling_guide.md)
- [0086_unit_testing_remote_datasource_guide.md](./0086_unit_testing_remote_datasource_guide.md)

## 1) Changes Verified with `git status` and `git diff`

### `git status` showed:
- Modified:
  - `lib/1_domain/failures/failures.dart`
- New (untracked):
  - `test/0_data/repositories/advicer_repo_impl_test.dart`
  - `test/0_data/repositories/advicer_repo_impl_test.mocks.dart`

### `git diff` showed:
- `failures.dart` switched to **bug reproduction mode**:
  - `Failure` and child classes are plain classes (no `Equatable`).
  - The working `Equatable` version is commented out in the same file.

Why this matters:
- Without value equality, two separate instances are different objects even if they represent the same failure type.

## 2) Conceptual Overview (Why this bug happens)

In Dart, custom objects are compared by identity by default.

So this fails:
- `ServerFailure() == ServerFailure()`  
because they are two different instances in memory.

In tests, repository returns `Left(ServerFailure())` and expected is `Left(ServerFailure())`.  
They look identical in logs, but equality is still false.

Analogy:
- Two printed photos of the same person look identical, but they are still two different physical photos.

## 3) Syntax Breakdown (Beginner-friendly)

- `abstract class Failure {}`
  - Base failure type with default identity comparison.

- `Left(ServerFailure())`
  - Failure path value from `Either`.

- `expect(result, Left<Failure, AdvicerEntity>(ServerFailure()))`
  - Compares actual and expected objects.
  - Fails in bug mode because object equality is identity-based.

- `@GenerateNiceMocks([MockSpec<AdvicerRemoteDataSource>()])`
  - Generates a mocked datasource for repository unit tests.

- `verify(...)` / `verifyNoMoreInteractions(...)`
  - Checks that mocked method calls happen exactly as expected.

## 4) Code Walkthrough (with extensive comments)

```dart
// lib/1_domain/failures/failures.dart

// BUG REPRODUCTION MODE (video):
// We intentionally do NOT use Equatable here.
// This means object comparison uses instance identity, not value equality.
abstract class Failure {}

class ServerFailure extends Failure {}
class CacheFailure extends Failure {}
class GeneralFailure extends Failure {}

// WORKING VERSION is kept commented in file:
// - Failure extends Equatable
// - const constructors
// - props for value equality
```

```dart
// test/0_data/repositories/advicer_repo_impl_test.dart
import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/0_data/models/advicer_model.dart';
import 'package:advicer/0_data/repositories/advicer_repo_impl.dart';
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'advicer_repo_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AdvicerRemoteDataSource>()])
void main() {
  group('AdvicerRepoImpl', () {
    group('getAdviceFromDataSource', () {
      test('returns Right when datasource returns model', () async {
        final mockDs = MockAdvicerRemoteDataSource();
        final repo = AdvicerRepoImpl(remoteDataSource: mockDs);

        const model = AdvicerModel(advice: 'test advice', id: 42);
        when(mockDs.getRandomAdviceFromApi()).thenAnswer((_) async => model);

        final result = await repo.getAdviceFromDataSource();

        // This passes because model/entity already has value equality.
        expect(result, const Right<Failure, AdvicerEntity>(model));
      });

      test('returns Left(ServerFailure) when datasource throws ServerException',
          () async {
        final mockDs = MockAdvicerRemoteDataSource();
        final repo = AdvicerRepoImpl(remoteDataSource: mockDs);

        when(mockDs.getRandomAdviceFromApi()).thenThrow(ServerException());

        final result = await repo.getAdviceFromDataSource();

        // BUG REPRO:
        // Looks same in output, but this comparison fails in bug mode
        // because ServerFailure has identity-based equality only.
        expect(result, Left<Failure, AdvicerEntity>(ServerFailure()));
      });

      test('returns Left(GeneralFailure) on unknown exception', () async {
        final mockDs = MockAdvicerRemoteDataSource();
        final repo = AdvicerRepoImpl(remoteDataSource: mockDs);

        when(mockDs.getRandomAdviceFromApi())
            .thenThrow(Exception('Unexpected'));

        final result = await repo.getAdviceFromDataSource();

        // Same equality bug pattern for GeneralFailure.
        expect(result, Left<Failure, AdvicerEntity>(GeneralFailure()));
      });
    });
  });
}
```

## 5) How to Reproduce (exact steps)

1. Ensure bug mode is active in `failures.dart` (plain classes, no `Equatable`).
2. Run:
```bash
flutter test test/0_data/repositories/advicer_repo_impl_test.dart
```
3. Observe failure output where expected/actual look the same but assertion fails.

## 6) Best Practices (Why this is the Flutter/testing way)

1. Keep this bug-repro setup only for learning; don’t keep it in production branch.
2. Use `Equatable` (or equivalent value equality) for state/failure classes.
3. Use focused tests per layer:
   - datasource tests for API parsing and exceptions
   - repository tests for exception-to-failure mapping
4. Use mocks to isolate the unit under test and avoid network dependency.
5. Verify interactions (`verify` + `verifyNoMoreInteractions`) to catch hidden side effects.

## 7) Quick Fix Reminder

To make these failing assertions pass again:
1. Switch `Failure` back to `Equatable`-based implementation.
2. Use `const` constructors for failure classes.
3. Compare against `const Left(...Failure())` in tests if desired.
