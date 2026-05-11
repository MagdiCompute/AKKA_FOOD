import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_earned_listener.dart';

void main() {
  Widget buildTestWidget({
    required StreamController<int> controller,
  }) {
    return ProviderScope(
      overrides: [
        coinBalanceStreamProvider.overrideWith(
          (ref) => controller.stream,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: CoinEarnedListener(
            child: Text('Content'),
          ),
        ),
      ),
    );
  }

  group('CoinEarnedListener', () {
    testWidgets('renders child widget', (tester) async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildTestWidget(controller: controller));

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('does not show snackbar on initial balance load',
        (tester) async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildTestWidget(controller: controller));

      controller.add(500);
      await tester.pumpAndSettle();

      // No snackbar on initial load
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows snackbar when balance increases', (tester) async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildTestWidget(controller: controller));

      // Initial balance
      controller.add(500);
      await tester.pumpAndSettle();

      // Balance increases by 150
      controller.add(650);
      await tester.pumpAndSettle();

      expect(find.text('🎉 You earned 150 coins!'), findsOneWidget);
    });

    testWidgets('does not show snackbar when balance decreases (redemption)',
        (tester) async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildTestWidget(controller: controller));

      // Initial balance
      controller.add(2000);
      await tester.pumpAndSettle();

      // Balance decreases (redemption)
      controller.add(1000);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('does not show snackbar when balance stays the same',
        (tester) async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildTestWidget(controller: controller));

      // Initial balance
      controller.add(500);
      await tester.pumpAndSettle();

      // Same balance emitted again
      controller.add(500);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows correct amount for multiple increases', (tester) async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildTestWidget(controller: controller));

      // Initial balance
      controller.add(100);
      await tester.pumpAndSettle();

      // First increase
      controller.add(200);
      await tester.pumpAndSettle();

      expect(find.text('🎉 You earned 100 coins!'), findsOneWidget);

      // Dismiss the first snackbar
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Second increase
      controller.add(450);
      await tester.pumpAndSettle();

      expect(find.text('🎉 You earned 250 coins!'), findsOneWidget);
    });
  });
}
