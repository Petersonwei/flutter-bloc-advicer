import 'package:advicer/1_domain/entities/advicer_entity.dart';

abstract class AdvicerRepo {
  Future<AdvicerEntity> getAdviceFromDataSource();
}
