import 'package:advicer/1_domain/entities/advicer_entity.dart';

class AdvicerModel extends AdvicerEntity {
  const AdvicerModel({
    required super.advice,
    required super.id,
  });

  factory AdvicerModel.fromJson(Map<String, dynamic> json) {
    return AdvicerModel(
      advice: json['advice'] as String,
      id: json['advice_id'] as int,
    );
  }
}
