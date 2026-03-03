import 'package:advicer/2_application/pages/advicer/bloc/advicer_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdvicerBloc', () {
    blocTest<AdvicerBloc, AdvicerState>(
      'emits nothing when no event is added',
      build: () => AdvicerBloc(),
      expect: () => <AdvicerState>[],
    );

    blocTest<AdvicerBloc, AdvicerState>(
      'emits [AdvicerStateLoading, AdvicerStateLoaded] when AdvicerRequestedEvent is added',
      build: () => AdvicerBloc(),
      act: (bloc) => bloc.add(const AdvicerRequestedEvent()),
      wait: const Duration(seconds: 3),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateLoaded(advice: 'Fake advice to test bloc'),
      ],
    );
  });
}
