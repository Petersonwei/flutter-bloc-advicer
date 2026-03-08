# Unit Testing the Remote Data Source with Mockito

References:
- [0082_data_layer_remote_datasource_models_guide.md](./0082_data_layer_remote_datasource_models_guide.md)
- [0083_data_layer_exception_handling_guide.md](./0083_data_layer_exception_handling_guide.md)

## 1) Changes Verified with `git status` and `git diff`

### `git status` showed:
- Modified:
  - `pubspec.yaml`
  - `pubspec.lock`
- New:
  - `test/0_data/datasources/advicer_remote_datasource_test.dart`
  - `test/0_data/datasources/advicer_remote_datasource_test.mocks.dart`

### `git diff` showed:
- `pubspec.yaml` dev dependencies added:
  - `build_runner`
  - `mockito`
  - `test`

Important note:
- The generated `*.mocks.dart` file is auto-created by `build_runner`.

## 2) Conceptual Overview (Why this change)

We want to test only **our logic**, not external package internals.

The remote datasource depends on `http.Client`. If we call the real internet in unit tests, tests become slow and flaky.

So we use a **mock** client:
- We control exactly what response it returns.
- We can test success and failure behavior reliably.

Analogy:
- Instead of testing your car by driving on random real roads, you use a simulator where you control weather, traffic, and road conditions.

## 3) Syntax Breakdown (Beginner-friendly)

- `@GenerateNiceMocks([MockSpec<http.Client>()])`
  - Tells Mockito to generate a fake `http.Client` class.

- `group(...)`
  - Groups related tests for one class/feature.

- `test(...)`
  - One test case with one expected behavior.

- `when(...).thenAnswer(...)`
  - Defines how a mock should behave when a method is called.

- `expect(actual, matcher)`
  - Assertion that checks behavior/result.

- `throwsA(isA<SomeException>())`
  - Asserts that a function throws a specific error type.

- `async/await`
  - Used because datasource method returns `Future`.

## 4) Code Walkthrough (with extensive comments)

```yaml
# pubspec.yaml (new dev dependencies for unit testing)
dev_dependencies:
  build_runner: ^2.4.13
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mockito: ^5.4.4
  test: ^1.25.8
```

```dart
// test/0_data/datasources/advicer_remote_datasource_test.dart
import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/0_data/models/advicer_model.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Generated file created by build_runner.
import 'advicer_remote_datasource_test.mocks.dart';

// Ask Mockito to generate a MockClient class for http.Client.
@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {
  // Group all tests for this class in one section.
  group('AdvicerRemoteDataSource', () {
    test(
      'should return AdvicerModel when client response was 200 and has valid data',
      () async {
        // 1) Create fake HTTP client.
        final mockClient = MockClient();

        // 2) Create class under test and inject fake client.
        final datasourceUnderTest = AdvicerRemoteDataSourceImpl(
          client: mockClient,
        );

        // 3) Mock JSON body exactly as API shape expects.
        const responseBody = '{"advice_id":1,"advice":"test advice"}';
        final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');

        // 4) Tell mock client what to return when .get(...) is called.
        when(
          mockClient.get(
            uri,
            headers: {'content-type': 'application/json'},
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // 5) Execute method under test.
        final result = await datasourceUnderTest.getRandomAdviceFromApi();

        // 6) Assert parsed model is exactly what we expect.
        expect(result, const AdvicerModel(advice: 'test advice', id: 1));
      },
    );

    test(
      'should throw ServerException when client response was not 200',
      () async {
        final mockClient = MockClient();
        final datasourceUnderTest = AdvicerRemoteDataSourceImpl(
          client: mockClient,
        );

        final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');

        // Return a non-200 status code to trigger failure path.
        when(
          mockClient.get(
            uri,
            headers: {'content-type': 'application/json'},
          ),
        ).thenAnswer((_) async => http.Response('', 201));

        // Expect ServerException from datasource.
        expect(
          () => datasourceUnderTest.getRandomAdviceFromApi(),
          throwsA(isA<ServerException>()),
        );
      },
    );

    test(
      'should throw TypeError when client response was 200 but has invalid data',
      () async {
        final mockClient = MockClient();
        final datasourceUnderTest = AdvicerRemoteDataSourceImpl(
          client: mockClient,
        );

        // Invalid shape: advice_id is missing, so parsing to int fails.
        const responseBody = '{"advice":"test advice"}';
        final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');

        when(
          mockClient.get(
            uri,
            headers: {'content-type': 'application/json'},
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        // Datasource decode/parse should throw TypeError.
        expect(
          () => datasourceUnderTest.getRandomAdviceFromApi(),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });
}
```

```bash
# Commands used
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/0_data/datasources/advicer_remote_datasource_test.dart
```

## 5) Best Practices (Why this is the Flutter way)

1. Mirror `lib` folder structure under `test` for easier navigation.
2. Mock external dependencies (`http.Client`) to keep unit tests deterministic.
3. Test both happy path and failure paths.
4. Keep test names descriptive (“should ... when ...” format).
5. Generate mocks instead of hand-writing fake classes for package types.

## 6) Quick takeaway

You now have a clean first unit-test layer:
- Success parsing test
- HTTP status failure test
- Invalid JSON shape failure test

This is the right foundation before testing repository, use case, and cubit layers.
