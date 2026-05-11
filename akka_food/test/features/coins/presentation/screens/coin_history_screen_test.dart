import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/coins/domain/entities/coin_balance.dart';
import 'package:akka_food/features/coins/domain/entities/coin_transaction.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/presentation/screens/coin_history_screen.dart';

void main() {
  /// Helper to build the test widget with provider overrides.
  Widget buildTestWidget({
    int balance = 0,
    AsyncValue<List<CoinTransaction>> historyState =
        const AsyncData<List<CoinTransaction>>([]),
  }) {
    return ProviderScope(
      overrides: [
        coinBalanceStreamProvider.overrideWith((ref) => Stream.value(balance)),
        coinBalanceProvider.overrideWith((ref) => CoinBalance.fromTotal(balance)),
        coinHistoryNotifierProvider.overrideWith(
          () => _FakeCoinHistoryNotifier(historyState),
        ),
      ],
      child: const MaterialApp(
        home: CoinHistoryScreen(),
      ),
    );
  }

  group('CoinHistoryScreen', () {
    testWidgets('displays app bar with title "Coin History"', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Coin History'), findsOneWidget);
    });

    testWidgets('displays balance card with formatted total', (tester) async {
      await tester.pumpWidget(buildTestWidget(balance: 2500));
      await tester.pumpAndSettle();

      expect(find.text('2,500'), findsOneWidget);
      expect(find.text('Total Coins'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('displays progress bar widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(balance: 500));
      await tester.pumpAndSettle();

      // CoinProgressBar shows "X coins to next reward"
      expect(find.text('500 coins to next reward'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading indicator while transactions are loading',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        historyState: const AsyncLoading<List<CoinTransaction>>(),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows empty state when no transactions exist (Req 4 AC3)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        balance: 0,
        historyState: const AsyncData<List<CoinTransaction>>([]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Your coin earnings and redemptions will appear here.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('displays transaction list with credit items', (tester) async {
      final transactions = [
        CoinTransaction(
          id: 'tx1',
          uid: 'user1',
          amount: 500,
          reason: 'Purchase reward',
          orderId: 'order123',
          timestamp: DateTime(2024, 3, 15, 10, 30),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        balance: 500,
        historyState: AsyncData<List<CoinTransaction>>(transactions),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Purchase reward'), findsOneWidget);
      expect(find.text('+500'), findsOneWidget);
      expect(find.textContaining('Order #order123'), findsOneWidget);
    });

    testWidgets('displays transaction list with debit items', (tester) async {
      final transactions = [
        CoinTransaction(
          id: 'tx2',
          uid: 'user1',
          amount: -1000,
          reason: 'Redemption',
          orderId: 'order456',
          timestamp: DateTime(2024, 3, 16, 14, 0),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        balance: 1500,
        historyState: AsyncData<List<CoinTransaction>>(transactions),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Redemption'), findsOneWidget);
      expect(find.text('-1000'), findsOneWidget);
    });

    testWidgets('shows error state with retry button on failure',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        historyState: AsyncError<List<CoinTransaction>>(
          Exception('Network error'),
          StackTrace.current,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load transactions'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays multiple transactions in order', (tester) async {
      final transactions = [
        CoinTransaction(
          id: 'tx1',
          uid: 'user1',
          amount: 500,
          reason: 'Purchase reward',
          orderId: 'order1',
          timestamp: DateTime(2024, 3, 16),
        ),
        CoinTransaction(
          id: 'tx2',
          uid: 'user1',
          amount: -1000,
          reason: 'Redemption',
          orderId: 'order2',
          timestamp: DateTime(2024, 3, 15),
        ),
        CoinTransaction(
          id: 'tx3',
          uid: 'user1',
          amount: 250,
          reason: 'Purchase reward',
          timestamp: DateTime(2024, 3, 14),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        balance: 750,
        historyState: AsyncData<List<CoinTransaction>>(transactions),
      ));
      await tester.pumpAndSettle();

      expect(find.text('+500'), findsOneWidget);
      expect(find.text('-1000'), findsOneWidget);
      expect(find.text('+250'), findsOneWidget);
    });

    testWidgets('transaction without orderId does not show order reference',
        (tester) async {
      final transactions = [
        CoinTransaction(
          id: 'tx1',
          uid: 'user1',
          amount: 100,
          reason: 'Bonus',
          timestamp: DateTime(2024, 3, 15, 10, 30),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(
        balance: 100,
        historyState: AsyncData<List<CoinTransaction>>(transactions),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bonus'), findsOneWidget);
      // Should not contain "Order #" text
      expect(find.textContaining('Order #'), findsNothing);
    });

    testWidgets('balance card shows zero correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(balance: 0));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Total Coins'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

/// A fake [CoinHistoryNotifier] that returns a predetermined state.
class _FakeCoinHistoryNotifier extends CoinHistoryNotifier {
  _FakeCoinHistoryNotifier(this._initialState);

  final AsyncValue<List<CoinTransaction>> _initialState;

  @override
  Future<List<CoinTransaction>> build() async {
    // Set the state from the initial value
    if (_initialState is AsyncData<List<CoinTransaction>>) {
      return (_initialState as AsyncData<List<CoinTransaction>>).value;
    }
    if (_initialState is AsyncError<List<CoinTransaction>>) {
      final err = _initialState as AsyncError<List<CoinTransaction>>;
      throw err.error;
    }
    // For loading state, return a future that never completes
    return Completer<List<CoinTransaction>>().future;
  }

  @override
  bool get hasMore => false;

  @override
  Future<void> loadNextPage() async {}

  @override
  Future<void> refresh() async {}
}
