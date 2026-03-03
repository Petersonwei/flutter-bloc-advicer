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
  AdvicerRemoteDataSourceImpl({required this.client});

  final http.Client client;

  @override
  Future<AdvicerModel> getRandomAdviceFromApi() async {
    final uri = Uri.parse('https://api.flutter-community.com/api/v1/advice');
    final response = await client.get(
      uri,
      headers: {'content-type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ServerException();
    }

    final decodedJson = json.decode(response.body) as Map<String, dynamic>;
    return AdvicerModel.fromJson(decodedJson);
  }
}
