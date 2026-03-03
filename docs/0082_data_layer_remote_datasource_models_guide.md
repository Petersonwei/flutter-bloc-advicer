# Building the Data Layer That Actually Works: Remote Data Source, Model Parsing, Repository Wiring, and Safe Error Mapping

This guide reflects the **actual current code changes**.

Source of truth used:
- `git diff` for tracked changes
- `git status` + file reads for new untracked `0_data` files

References:
- [0081_functional_error_handling_with_failures_and_either.md](./0081_functional_error_handling_with_failures_and_either.md)

## 1) Changes verified with Git

### Tracked changes from `git diff`
1. `lib/1_domain/usecases/advicer_usecases.dart`
2. `lib/2_application/pages/advicer/cubit/advicer_cubit.dart`
3. `pubspec.yaml`

### New files from `git status` (untracked)
1. `lib/0_data/exceptions/exceptions.dart`
2. `lib/0_data/models/advicer_model.dart`
3. `lib/0_data/datasources/advicer_remote_datasource.dart`
4. `lib/0_data/repositories/advicer_repo_impl.dart`

Why this note matters:
- `git diff` does not list untracked files by default.
- But these new files are core to the Data Layer implementation.

## 2) Conceptual Overview (Why these changes)

You moved from mocked advice data to a real API flow:

1. Remote datasource calls the API.
2. Model converts raw JSON into app-friendly object.
3. Repository returns `Either<Failure, Entity>` to domain.
4. Cubit maps result to `Loaded` or `Error`.

Important runtime fix included:
- Network/TLS exceptions are now caught in repository and mapped to failures.
- This prevents app crashes and shows proper error UI instead.

Analogy:
- Datasource = courier to the internet.
- Model = translator from JSON language to app language.
- Repository = safety checkpoint that turns unpredictable external issues into controlled failures.

## 3) Syntax Breakdown (Beginner-friendly)

- `abstract class`
  - A blueprint/contract.

- `implements`
  - Enforces that required methods are provided.

- `http.Client`
  - Sends HTTP requests.

- `Uri.parse(...)`
  - Converts URL string into URI object.

- `json.decode(...)`
  - Parses JSON text to Dart map/list.

- `factory ... fromJson(...)`
  - Constructor for creating object from JSON map.

- `Either<Failure, AdvicerEntity>`
  - `Left` for failure, `Right` for success.

- `try / on / catch`
  - Handles specific exception types safely.

- `SocketException`, `HandshakeException`
  - Common network and TLS certificate errors.

## 4) Code Walkthrough

```dart
// lib/0_data/exceptions/exceptions.dart
// Custom exception thrown inside the data layer for bad HTTP status responses.
class ServerException implements Exception {}
```

```dart
// lib/0_data/models/advicer_model.dart
import 'package:advicer/1_domain/entities/advicer_entity.dart';

// Model (DTO) extends entity:
// same data shape, plus JSON parsing behavior.
class AdvicerModel extends AdvicerEntity {
  const AdvicerModel({
    required super.advice,
    required super.id,
  });

  // Convert raw API map into model/entity.
  factory AdvicerModel.fromJson(Map<String, dynamic> json) {
    return AdvicerModel(
      advice: json['advice'] as String,
      id: json['advice_id'] as int,
    );
  }
}
```

```dart
// lib/0_data/datasources/advicer_remote_datasource.dart
import 'dart:convert';

import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/0_data/models/advicer_model.dart';
import 'package:http/http.dart' as http;

abstract class AdvicerRemoteDataSource {
  /// Returns [AdvicerModel] when successful.
  /// Throws [ServerException] when status code is not 200.
  Future<AdvicerModel> getRandomAdviceFromApi();
}

class AdvicerRemoteDataSourceImpl implements AdvicerRemoteDataSource {
  AdvicerRemoteDataSourceImpl({
    http.Client? client,
  }) : client = client ?? http.Client();

  // HTTP client used to communicate with the API.
  final http.Client client;

  @override
  Future<AdvicerModel> getRandomAdviceFromApi() async {
    final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');

    final response = await client.get(
      uri,
      headers: {'content-type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decodedJson = json.decode(response.body) as Map<String, dynamic>;
      return AdvicerModel.fromJson(decodedJson);
    } else {
      throw ServerException();
    }
  }
}
```

```dart
// lib/0_data/repositories/advicer_repo_impl.dart
import 'dart:io';

import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:dartz/dartz.dart';

class AdvicerRepoImpl implements AdvicerRepo {
  AdvicerRepoImpl({
    AdvicerRemoteDataSource? remoteDataSource,
  }) : remoteDataSource = remoteDataSource ?? AdvicerRemoteDataSourceImpl();

  final AdvicerRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, AdvicerEntity>> getAdviceFromDataSource() async {
    try {
      // Ask remote datasource for model/entity.
      final advice = await remoteDataSource.getRandomAdviceFromApi();
      return Right(advice);
    } on ServerException {
      // API returned non-200 response.
      return Left(ServerFailure());
    } on SocketException {
      // Device/network connectivity issue.
      return Left(ServerFailure());
    } on HandshakeException {
      // TLS certificate / secure channel issue.
      return Left(ServerFailure());
    } catch (_) {
      // Any unexpected failure fallback.
      return Left(GeneralFailure());
    }
  }
}
```

```dart
// lib/1_domain/usecases/advicer_usecases.dart
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:dartz/dartz.dart';

class AdvicerUseCases {
  const AdvicerUseCases({required this.advicerRepo});

  // Domain depends on repository contract (not concrete data-layer details).
  final AdvicerRepo advicerRepo;

  // Use case delegates fetch action to repository.
  Future<Either<Failure, AdvicerEntity>> getAdvice() =>
      advicerRepo.getAdviceFromDataSource();
}
```

```dart
// lib/2_application/pages/advicer/cubit/advicer_cubit.dart
import 'package:advicer/0_data/repositories/advicer_repo_impl.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const serverFailureMessage = 'Oops, API Error. Please try again.';
const cacheFailureMessage = 'Oops, Cache failed. Please try again.';
const generalFailureMessage = 'Oops, something went wrong. Please try again.';

class AdvicerCubit extends Cubit<AdvicerState> {
  AdvicerCubit() : super(const AdvicerInitial());

  // Final app wiring:
  // Cubit -> UseCase -> RepoImpl -> RemoteDataSource -> API
  final AdvicerUseCases advicerUseCases = AdvicerUseCases(
    advicerRepo: AdvicerRepoImpl(),
  );

  Future<void> adviceRequested() async {
    emit(const AdvicerStateLoading());

    final failureOrAdvice = await advicerUseCases.getAdvice();

    failureOrAdvice.fold(
      (failure) =>
          emit(AdvicerStateError(message: _mapFailureToMessage(failure))),
      (advice) => emit(AdvicerStateLoaded(advice: advice.advice)),
    );
  }

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

```yaml
# pubspec.yaml (relevant dependency)
dependencies:
  http: ^1.2.2
```

## 5) Data Flow (actual current behavior)

1. UI button triggers `adviceRequested()`.
2. Cubit emits loading state.
3. Use case calls repository contract.
4. Repository implementation calls remote datasource.
5. Datasource calls API and parses JSON into model/entity.
6. Repository maps result:
   - success -> `Right(entity)`
   - exceptions -> `Left(failure)`
7. Cubit maps failures to message and emits error state, or emits loaded state.

## 6) Best Practices

1. Keep HTTP and JSON logic in Data layer only.
2. Keep Domain layer pure via repository contract.
3. Convert external exceptions into domain failures before reaching UI.
4. Keep Cubit focused on UI state orchestration, not networking details.
5. Use small, single-purpose classes (datasource/model/repository/usecase).

## 7) Current API Certificate Status (Important)

As of **March 3, 2026**, the community API endpoint certificate is failing trust validation (`CERTIFICATE_VERIFY_FAILED`, certificate expired).

What this means in this project:
1. HTTPS handshake can fail even when the endpoint itself is reachable.
2. Your app may show `ServerFailure` error state instead of loaded advice.
3. This is an infrastructure/certificate issue, not a Clean Architecture wiring issue in your code.

Recommended approach:
1. Keep production security strict (do not bypass TLS validation).
2. Wait for API certificate renewal/fix on the server side.
3. Continue testing app behavior through failure-state handling until cert is fixed.

Debug-only local testing snippet (keep commented by default):

```dart
// main.dart
//
// 1) Uncomment:
// import 'dart:io';
// import 'package:flutter/foundation.dart';
//
// 2) In main(), uncomment:
// if (kDebugMode) {
//   HttpOverrides.global = DevHttpOverrides();
// }
//
// 3) Uncomment this class:
// class DevHttpOverrides extends HttpOverrides {
//   @override
//   HttpClient createHttpClient(SecurityContext? context) {
//     final client = super.createHttpClient(context);
//     client.badCertificateCallback = (cert, host, port) {
//       return host == 'api.flutter-community.de' ||
//           host == 'api.flutter-community.com';
//     };
//     return client;
//   }
// }
//
// IMPORTANT: Debug-only. Never ship this in production.
```
