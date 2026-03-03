import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:dartz/dartz.dart';

class AdvicerUseCases {
  const AdvicerUseCases({required this.advicerRepo});

  final AdvicerRepo advicerRepo;

  Future<Either<Failure, AdvicerEntity>> getAdvice() =>
      advicerRepo.getAdviceFromDataSource();
}
