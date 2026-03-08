import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/pages/advicer/advicer_page.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:advicer/2_application/pages/advicer/widgets/error_message.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAdvicerCubit extends MockCubit<AdvicerState> implements AdvicerCubit {}

Widget widgetUnderTest({required AdvicerCubit cubit}) {
  return MaterialApp(
    home: ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: BlocProvider<AdvicerCubit>.value(
        value: cubit,
        child: const AdvicerPage(),
      ),
    ),
  );
}

void main() {
  group('AdvicerPage', () {
    late MockAdvicerCubit mockAdvicerCubit;

    setUp(() {
      mockAdvicerCubit = MockAdvicerCubit();
    });

    group('should display view state', () {
      testWidgets('cubit emits AdvicerInitial', (tester) async {
        whenListen(
          mockAdvicerCubit,
          Stream<AdvicerState>.fromIterable([const AdvicerInitial()]),
          initialState: const AdvicerInitial(),
        );

        await tester.pumpWidget(widgetUnderTest(cubit: mockAdvicerCubit));

        final initialTextFinder = find.text('Your advice is waiting for you');
        expect(initialTextFinder, findsOneWidget);
      });

      testWidgets('cubit emits AdvicerStateLoading', (tester) async {
        whenListen(
          mockAdvicerCubit,
          Stream<AdvicerState>.fromIterable([const AdvicerStateLoading()]),
          initialState: const AdvicerInitial(),
        );

        await tester.pumpWidget(widgetUnderTest(cubit: mockAdvicerCubit));
        await tester.pump();

        final loadingFinder = find.byType(CircularProgressIndicator);
        expect(loadingFinder, findsOneWidget);
      });

      testWidgets('cubit emits AdvicerStateLoaded', (tester) async {
        whenListen(
          mockAdvicerCubit,
          Stream<AdvicerState>.fromIterable([
            const AdvicerStateLoaded(advice: 'advice 42'),
          ]),
          initialState: const AdvicerInitial(),
        );

        await tester.pumpWidget(widgetUnderTest(cubit: mockAdvicerCubit));
        await tester.pump();

        final loadedFinder = find.byType(AdviceField);
        expect(loadedFinder, findsOneWidget);

        final adviceText = tester.widget<AdviceField>(loadedFinder).advice;
        expect(adviceText, 'advice 42');
      });

      testWidgets('cubit emits AdvicerStateError', (tester) async {
        whenListen(
          mockAdvicerCubit,
          Stream<AdvicerState>.fromIterable([
            const AdvicerStateError(message: 'error'),
          ]),
          initialState: const AdvicerInitial(),
        );

        await tester.pumpWidget(widgetUnderTest(cubit: mockAdvicerCubit));
        await tester.pump();

        final errorFinder = find.byType(ErrorMessage);
        expect(errorFinder, findsOneWidget);
      });
    });
  });
}
