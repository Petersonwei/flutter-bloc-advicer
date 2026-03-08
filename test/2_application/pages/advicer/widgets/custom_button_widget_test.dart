import 'package:advicer/2_application/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

abstract class OnCustomButtonTap {
  void call();
}

class MockOnCustomButtonTap extends Mock implements OnCustomButtonTap {}

Widget widgetUnderTest({VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: CustomButton(
        text: 'Get Advice',
        onTap: onTap,
      ),
    ),
  );
}

void main() {
  group('CustomButton', () {
    group('should render correctly', () {
      testWidgets('when button is displayed', (tester) async {
        await tester.pumpWidget(widgetUnderTest());

        final buttonLabelFinder = find.text('Get Advice');
        expect(buttonLabelFinder, findsOneWidget);
      });
    });

    group('should handle onTap', () {
      testWidgets('when user presses the button', (tester) async {
        final mockOnCustomButtonTap = MockOnCustomButtonTap();

        await tester.pumpWidget(
          widgetUnderTest(
            onTap: mockOnCustomButtonTap.call,
          ),
        );

        final customButtonFinder = find.byType(CustomButton);
        await tester.tap(customButtonFinder);

        verify(() => mockOnCustomButtonTap.call()).called(1);
      });
    });
  });
}
