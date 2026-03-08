import 'package:advicer/1_domain/entities/advicer_entity.dart';
import 'package:advicer/1_domain/failures/failures.dart';
import 'package:advicer/1_domain/usecases/advicer_usecases.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockAdvicerUseCases extends Mock implements AdvicerUseCases {}

void main() {
  group('AdvicerCubit', () {
    late MockAdvicerUseCases mockAdvicerUseCases;

    setUp(() {
      mockAdvicerUseCases = MockAdvicerUseCases();
    });

    blocTest<AdvicerCubit, AdvicerState>(
      'emits nothing when no method is called',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      expect: () => <AdvicerState>[],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      'emits [AdvicerStateLoading, AdvicerStateLoaded] when adviceRequested succeeds',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(
          () => mockAdvicerUseCases.getAdvice(),
        ).thenAnswer(
          (_) async => const Right<Failure, AdvicerEntity>(
            AdvicerEntity(advice: 'advice', id: 1),
          ),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateLoaded(advice: 'advice'),
      ],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      'emits [AdvicerStateLoading, AdvicerStateError] with server message on ServerFailure',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(
          () => mockAdvicerUseCases.getAdvice(),
        ).thenAnswer(
          (_) async =>
              const Left<Failure, AdvicerEntity>(ServerFailure()),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateError(message: serverFailureMessage),
      ],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      'emits [AdvicerStateLoading, AdvicerStateError] with cache message on CacheFailure',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(
          () => mockAdvicerUseCases.getAdvice(),
        ).thenAnswer(
          (_) async =>
              const Left<Failure, AdvicerEntity>(CacheFailure()),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateError(message: cacheFailureMessage),
      ],
    );

    blocTest<AdvicerCubit, AdvicerState>(
      'emits [AdvicerStateLoading, AdvicerStateError] with general message on GeneralFailure',
      build: () => AdvicerCubit(advicerUseCases: mockAdvicerUseCases),
      setUp: () {
        when(
          () => mockAdvicerUseCases.getAdvice(),
        ).thenAnswer(
          (_) async =>
              const Left<Failure, AdvicerEntity>(GeneralFailure()),
        );
      },
      act: (cubit) => cubit.adviceRequested(),
      expect: () => <AdvicerState>[
        const AdvicerStateLoading(),
        const AdvicerStateError(message: generalFailureMessage),
      ],
    );
  });
}
