# Dependency Injection with `get_it`: Decoupling Cubit, Use Case, Repository, and Data Source

This guide explains the latest Dependency Injection (DI) refactor using your actual code changes.

Reference guides:
- [0082_data_layer_remote_datasource_models_guide.md](./0082_data_layer_remote_datasource_models_guide.md)
- [0083_data_layer_exception_handling_guide.md](./0083_data_layer_exception_handling_guide.md)

## 1) Changes Verified with Git

### Tracked files from `git diff`
1. `lib/main.dart`
2. `lib/2_application/pages/advicer/advicer_page.dart`
3. `lib/2_application/pages/advicer/cubit/advicer_cubit.dart`
4. `lib/0_data/repositories/advicer_repo_impl.dart`
5. `lib/0_data/datasources/advicer_remote_datasource.dart`
6. `pubspec.yaml`

### New file from `git status` (untracked)
1. `lib/injection.dart`

Why this matters:
- `git diff` does not include untracked files.
- The DI setup is centered around the new `injection.dart`.

## 2) Conceptual Overview (Why DI was added)

Before DI:
- `AdvicerCubit` created `AdvicerUseCases` directly.
- `AdvicerUseCases` indirectly got tightly coupled to concrete classes.
- Repository/DataSource created their own dependencies internally.

This made testing and swapping implementations harder.

After DI:
- Each class receives its dependency from outside (constructor parameter).
- A single injection container (`GetIt`) creates and wires all objects.

Analogy:
- Instead of each worker buying their own tools, a central tool room provides the right tool to each person.

## 3) Syntax Breakdown (Beginner-friendly)

- `get_it`
  - A service locator package used as dependency container.

- `final sl = GetIt.instance;`
  - Creates one global container instance.

- `registerFactory<T>(() => ...)`
  - Tells container how to build type `T`.
  - `Factory` means a new instance each time requested.

- Constructor injection:
  - `AdvicerCubit({required this.advicerUseCases})`
  - Class no longer creates dependency itself.

- `WidgetsFlutterBinding.ensureInitialized()`
  - Ensures Flutter binding is ready before async startup work.

- `await di.init();`
  - Initializes and registers all dependencies before app starts.

- `di.sl<AdvicerCubit>()`
  - Gets a ready-built Cubit from the container.

## 4) Code Walkthrough (with extensive beginner comments)

```yaml
# pubspec.yaml
dependencies:
  get_it: ^8.0.3 # NEW: dependency injection container
```

```dart
// lib/injection.dart
import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/repositories/advicer_repo_impl.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Global service locator instance.
final sl = GetIt.instance;

Future<void> init() async {
  // Application layer:
  // Each request gets a fresh Cubit instance.
  sl.registerFactory<AdvicerCubit>(
    () => AdvicerCubit(advicerUseCases: sl()),
  );

  // Domain layer:
  // UseCase receives abstract repo from container.
  sl.registerFactory<AdvicerUseCases>(
    () => AdvicerUseCases(advicerRepo: sl()),
  );

  // Data layer:
  // Bind abstract repo type to concrete implementation.
  sl.registerFactory<AdvicerRepo>(
    () => AdvicerRepoImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<AdvicerRemoteDataSource>(
    () => AdvicerRemoteDataSourceImpl(client: sl()),
  );

  // External dependency:
  // HTTP client is also container-managed.
  sl.registerFactory<http.Client>(() => http.Client());
}
```

```dart
// lib/2_application/pages/advicer/cubit/advicer_cubit.dart
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvicerCubit extends Cubit<AdvicerState> {
  // CHANGED: UseCase is injected from outside.
  AdvicerCubit({required this.advicerUseCases}) : super(const AdvicerInitial());

  // This variable now holds injected business dependency.
  final AdvicerUseCases advicerUseCases;

  // ... existing adviceRequested logic unchanged ...
}
```

```dart
// lib/0_data/repositories/advicer_repo_impl.dart
class AdvicerRepoImpl implements AdvicerRepo {
  // CHANGED: DataSource is injected from outside.
  AdvicerRepoImpl({required this.remoteDataSource});

  final AdvicerRemoteDataSource remoteDataSource;

  // ... existing getAdviceFromDataSource logic ...
}
```

```dart
// lib/0_data/datasources/advicer_remote_datasource.dart
class AdvicerRemoteDataSourceImpl implements AdvicerRemoteDataSource {
  // CHANGED: http.Client is injected from outside.
  AdvicerRemoteDataSourceImpl({required this.client});

  final http.Client client;

  // ... existing getRandomAdviceFromApi logic ...
}
```

```dart
// lib/main.dart
import 'package:advicer/injection.dart' as di;
import 'package:flutter/material.dart';

void main() async {
  // Ensure Flutter is initialized before async DI setup.
  WidgetsFlutterBinding.ensureInitialized();

  // Register all dependencies before runApp.
  await di.init();

  runApp(/* ... */);
}
```

```dart
// lib/2_application/pages/advicer/advicer_page.dart
import 'package:advicer/injection.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvicerPageWrapperProvider extends StatelessWidget {
  const AdvicerPageWrapperProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // CHANGED: Cubit comes from DI container, not direct new().
      create: (context) => di.sl<AdvicerCubit>(),
      child: const AdvicerPage(),
    );
  }
}
```

## 5) Data Flow (after DI)

1. App starts.
2. `di.init()` registers factories.
3. `AdvicerPage` asks container for `AdvicerCubit`.
4. Container builds Cubit and injects UseCase.
5. Container builds UseCase and injects Repo.
6. Container builds Repo and injects DataSource.
7. Container builds DataSource and injects `http.Client`.

## 6) Best Practices (Why this is the Flutter way)

1. Constructor injection keeps classes focused and testable.
2. Class dependencies become explicit (`required` params).
3. App wiring is centralized in one place (`injection.dart`).
4. Abstract type registration (`AdvicerRepo`) supports easy swapping/mocking.
5. `registerFactory` for Cubit avoids stale state reuse between screens.
