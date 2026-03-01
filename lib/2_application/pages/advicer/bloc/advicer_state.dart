part of 'advicer_bloc.dart';

sealed class AdvicerState {}

final class AdvicerInitial extends AdvicerState {}

final class AdvicerStateLoading extends AdvicerState {}

final class AdvicerStateLoaded extends AdvicerState {
  AdvicerStateLoaded({required this.advice});

  final String advice;
}

final class AdvicerStateError extends AdvicerState {
  AdvicerStateError({required this.message});

  final String message;
}
