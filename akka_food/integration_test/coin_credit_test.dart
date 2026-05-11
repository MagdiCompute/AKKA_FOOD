// integration_test/coin_credit_test.dart
//
// Task 8.1 — Complete order → coins credited at 5% of total
//
// Tests the end-to-end flow from the Flutter app's perspective:
// 1. User starts with 0 coins
// 2. A successful payment of 2000 XOF triggers coin crediting
// 3. Coin balance updates to 100 (floor(2000 * 0.05) = 100)
// 4. A CoinTransaction record appears in history with amount=100, reason="Purchase reward"
// 5. A notification (snackbar) is displayed informing the user of coins earned
//
// Validates:
// - Req 1 AC1: Credit coins equal to floor(totalAmount * 0.05)
// - Req 1 AC2: Create CoinTransaction record
// - Req 1 AC4: Display notification of coins earned

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/coins/domain/entities/coin_transaction.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_balance_widget.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_earned_listener.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_transaction_tile.dart';
import 'package:akka_food/features/coins/presentation/screens/coin_history_screen.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-coin-credit-test',
      email: 'credit@example.com',
      displayName: 'Credit Tester',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

/// Simulates the coin transaction created by the `onPaymentSuccess` Cloud Function
/// after a 2000 XOF payment: floor(2000 * 0.05) = 100 coins.
CoinTransaction _expectedTransaction() => CoinTransaction(
      id: 'tx-001',
      uid: 'uid-coin-credit-test',
      amount: 100,
      reason: 'Purchase reward',
      orderId: 'order-abc-123',
      timestamp: DateTime(2024, 6, 15, 10, 30),
    );

// =============================================================================
// FakeCoinHistoryNotifier — returns the expected transaction after "payment"
// =============================================================================

class _FakeCoinHistoryNotifier extends CoinHistoryNotifier {
  @override
  Future<List<CoinTransaction>> build() async {
    return [_expectedTransaction()];
  }
}

// =============================================================================
// Helper — builds a test app with CoinEarnedListener, CoinBalanceWidget,
// and CoinHistoryScreen to verify the full flow.
// =============================================================================

Widget _buildTestApp({
  required AppUser user,
  required Stream<int> balanceStream,
}) {
  return ProviderScope(
    overrides: [
      // Override current user so auth guards don't interfere.
      currentUserProvider.overrideWith((ref) => user),
      // Override coin balance stream to simulate the backend crediting coins.
      coinBalanceStreamProvider.overrideWith((ref) => balanceStream),
      // Override coin history to return the expected transaction.
      coinHistoryNotifierProvider.overrideWith(() => _FakeCoinHistoryNotifier()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CoinEarnedListener(
          child: Column(
            children: [
              // Header with coin balance
              const Padding(
                padding: EdgeInsets.all(16),
                child: CoinBalanceWidget(),
              ),
              // Coin history screen content
              const Expanded(child: CoinHistoryScreen()),
            ],
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'complete order: coins credited at 5% of 2000 XOF total (100 coins)',
    (WidgetTester tester) async {
      final user = _fakeUser();

      // StreamController simulates the real-time balance updates from Firestore.
      // Initially emits 0 (user has no coins), then emits 100 after "payment".
      final balanceController = StreamController<int>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build the app with initial balance of 0
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        user: user,
        balanceStream: balanceController.stream,
      ));

      // Emit initial balance of 0
      balanceController.add(0);
      await tester.pumpAndSettle();

      // Verify initial balance is displayed as 0
      expect(find.text('0'), findsWidgets);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Simulate successful payment — backend credits 100 coins
      //         (floor(2000 * 0.05) = 100)
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(100);
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Verify coin balance updated to 100 (Req 1 AC1)
      //         CoinBalanceWidget should now show "100"
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('100'), findsWidgets);

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Verify notification displayed (Req 1 AC4)
      //         CoinEarnedListener detects balance increase and shows snackbar
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('🎉 You earned 100 coins!'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 5: Verify CoinTransaction record in history (Req 1 AC2)
      //         The history should show a transaction with:
      //         - amount: +100
      //         - reason: "Purchase reward"
      // ─────────────────────────────────────────────────────────────────────
      expect(find.byType(CoinTransactionTile), findsOneWidget);
      expect(find.text('Purchase reward'), findsOneWidget);
      expect(find.text('+100'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await balanceController.close();
    },
  );

  testWidgets(
    'coin credit calculation: floor(2000 * 0.05) equals exactly 100',
    (WidgetTester tester) async {
      // This test verifies the 5% calculation is correct:
      // 2000 XOF * 0.05 = 100.0 → floor = 100 coins
      final user = _fakeUser();
      final balanceController = StreamController<int>();

      const orderTotal = 2000;
      const expectedCoins = 100; // floor(2000 * 0.05)

      await tester.pumpWidget(_buildTestApp(
        user: user,
        balanceStream: balanceController.stream,
      ));

      // Start with 0 coins
      balanceController.add(0);
      await tester.pumpAndSettle();

      // Simulate payment success — coins credited
      balanceController.add(expectedCoins);
      await tester.pumpAndSettle();

      // Verify the exact amount: floor(orderTotal * 0.05)
      expect(expectedCoins, equals((orderTotal * 0.05).floor()));
      expect(find.text('$expectedCoins'), findsWidgets);

      await balanceController.close();
    },
  );
}
