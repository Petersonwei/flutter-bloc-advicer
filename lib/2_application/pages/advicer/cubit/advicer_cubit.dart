import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvicerCubit extends Cubit<AdvicerState> {
  AdvicerCubit() : super(const AdvicerInitial());

  final AdvicerUseCases advicerUseCases = AdvicerUseCases();

  Future<void> adviceRequested() async {
    emit(const AdvicerStateLoading());

    try {
      final adviceEntity = await advicerUseCases.getAdvice();
      emit(AdvicerStateLoaded(advice: adviceEntity.advice));
    } catch (_) {
      emit(
        const AdvicerStateError(
          message: 'Oops, something went wrong. Please try again.',
        ),
      );
    }
  }
}
