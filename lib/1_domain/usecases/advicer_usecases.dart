import 'package:advicer/1_domain/entities/advicer_entity.dart';

class AdvicerUseCases {
  Future<AdvicerEntity> getAdvice() async {
    await Future<void>.delayed(const Duration(seconds: 3));

    return const AdvicerEntity(
      advice: 'Fake advice to test',
      id: 1,
    );
  }
}
