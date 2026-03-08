import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget widgetUnderTest(String text) {
  return MaterialApp(
    home: Scaffold(
      body: AdviceField(advice: text),
    ),
  );
}

void main() {
  group('AdviceField', () {
    group('should display correctly', () {
      testWidgets('when a short text is given', (tester) async {
        const testText = 'A';

        await tester.pumpWidget(widgetUnderTest(testText));
        await tester.pumpAndSettle();

        final adviceTextFinder = find.textContaining(testText);
        expect(adviceTextFinder, findsOneWidget);
      });

      testWidgets('when a long text is given', (tester) async {
        const testText =
            'Hello Flutter developers, I hope you enjoy this course and have a great time.';

        await tester.pumpWidget(widgetUnderTest(testText));
        await tester.pumpAndSettle();

        final adviceFieldFinder = find.byType(AdviceField);
        expect(adviceFieldFinder, findsOneWidget);
      });

      testWidgets('when an empty text is given', (tester) async {
        await tester.pumpWidget(widgetUnderTest(''));
        await tester.pumpAndSettle();

        final emptyAdviceFinder = find.text(AdviceField.emptyAdvice);
        expect(emptyAdviceFinder, findsOneWidget);

        final adviceText = tester.widget<AdviceField>(find.byType(AdviceField)).advice;
        expect(adviceText.isEmpty, true);
      });
    });
  });
}
