import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const serverFailureMessage = 'Oops, API Error. Please try again.';
const cacheFailureMessage = 'Oops, Cache failed. Please try again.';
const generalFailureMessage = 'Oops, something went wrong. Please try again.';

class AdvicerCubit extends Cubit<AdvicerState> {
  AdvicerCubit({required this.advicerUseCases}) : super(const AdvicerInitial());

  final AdvicerUseCases advicerUseCases;

  Future<void> adviceRequested() async {
    emit(const AdvicerStateLoading());

    try {
      final failureOrAdvice = await advicerUseCases.getAdvice();

      failureOrAdvice.fold(
        (failure) =>
            emit(AdvicerStateError(message: _mapFailureToMessage(failure))),
        (advice) => emit(AdvicerStateLoaded(advice: advice.advice)),
      );
    } catch (_) {
      emit(const AdvicerStateError(message: generalFailureMessage));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure) {
      case ServerFailure _:
        return serverFailureMessage;
      case CacheFailure _:
        return cacheFailureMessage;
      default:
        return generalFailureMessage;
    }
  }
}
