import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/domain/entities/coin_balance.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_progress_bar.dart';

void main() {
  Widget buildTestWidget({required CoinBalance coinBalance}) {
    return ProviderScope(
      overrides: [
        coinBalanceProvider.overrideWithValue(coinBalance),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: CoinProgressBar(),
          ),
        ),
      ),
    );
  }

  group('CoinProgressBar', () {
    testWidgets('displays correct label for coins to next reward',
        (tester) async {
      final balance = CoinBalance.fromTotal(500);

      await tester.pumpWidget(buildTestWidget(coinBalance: balance));
      await tester.pumpAndSettle();

      expect(find.text('500 coins to next reward'), findsOneWidget);
    });

    testWidgets('displays progress bar with correct value', (tester) async {
      final balance = CoinBalance.fromTotal(750);

      await tester.pumpWidget(buildTestWidget(coinBalance: balance));
      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(0.75, 0.001));
    });

    testWidgets('shows 1000 coins to next reward when balance is 0',
        (tester) async {
      final balance = CoinBalance.fromTotal(0);

      await tester.pumpWidget(buildTestWidget(coinBalance: balance));
      await tester.pumpAndSettle();

      expect(find.text('1000 coins to next reward'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.0);
    });

    testWidgets('shows 1000 coins to next reward at exact threshold',
        (tester) async {
      // At exactly 1000, next threshold is 2000, so coinsToNext = 1000
      final balance = CoinBalance.fromTotal(1000);

      await tester.pumpWidget(buildTestWidget(coinBalance: balance));
      await tester.pumpAndSettle();

      expect(find.text('1000 coins to next reward'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.0);
    });

    testWidgets('shows correct progress for partial balance', (tester) async {
      // 2300 coins: progress = 300/1000 = 0.3, coinsToNext = 700
      final balance = CoinBalance.fromTotal(2300);

      await tester.pumpWidget(buildTestWidget(coinBalance: balance));
      await tester.pumpAndSettle();

      expect(find.text('700 coins to next reward'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(0.3, 0.001));
    });

    testWidgets('has semantics for accessibility', (tester) async {
      final balance = CoinBalance.fromTotal(600);

      await tester.pumpWidget(buildTestWidget(coinBalance: balance));
      await tester.pumpAndSettle();

      final semanticsWidget = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '400 coins to next reward',
      );
      expect(semanticsWidget, findsOneWidget);
    });

    testWidgets('uses theme color scheme for progress bar', (tester) async {
      final balance = CoinBalance.fromTotal(500);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWithValue(balance),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: CoinProgressBar(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the progress indicator renders without errors
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without overflow in constrained space',
        (tester) async {
      final balance = CoinBalance.fromTotal(999);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coinBalanceProvider.overrideWithValue(balance),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                child: CoinProgressBar(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CoinProgressBar), findsOneWidget);
    });
  });
}
