import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'advicer_usecases_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AdvicerRepo>()])
void main() {
  group('AdvicerUseCases', () {
    group('should return AdvicerEntity', () {
      test('when AdvicerRepo returns AdvicerEntity', () async {
        final mockAdvicerRepo = MockAdvicerRepo();
        final usecaseUnderTest = AdvicerUseCases(advicerRepo: mockAdvicerRepo);

        const tAdviceEntity = AdvicerEntity(advice: 'test', id: 42);

        when(
          mockAdvicerRepo.getAdviceFromDataSource(),
        ).thenAnswer((_) async => const Right<Failure, AdvicerEntity>(tAdviceEntity));

        final result = await usecaseUnderTest.getAdvice();

        expect(result.isLeft(), false);
        expect(result.isRight(), true);
        expect(result, const Right<Failure, AdvicerEntity>(tAdviceEntity));
        verify(mockAdvicerRepo.getAdviceFromDataSource()).called(1);
        verifyNoMoreInteractions(mockAdvicerRepo);
      });
    });

    group('should return Failure', () {
      test('when AdvicerRepo returns ServerFailure', () async {
        final mockAdvicerRepo = MockAdvicerRepo();
        final usecaseUnderTest = AdvicerUseCases(advicerRepo: mockAdvicerRepo);

        when(
          mockAdvicerRepo.getAdviceFromDataSource(),
        ).thenAnswer(
          (_) async => const Left<Failure, AdvicerEntity>(ServerFailure()),
        );

        final result = await usecaseUnderTest.getAdvice();

        expect(result.isLeft(), true);
        expect(result.isRight(), false);
        expect(result, const Left<Failure, AdvicerEntity>(ServerFailure()));
        verify(mockAdvicerRepo.getAdviceFromDataSource()).called(1);
        verifyNoMoreInteractions(mockAdvicerRepo);
      });

      test('when AdvicerRepo returns GeneralFailure', () async {
        final mockAdvicerRepo = MockAdvicerRepo();
        final usecaseUnderTest = AdvicerUseCases(advicerRepo: mockAdvicerRepo);

        when(
          mockAdvicerRepo.getAdviceFromDataSource(),
        ).thenAnswer(
          (_) async => const Left<Failure, AdvicerEntity>(GeneralFailure()),
        );

        final result = await usecaseUnderTest.getAdvice();

        expect(result.isLeft(), true);
        expect(result.isRight(), false);
        expect(result, const Left<Failure, AdvicerEntity>(GeneralFailure()));
        verify(mockAdvicerRepo.getAdviceFromDataSource()).called(1);
        verifyNoMoreInteractions(mockAdvicerRepo);
      });
    });
  });
}
