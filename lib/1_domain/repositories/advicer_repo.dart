import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:dartz/dartz.dart';

abstract class AdvicerRepo {
  Future<Either<Failure, AdvicerEntity>> getAdviceFromDataSource();
}
