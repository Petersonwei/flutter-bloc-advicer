# Handling Exceptions in the Data Layer: From Unpredictable Errors to Predictable Failures

This guide explains the latest exception-handling refactor based on the actual `git diff`.

References:
- [0082_data_layer_remote_datasource_models_guide.md](./0082_data_layer_remote_datasource_models_guide.md)
- [0081_functional_error_handling_with_failures_and_either.md](./0081_functional_error_handling_with_failures_and_either.md)

## 1) Changes Confirmed with `git diff`

The latest tracked changes are in:
1. `lib/0_data/exceptions/exceptions.dart`
2. `lib/0_data/datasources/advicer_remote_datasource.dart`
3. `lib/0_data/repositories/advicer_repo_impl.dart`

What changed:
- Added `CacheException`.
- Datasource now checks `statusCode != 200` first, then throws `ServerException`.
- Repository now catches `CacheException` and maps it to `CacheFailure`.

## 2) Conceptual Overview (Why this matters)

The Data Layer talks to external systems (API, local storage), and those systems can fail unexpectedly.

If we let raw exceptions bubble up, the app can crash or become hard to reason about.

So we do this:
1. **Datasource** throws clear exception types (`ServerException`, etc.).
2. **Repository** catches these exceptions.
3. **Repository** returns clean `Failure` objects (`ServerFailure`, `CacheFailure`, `GeneralFailure`) through `Either`.
4. **Cubit/UI** handles predictable failures, not raw exceptions.

Analogy:
- Datasource is a field reporter.
- Repository is the editor that translates messy reports into standard categories.
- Cubit/UI reads those categories and shows the right user message.

## 3) Syntax Breakdown (Beginner-friendly)

- `implements Exception`
  - Declares custom exception classes.

- `if (response.statusCode != 200) { throw ServerException(); }`
  - Guard clause: fail fast if HTTP response is not successful.

- `try / on / catch`
  - `try`: risky code
  - `on SomeException`: handle known error type
  - `catch`: fallback for unknown errors

- `Either<Failure, AdvicerEntity>`
  - `Right(data)` means success
  - `Left(failure)` means controlled error

- `Left(CacheFailure())`
  - Maps a technical `CacheException` into app-level failure type.

## 4) Code Walkthrough (Updated implementation with extensive comments)

```dart
// lib/0_data/exceptions/exceptions.dart
// Custom exception for API/server-related failures.
class ServerException implements Exception {}

// Custom exception for cache/local-storage-related failures.
// Even if not fully used yet, defining this now prepares the codebase.
class CacheException implements Exception {}
```

```dart
// lib/0_data/datasources/advicer_remote_datasource.dart
import 'dart:convert';

import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/0_data/models/advicer_model.dart';
import 'package:http/http.dart' as http;

abstract class AdvicerRemoteDataSource {
  /// Returns an [AdvicerModel] when the API call succeeds.
  ///
  /// Throws [ServerException] when the API does not return status code 200.
  Future<AdvicerModel> getRandomAdviceFromApi();
}

class AdvicerRemoteDataSourceImpl implements AdvicerRemoteDataSource {
  AdvicerRemoteDataSourceImpl({
    http.Client? client,
  }) : client = client ?? http.Client();

  final http.Client client;

  @override
  Future<AdvicerModel> getRandomAdviceFromApi() async {
    final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');
    final response = await client.get(
      uri,
      headers: {'content-type': 'application/json'},
    );

    // CHANGED LOGIC:
    // Guard first. If status is not 200, stop immediately.
    if (response.statusCode != 200) {
      throw ServerException();
    }

    // Success path only.
    // Decode raw JSON body into a Map and convert it into AdvicerModel.
    final decodedJson = json.decode(response.body) as Map<String, dynamic>;
    return AdvicerModel.fromJson(decodedJson);
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
      // Try to fetch data from remote datasource.
      final advice = await remoteDataSource.getRandomAdviceFromApi();
      return Right(advice);
    } on ServerException {
      // API-level failure mapped to domain failure.
      return Left(ServerFailure());
    } on CacheException {
      // NEW in this update:
      // cache-related exception mapped to cache failure.
      return Left(CacheFailure());
    } on SocketException {
      // Network connectivity issue.
      return Left(ServerFailure());
    } on HandshakeException {
      // TLS/certificate issue.
      return Left(ServerFailure());
    } catch (_) {
      // Any unknown error -> generic app-level failure.
      return Left(GeneralFailure());
    }
  }
}
```

## 5) Data Flow (Final Error Flow)

1. Datasource makes HTTP request.
2. If status is not `200`, datasource throws `ServerException`.
3. Repository catches it and returns `Left(ServerFailure())`.
4. Use case passes `Left` to Cubit.
5. Cubit maps `ServerFailure` to a user-friendly string.
6. UI shows error state instead of crashing.

Same pattern applies for other known exceptions (`CacheException` -> `CacheFailure`).

## 6) Best Practices (Why this is the Flutter/Clean Architecture way)

1. Throw technical exceptions only in Data layer.
2. Convert exceptions to domain failures in repository.
3. Keep UseCase/Cubit/UI free from low-level error details.
4. Handle known exception types explicitly before generic fallback.
5. Use guard clauses (`statusCode != 200`) for clearer control flow.
