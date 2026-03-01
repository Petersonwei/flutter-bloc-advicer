# Building the Domain Layer: Entities, Use Cases, and Repository Blueprint

This guide explains the latest refactor where business logic was moved out of the Cubit and into the **Domain Layer**.

References:
- [0079_cubit_introduction_and_migration_guide.md](./0079_cubit_introduction_and_migration_guide.md)
- [0078_equatable_for_bloc_events_and_states.md](./0078_equatable_for_bloc_events_and_states.md)

## Conceptual Overview (Why this change matters)

Before this change, the Cubit was doing everything:
1. Controlling UI states.
2. Simulating delay.
3. Creating fake advice data.

That works for small demos, but it mixes responsibilities.

Now we separate concerns:
- **Cubit**: handles UI state transitions (`Loading`, `Loaded`, `Error`).
- **Use Case**: contains business action logic ("get advice").
- **Entity**: defines core data shape (`advice`, `id`).
- **Repository interface**: defines what data access must look like later.

Analogy:
- Cubit is the waiter who talks to the customer (UI).
- Use Case is the kitchen workflow.
- Repository is the delivery contract with suppliers.
- Entity is the standard food container with expected fields.

This makes code easier to test, scale, and maintain.

## What changed in your codebase

1. Added Domain Entity:
- `lib/1_domain/entities/advicer_entity.dart`

2. Added Domain Use Case:
- `lib/1_domain/usecases/advicer_usecases.dart`

3. Added Repository Blueprint (abstract contract):
- `lib/1_domain/repositories/advicer_repo.dart`

4. Updated Cubit:
- `lib/2_application/pages/advicer/cubit/advicer_cubit.dart`
- Cubit now calls `advicerUseCases.getAdvice()` instead of building fake data itself.

## Syntax Breakdown (Beginner-friendly)

- `class AdvicerEntity extends Equatable`
  - Custom data class for core business data.
  - `Equatable` lets us compare objects by values.

- `final String advice; final int id;`
  - Immutable fields (set once, read many times).
  - Represents the core advice object.

- `abstract class AdvicerRepo`
  - A blueprint/contract.
  - Says what methods must exist, but not how they work yet.

- `Future<AdvicerEntity> getAdvice() async`
  - `Future`: result will come later.
  - `async/await`: clean way to write asynchronous flow.

- `await Future<void>.delayed(...)`
  - Simulates waiting for network/data source.

- `final AdvicerUseCases advicerUseCases = AdvicerUseCases();`
  - Cubit holds a use case instance and delegates business work to it.

- `emit(...)`
  - Cubit publishes a new state to UI.

## Code Walkthrough (Updated implementation with extensive comments)

```dart
// lib/1_domain/entities/advicer_entity.dart
import 'package:equatable/equatable.dart';

// ENTITY:
// This class represents the core "Advice" object in business terms.
// We keep it in the Domain layer because it is app-meaningful data,
// not UI-specific data and not API-model-specific data.
class AdvicerEntity extends Equatable {
  const AdvicerEntity({
    required this.advice,
    required this.id,
  });

  // The actual advice text (what user reads).
  final String advice;

  // A unique id for this advice (useful later for caching, tracking, etc.).
  final int id;

  // Equatable compares these values for equality.
  // If two entities have same advice + id, they are considered equal.
  @override
  List<Object?> get props => [advice, id];
}
```

```dart
// lib/1_domain/repositories/advicer_repo.dart
import 'package:advicer/1_domain/entities/advicer_entity.dart';

// REPOSITORY BLUEPRINT (contract):
// Domain layer defines WHAT is needed, not HOW it is fetched.
// Concrete implementation will come later in data/infrastructure layer.
abstract class AdvicerRepo {
  // Any real repository must provide this method.
  Future<AdvicerEntity> getAdviceFromDataSource();
}
```

```dart
// lib/1_domain/usecases/advicer_usecases.dart
import 'package:advicer/1_domain/entities/advicer_entity.dart';

// USE CASE:
// Encapsulates one business action: "get advice".
// Today it returns fake data; later it can call repository methods.
class AdvicerUseCases {
  Future<AdvicerEntity> getAdvice() async {
    // Simulate async work (e.g., network call).
    await Future<void>.delayed(const Duration(seconds: 3));

    // Return domain entity.
    // Important: returning Entity keeps domain contract consistent.
    return const AdvicerEntity(
      advice: 'Fake advice to test',
      id: 1,
    );
  }
}
```

```dart
// lib/2_application/pages/advicer/cubit/advicer_cubit.dart
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvicerCubit extends Cubit<AdvicerState> {
  AdvicerCubit() : super(const AdvicerInitial());

  // Cubit depends on use case to perform business logic.
  // In large apps this is injected, but this is fine for now.
  final AdvicerUseCases advicerUseCases = AdvicerUseCases();

  Future<void> adviceRequested() async {
    // 1) Tell UI to show loading state immediately.
    emit(const AdvicerStateLoading());

    try {
      // 2) Delegate business work to domain use case.
      final adviceEntity = await advicerUseCases.getAdvice();

      // 3) Use returned entity data to create loaded UI state.
      // Here we extract adviceEntity.advice for the presentation state.
      emit(AdvicerStateLoaded(advice: adviceEntity.advice));
    } catch (_) {
      // 4) Emit error state if something goes wrong.
      emit(
        const AdvicerStateError(
          message: 'Oops, something went wrong. Please try again.',
        ),
      );
    }
  }
}
```

## Data Flow (New architecture flow)

1. UI button calls `adviceRequested()`.
2. Cubit emits `AdvicerStateLoading`.
3. Cubit calls `AdvicerUseCases.getAdvice()`.
4. Use case returns `AdvicerEntity`.
5. Cubit reads `adviceEntity.advice`.
6. Cubit emits `AdvicerStateLoaded`.
7. UI rebuilds with the new advice text.

## Best Practices (Why this is the Flutter way)

1. Keep UI state logic in Cubit, and business rules in Use Cases.
2. Represent core business objects with Entities, not loose primitives everywhere.
3. Use repository interfaces in Domain to avoid tight coupling to network/database packages.
4. Keep classes focused on one responsibility (single-responsibility principle).
5. Use `Equatable` for reliable value comparisons in tests.