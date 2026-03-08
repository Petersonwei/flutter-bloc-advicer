import 'package:advicer/2_application/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget widgetUnderTest({VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 220,
          height: 56,
          child: CustomButton(
            text: 'Get Advice',
            onTap: onTap,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Golden test', () {
    group('CustomButton', () {
      testWidgets('is enabled', (tester) async {
        await tester.pumpWidget(widgetUnderTest(onTap: () {}));

        await expectLater(
          find.byType(CustomButton),
          matchesGoldenFile('goldens/custom_button/custom_button_enabled.png'),
        );
      });

      testWidgets('is disabled', (tester) async {
        await tester.pumpWidget(widgetUnderTest());

        await expectLater(
          find.byType(CustomButton),
          matchesGoldenFile('goldens/custom_button/custom_button_disabled.png'),
        );
      });
    });
  });
}
