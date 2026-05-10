// Smoke test for the root AkkaFoodApp widget.
//
// The original counter demo test was removed when main.dart was updated to
// use GoRouter + Riverpod. This test verifies the app boots without errors.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/main.dart';

void main() {
  testWidgets('AkkaFoodApp boots without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AkkaFoodApp()),
    );
    await tester.pumpAndSettle();

    // The app starts at /home which renders the placeholder Home screen.
    expect(find.text('Home'), findsOneWidget);
  });
}
