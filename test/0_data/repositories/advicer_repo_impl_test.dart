import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/0_data/models/advicer_model.dart';
import 'package:advicer/0_data/repositories/advicer_repo_impl.dart';
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'advicer_repo_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AdvicerRemoteDataSource>()])
void main() {
  group('AdvicerRepoImpl', () {
    group('getAdviceFromDataSource', () {
      test('should return Right with AdvicerEntity when datasource returns model',
          () async {
        final mockRemoteDataSource = MockAdvicerRemoteDataSource();
        final repoUnderTest = AdvicerRepoImpl(
          remoteDataSource: mockRemoteDataSource,
        );

        const tAdviceModel = AdvicerModel(advice: 'test advice', id: 42);

        when(
          mockRemoteDataSource.getRandomAdviceFromApi(),
        ).thenAnswer((_) async => tAdviceModel);

        final result = await repoUnderTest.getAdviceFromDataSource();

        expect(result.isRight(), true);
        expect(result, const Right<Failure, AdvicerEntity>(tAdviceModel));
        verify(mockRemoteDataSource.getRandomAdviceFromApi()).called(1);
        verifyNoMoreInteractions(mockRemoteDataSource);
      });

      test('should return Left(ServerFailure) when datasource throws ServerException',
          () async {
        final mockRemoteDataSource = MockAdvicerRemoteDataSource();
        final repoUnderTest = AdvicerRepoImpl(
          remoteDataSource: mockRemoteDataSource,
        );

        when(
          mockRemoteDataSource.getRandomAdviceFromApi(),
        ).thenThrow(ServerException());

        final result = await repoUnderTest.getAdviceFromDataSource();

        expect(result.isLeft(), true);
        expect(result, Left<Failure, AdvicerEntity>(ServerFailure()));
        verify(mockRemoteDataSource.getRandomAdviceFromApi()).called(1);
        verifyNoMoreInteractions(mockRemoteDataSource);
      });

      test('should return Left(GeneralFailure) on other exceptions', () async {
        final mockRemoteDataSource = MockAdvicerRemoteDataSource();
        final repoUnderTest = AdvicerRepoImpl(
          remoteDataSource: mockRemoteDataSource,
        );

        when(
          mockRemoteDataSource.getRandomAdviceFromApi(),
        ).thenThrow(Exception('Unexpected failure'));

        final result = await repoUnderTest.getAdviceFromDataSource();

        expect(result.isLeft(), true);
        expect(result, Left<Failure, AdvicerEntity>(GeneralFailure()));
        verify(mockRemoteDataSource.getRandomAdviceFromApi()).called(1);
        verifyNoMoreInteractions(mockRemoteDataSource);
      });
    });
  });
}
