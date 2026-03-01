part of 'advicer_bloc.dart';

sealed class AdvicerEvent extends Equatable {
  const AdvicerEvent();

  @override
  List<Object?> get props => [];
}

final class AdvicerRequestedEvent extends AdvicerEvent {
  const AdvicerRequestedEvent();
}
