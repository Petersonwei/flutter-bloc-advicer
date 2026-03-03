// BUG REPRODUCTION MODE (video):
// Keep failures as plain classes (no Equatable),
// so equality checks like ServerFailure() == ServerFailure() fail.
// This reproduces the test bug shown in the lesson.
abstract class Failure {}

class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class GeneralFailure extends Failure {}

// WORKING VERSION (commented out on purpose):
// import 'package:equatable/equatable.dart';
//
// abstract class Failure extends Equatable {
//   const Failure();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class ServerFailure extends Failure {
//   const ServerFailure();
// }
//
// class CacheFailure extends Failure {
//   const CacheFailure();
// }
//
// class GeneralFailure extends Failure {
//   const GeneralFailure();
// }
