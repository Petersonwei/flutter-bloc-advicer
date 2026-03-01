import 'package:equatable/equatable.dart';

sealed class AdvicerState extends Equatable {
  const AdvicerState();

  @override
  List<Object?> get props => [];
}

final class AdvicerInitial extends AdvicerState {
  const AdvicerInitial();
}

final class AdvicerStateLoading extends AdvicerState {
  const AdvicerStateLoading();
}

final class AdvicerStateLoaded extends AdvicerState {
  const AdvicerStateLoaded({required this.advice});

  final String advice;

  @override
  List<Object?> get props => [advice];
}

final class AdvicerStateError extends AdvicerState {
  const AdvicerStateError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
