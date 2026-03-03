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

    if (response.statusCode == 200) {
      final decodedJson = json.decode(response.body) as Map<String, dynamic>;
      return AdvicerModel.fromJson(decodedJson);
    } else {
      throw ServerException();
    }
  }
}
