import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:advicer/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('tap on custom button, verify advice will be loaded', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Your advice is waiting for you'), findsOneWidget);

      final customButtonFinder = find.text('Get Advice');
      expect(customButtonFinder, findsOneWidget);

      await tester.tap(customButtonFinder);

      // Wait for the API request + state transition.
      // Older Flutter versions don't support `timeout:` on pumpAndSettle,
      // so we poll manually for a few seconds.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(AdviceField).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.byType(AdviceField), findsOneWidget);
    });
  });
}
