import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:dartz/dartz.dart';

class AdvicerUseCases {
  Future<Either<Failure, AdvicerEntity>> getAdvice() async {
    await Future<void>.delayed(const Duration(seconds: 3));

    // Enable this line to test the error path manually:
    // return Left(ServerFailure());

    return const Right(
      AdvicerEntity(
        advice: 'Fake advice to test',
        id: 1,
      ),
    );
  }
}
