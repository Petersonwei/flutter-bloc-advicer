import 'package:flutter_bloc/flutter_bloc.dart';

part 'advicer_event.dart';
part 'advicer_state.dart';

class AdvicerBloc extends Bloc<AdvicerEvent, AdvicerState> {
  AdvicerBloc() : super(AdvicerInitial()) {
    on<AdvicerRequestedEvent>(_onAdvicerRequestedEvent);
  }

  Future<void> _onAdvicerRequestedEvent(
    AdvicerRequestedEvent event,
    Emitter<AdvicerState> emit,
  ) async {
    emit(AdvicerStateLoading());

    try {
      await Future<void>.delayed(const Duration(seconds: 3));

      emit(AdvicerStateLoaded(advice: 'Fake advice to test bloc'));
    } catch (_) {
      emit(
        AdvicerStateError(
          message: 'Oops, something went wrong. Please try again.',
        ),
      );
    }
  }
}
