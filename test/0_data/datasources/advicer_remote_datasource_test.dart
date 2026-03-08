import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/0_data/models/advicer_model.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'advicer_remote_datasource_test.mocks.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {
  group('AdvicerRemoteDataSource', () {
    test(
      'should return AdvicerModel when client response was 200 and has valid data',
      () async {
        final mockClient = MockClient();
        final datasourceUnderTest = AdvicerRemoteDataSourceImpl(
          client: mockClient,
        );

        const responseBody = '{"advice_id":1,"advice":"test advice"}';
        final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');

        when(
          mockClient.get(
            uri,
            headers: {'content-type': 'application/json'},
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        final result = await datasourceUnderTest.getRandomAdviceFromApi();

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

        when(
          mockClient.get(
            uri,
            headers: {'content-type': 'application/json'},
          ),
        ).thenAnswer((_) async => http.Response('', 201));

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

        const responseBody = '{"advice":"test advice"}';
        final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');

        when(
          mockClient.get(
            uri,
            headers: {'content-type': 'application/json'},
          ),
        ).thenAnswer((_) async => http.Response(responseBody, 200));

        expect(
          () => datasourceUnderTest.getRandomAdviceFromApi(),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });
}
