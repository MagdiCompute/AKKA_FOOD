import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/presentation/widgets/coin_earned_snackbar.dart';

void main() {
  Widget buildTestWidget({required Widget child}) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('showCoinEarnedSnackbar', () {
    testWidgets('displays snackbar with correct coin amount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCoinEarnedSnackbar(context, coinsEarned: 150),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('🎉 You earned 150 coins!'), findsOneWidget);
    });

    testWidgets('displays coin icon in snackbar', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCoinEarnedSnackbar(context, coinsEarned: 50),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('does not show snackbar when coinsEarned is 0',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCoinEarnedSnackbar(context, coinsEarned: 0),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('does not show snackbar when coinsEarned is negative',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCoinEarnedSnackbar(context, coinsEarned: -100),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('snackbar uses floating behavior', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showCoinEarnedSnackbar(context, coinsEarned: 200),
              child: const Text('Trigger'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
    });
  });
}
