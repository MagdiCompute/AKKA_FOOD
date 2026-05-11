import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_balance_widget.dart';

void main() {
  Widget buildTestWidget({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: Scaffold(
          appBar: _TestAppBar(),
        ),
      ),
    );
  }

  group('CoinBalanceWidget', () {
    testWidgets('shows loading indicator while stream is loading',
        (tester) async {
      // Use a stream that never emits to keep it in loading state
      final controller = StreamController<int>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            coinBalanceStreamProvider.overrideWith(
              (ref) => controller.stream,
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays balance with coin icon when data is available',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            coinBalanceStreamProvider.overrideWith(
              (ref) => Stream.value(2500),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Coin icon is displayed
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
      // Balance is formatted with comma separator
      expect(find.text('2,500'), findsOneWidget);
    });

    testWidgets('displays 0 on error state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            coinBalanceStreamProvider.overrideWith(
              (ref) => Stream.error(Exception('Network error')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Should show 0 as fallback
      expect(find.text('0'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('formats large balance with comma separators', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            coinBalanceStreamProvider.overrideWith(
              (ref) => Stream.value(12500),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('12,500'), findsOneWidget);
    });

    testWidgets('displays zero balance correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            coinBalanceStreamProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('has semantics label for accessibility', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            coinBalanceStreamProvider.overrideWith(
              (ref) => Stream.value(1500),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Verify the Semantics widget is present with the correct label
      final semanticsWidget = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '1500 coins',
      );
      expect(semanticsWidget, findsOneWidget);
    });

    testWidgets('is compact enough for app bar usage', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            coinBalanceStreamProvider.overrideWith(
              (ref) => Stream.value(999),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render within the app bar without overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(CoinBalanceWidget), findsOneWidget);
    });
  });
}

/// A test app bar that includes the CoinBalanceWidget in its actions.
class _TestAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TestAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Test'),
      actions: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: CoinBalanceWidget(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
