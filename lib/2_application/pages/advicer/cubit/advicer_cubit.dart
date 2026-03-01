import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvicerCubit extends Cubit<AdvicerState> {
  AdvicerCubit() : super(const AdvicerInitial());

  Future<void> adviceRequested() async {
    emit(const AdvicerStateLoading());

    try {
      await Future<void>.delayed(const Duration(seconds: 3));
      emit(const AdvicerStateLoaded(advice: 'Fake advice from Cubit'));
    } catch (_) {
      emit(
        const AdvicerStateError(
          message: 'Oops, something went wrong. Please try again.',
        ),
      );
    }
  }
}
