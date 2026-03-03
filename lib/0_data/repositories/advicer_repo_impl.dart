import 'dart:io';

import 'package:advicer/0_data/datasources/advicer_remote_datasource.dart';
import 'package:advicer/0_data/exceptions/exceptions.dart';
import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/repositories/advicer_repo.dart';
import 'package:dartz/dartz.dart';

class AdvicerRepoImpl implements AdvicerRepo {
  AdvicerRepoImpl({required this.remoteDataSource});

  final AdvicerRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, AdvicerEntity>> getAdviceFromDataSource() async {
    try {
      final advice = await remoteDataSource.getRandomAdviceFromApi();
      return Right(advice);
    } on ServerException {
      return Left(ServerFailure());
    } on CacheException {
      return Left(CacheFailure());
    } on SocketException {
      return Left(ServerFailure());
    } on HandshakeException {
      return Left(ServerFailure());
    } catch (_) {
      return Left(GeneralFailure());
    }
  }
}
