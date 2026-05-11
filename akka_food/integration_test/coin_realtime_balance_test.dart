// integration_test/coin_realtime_balance_test.dart
//
// Task 8.4 — Balance updates in real time after payment
//
// Tests that the coin balance UI updates reactively without manual refresh:
// 1. User starts with initial balance (500 coins)
// 2. CoinBalanceWidget displays "500"
// 3. Simulate a payment success (balance stream emits 600)
// 4. Verify CoinBalanceWidget updates to "600" WITHOUT manual refresh
// 5. Simulate another payment (balance stream emits 750)
// 6. Verify CoinBalanceWidget updates to "750"
// 7. Verify CoinProgressBar updates accordingly
// 8. Verify notifications fire for each increase
//
// Validates:
// - Req 3 AC1: Display current coin balance
// - Req 3 AC2: Update displayed balance within 5 seconds without manual refresh
// - Req 3 AC3: Progress indicator updates

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_balance_widget.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_earned_listener.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_progress_bar.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-realtime-balance-test',
      email: 'realtime@example.com',
      displayName: 'Realtime Tester',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

// =============================================================================
// Helper — builds a test app with CoinEarnedListener, CoinBalanceWidget,
// and CoinProgressBar to verify real-time updates.
// =============================================================================

Widget _buildTestApp({
  required AppUser user,
  required Stream<int> balanceStream,
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => user),
      coinBalanceStreamProvider.overrideWith((ref) => balanceStream),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CoinEarnedListener(
          child: Column(
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: CoinBalanceWidget(),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CoinProgressBar(),
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
    'balance updates in real time: 500 → 600 → 750 without manual refresh',
    (WidgetTester tester) async {
      final user = _fakeUser();
      final balanceController = StreamController<int>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build the app and emit initial balance of 500
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        user: user,
        balanceStream: balanceController.stream,
      ));

      balanceController.add(500);
      await tester.pumpAndSettle();

      // Verify initial balance is displayed as "500"
      expect(find.text('500'), findsOneWidget);

      // Verify progress bar shows coins to next threshold
      // 500 coins → nextThreshold = 1000, coinsToNext = 500
      expect(find.text('500 coins to next reward'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Simulate first payment success — balance increases to 600
      //         (Req 3 AC2: update without manual refresh)
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(600);
      await tester.pumpAndSettle();

      // Verify CoinBalanceWidget updates to "600" without manual refresh
      expect(find.text('600'), findsOneWidget);

      // Verify CoinProgressBar updates: 600 → coinsToNext = 400
      expect(find.text('400 coins to next reward'), findsOneWidget);

      // Verify notification fires for the 100-coin increase
      expect(find.text('🎉 You earned 100 coins!'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Dismiss the first snackbar before the next balance change
      // ─────────────────────────────────────────────────────────────────────
      // Wait for snackbar to auto-dismiss or dismiss manually
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Simulate second payment success — balance increases to 750
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(750);
      await tester.pumpAndSettle();

      // Verify CoinBalanceWidget updates to "750" without manual refresh
      expect(find.text('750'), findsOneWidget);

      // Verify CoinProgressBar updates: 750 → coinsToNext = 250
      expect(find.text('250 coins to next reward'), findsOneWidget);

      // Verify notification fires for the 150-coin increase
      expect(find.text('🎉 You earned 150 coins!'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await balanceController.close();
    },
  );

  testWidgets(
    'progress bar updates correctly when balance crosses threshold boundary',
    (WidgetTester tester) async {
      final user = _fakeUser();
      final balanceController = StreamController<int>();

      // ─────────────────────────────────────────────────────────────────────
      // Start with 950 coins (50 away from 1000 threshold)
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        user: user,
        balanceStream: balanceController.stream,
      ));

      balanceController.add(950);
      await tester.pumpAndSettle();

      // 950 coins → nextThreshold = 1000, coinsToNext = 50
      expect(find.text('950'), findsOneWidget);
      expect(find.text('50 coins to next reward'), findsOneWidget);

      // Verify the LinearProgressIndicator exists
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Cross the 1000 threshold — balance goes to 1050
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(1050);
      await tester.pumpAndSettle();

      // 1050 coins → nextThreshold = 2000, coinsToNext = 950
      expect(find.text('1,050'), findsOneWidget);
      expect(find.text('950 coins to next reward'), findsOneWidget);

      // Verify notification for the 100-coin increase
      expect(find.text('🎉 You earned 100 coins!'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await balanceController.close();
    },
  );

  testWidgets(
    'no notification fires on initial balance load (only on increases)',
    (WidgetTester tester) async {
      final user = _fakeUser();
      final balanceController = StreamController<int>();

      // ─────────────────────────────────────────────────────────────────────
      // Emit initial balance — should NOT trigger a notification
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        user: user,
        balanceStream: balanceController.stream,
      ));

      balanceController.add(500);
      await tester.pumpAndSettle();

      // Balance is displayed
      expect(find.text('500'), findsOneWidget);

      // No snackbar notification on initial load
      expect(find.textContaining('You earned'), findsNothing);

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await balanceController.close();
    },
  );
}
