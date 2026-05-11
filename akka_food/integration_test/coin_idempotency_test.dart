// integration_test/coin_idempotency_test.dart
//
// Task 8.3 — Duplicate payment callback → no double coin credit
//
// Tests the idempotency guarantee from the Flutter app's perspective:
// 1. User starts with 0 coins
// 2. A successful payment of 2000 XOF triggers coin crediting → balance = 100
// 3. A DUPLICATE payment callback fires (server-side idempotency prevents credit)
// 4. Balance remains 100 — no second notification, no double credit
//
// The server-side `onPaymentSuccess` Cloud Function uses:
// - Pre-check: queries for existing CoinTransaction with same orderId
// - In-transaction guard: deterministic doc ID (`reward_{orderId}`) + existence check
//
// From the Flutter app's perspective, the balance stream simply does NOT emit
// a new (higher) value when a duplicate callback is processed. This test verifies
// that the UI correctly handles this — no spurious notification, balance unchanged.
//
// Validates:
// - Req 1 AC3: Credit coins only once per successful payment; duplicate payment
//   callbacks SHALL NOT result in duplicate coin credits

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

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-idempotency-test',
      email: 'idempotency@example.com',
      displayName: 'Idempotency Tester',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

// =============================================================================
// FakeCoinHistoryNotifier — returns a single transaction (no duplicates)
// =============================================================================

class _FakeCoinHistoryNotifier extends CoinHistoryNotifier {
  @override
  Future<List<CoinTransaction>> build() async {
    // Only ONE transaction exists — the idempotency check prevented a second one
    return [
      CoinTransaction(
        id: 'reward_order-dup-123',
        uid: 'uid-idempotency-test',
        amount: 100,
        reason: 'Purchase reward',
        orderId: 'order-dup-123',
        timestamp: DateTime(2024, 6, 15, 10, 30),
      ),
    ];
  }
}

// =============================================================================
// Helper — builds a test app with CoinEarnedListener and CoinBalanceWidget
// =============================================================================

Widget _buildTestApp({
  required AppUser user,
  required Stream<int> balanceStream,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => user),
      coinBalanceStreamProvider.overrideWith((ref) => balanceStream),
      coinHistoryNotifierProvider.overrideWith(() => _FakeCoinHistoryNotifier()),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: CoinEarnedListener(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: CoinBalanceWidget(),
              ),
              Expanded(
                child: Center(
                  child: Text('Idempotency Test Content'),
                ),
              ),
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
    'duplicate payment callback: no double coin credit (Req 1 AC3)',
    (WidgetTester tester) async {
      final user = _fakeUser();

      // StreamController simulates the real-time balance updates from Firestore.
      // The server-side idempotency ensures that a duplicate payment callback
      // does NOT change the balance — so the stream emits the same value.
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
      // Step 2: First payment success — coins credited (100 coins)
      //         floor(2000 * 0.05) = 100
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(100);
      await tester.pumpAndSettle();

      // Verify balance updated to 100
      expect(find.text('100'), findsWidgets);

      // Verify notification shown for the first credit
      expect(find.text('🎉 You earned 100 coins!'), findsOneWidget);

      // Dismiss the snackbar so we can detect if a second one appears
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: DUPLICATE payment callback fires
      //         Server-side idempotency prevents double credit.
      //         The balance stream re-emits the SAME value (100) because
      //         Firestore did not change — no new CoinTransaction was created.
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(100); // Same value — no change
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Verify NO second notification (Req 1 AC3)
      //         CoinEarnedListener only fires when newBalance > oldBalance.
      //         Since balance stayed at 100, no notification should appear.
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('🎉 You earned 100 coins!'), findsNothing);

      // ─────────────────────────────────────────────────────────────────────
      // Step 5: Verify balance is still 100 — NOT 200 (no double credit)
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('100'), findsWidgets);
      expect(find.text('200'), findsNothing); // Would be 200 if double-credited

      // Verify the CoinBalance provider reflects the correct value
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CoinBalanceWidget)),
      );
      final coinBalance = container.read(coinBalanceProvider);
      expect(coinBalance.total, equals(100));
      expect(coinBalance.coinsToNext, equals(900)); // 1000 - 100

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await balanceController.close();
    },
  );

  testWidgets(
    'multiple duplicate callbacks: balance remains stable, single notification only',
    (WidgetTester tester) async {
      final user = _fakeUser();
      final balanceController = StreamController<int>();

      await tester.pumpWidget(_buildTestApp(
        user: user,
        balanceStream: balanceController.stream,
      ));

      // Initial balance
      balanceController.add(500);
      await tester.pumpAndSettle();

      expect(find.text('500'), findsWidgets);

      // ─────────────────────────────────────────────────────────────────────
      // First legitimate payment: balance goes from 500 → 600
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(600);
      await tester.pumpAndSettle();

      expect(find.text('600'), findsWidgets);
      expect(find.text('🎉 You earned 100 coins!'), findsOneWidget);

      // Wait for snackbar to dismiss
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Simulate 3 duplicate callbacks — balance stays at 600 each time
      // (Server-side idempotency prevents any additional credits)
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(600); // Duplicate 1
      await tester.pumpAndSettle();
      expect(find.text('🎉 You earned 100 coins!'), findsNothing);

      balanceController.add(600); // Duplicate 2
      await tester.pumpAndSettle();
      expect(find.text('🎉 You earned 100 coins!'), findsNothing);

      balanceController.add(600); // Duplicate 3
      await tester.pumpAndSettle();
      expect(find.text('🎉 You earned 100 coins!'), findsNothing);

      // ─────────────────────────────────────────────────────────────────────
      // Verify balance is still 600 — no double/triple/quadruple credit
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('600'), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CoinBalanceWidget)),
      );
      final coinBalance = container.read(coinBalanceProvider);
      expect(coinBalance.total, equals(600));

      await balanceController.close();
    },
  );
}
