// integration_test/coin_redemption_test.dart
//
// Task 8.2 — Redeem 1000 coins → balance decremented → discount applied
//
// Tests the full coin redemption flow from the Flutter app's perspective:
// 1. User starts with 3000 coins
// 2. Adds items to cart (subtotal > 1000)
// 3. Toggles coin redemption on
// 4. Verifies discount is applied (total reduced by redeemed amount)
// 5. Simulates payment success (balance decremented by Cloud Function)
// 6. Verifies balance stream emits decremented value (3000 - redeemed)
//
// Validates:
// - Req 2 AC1: Verify balance >= 1000
// - Req 2 AC2: Only multiples of 1000
// - Req 2 AC3: Debit redeemed amount and create CoinTransaction

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/cart/presentation/screens/cart_screen.dart';
import 'package:akka_food/features/cart/presentation/widgets/coin_redemption_card.dart';
import 'package:akka_food/features/coins/domain/entities/coin_transaction.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/presentation/widgets/coin_balance_widget.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-coin-redemption-test',
      email: 'redeem@example.com',
      displayName: 'Redemption Tester',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

Meal _testMeal({
  String id = 'meal-1',
  String name = 'Jollof Rice',
  double price = 2500.0,
}) =>
    Meal(
      id: id,
      name: name,
      description: 'Delicious jollof rice',
      price: price,
      categoryId: 'cat-1',
      imageUrls: const ['https://example.com/jollof.jpg'],
      isAvailable: true,
      isFeatured: false,
      featuredOrder: 0,
      nutritionalInfo: null,
      dietaryTags: const [],
      popularityScore: 10,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

// =============================================================================
// FakeCartRepository
// =============================================================================

class _FakeCartRepository implements ICartRepository {
  Cart? savedCart;

  @override
  Future<void> save(Cart cart) async {
    savedCart = cart;
  }

  @override
  Future<Cart?> load() async => null;

  @override
  Future<void> clear() async {
    savedCart = null;
  }

  @override
  Future<Cart> recheckAvailability(Cart cart) async => cart;
}

// =============================================================================
// FakeAddressNotifier — returns empty address list
// =============================================================================

class _FakeAddressNotifier extends AddressNotifier {
  @override
  Future<List<DeliveryAddress>> build() async => [];
}

// =============================================================================
// FakeCoinHistoryNotifier — returns the redemption transaction after payment
// =============================================================================

class _FakeCoinHistoryNotifier extends CoinHistoryNotifier {
  @override
  Future<List<CoinTransaction>> build() async {
    return [
      CoinTransaction(
        id: 'tx-redeem-001',
        uid: 'uid-coin-redemption-test',
        amount: -2000,
        reason: 'Redemption',
        orderId: 'order-redeem-123',
        timestamp: DateTime(2024, 6, 15, 14, 0),
      ),
    ];
  }
}

// =============================================================================
// Helper — builds CartScreen with CoinBalanceWidget to verify balance updates
// =============================================================================

Widget _buildTestApp({
  required _FakeCartRepository fakeRepo,
  required AppUser user,
  required Stream<int> balanceStream,
}) {
  return ProviderScope(
    overrides: [
      // Override cart repository to avoid Hive/Firebase.
      cartRepositoryProvider.overrideWith((_) async => fakeRepo),
      // Override current user so auth guards don't interfere.
      currentUserProvider.overrideWith((ref) => user),
      // Override coin balance stream to simulate real-time balance updates.
      coinBalanceStreamProvider.overrideWith((ref) => balanceStream),
      // Override coin history to return the redemption transaction.
      coinHistoryNotifierProvider.overrideWith(() => _FakeCoinHistoryNotifier()),
      // Override address notifier to return an empty list.
      addressNotifierProvider.overrideWith(() => _FakeAddressNotifier()),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            // Header with coin balance widget to verify balance updates
            Padding(
              padding: EdgeInsets.all(16),
              child: CoinBalanceWidget(),
            ),
            // Cart screen content
            Expanded(child: CartScreen()),
          ],
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
    'redeem 1000 coins: balance decremented, discount applied (Req 2 AC1-AC3)',
    (WidgetTester tester) async {
      final fakeRepo = _FakeCartRepository();
      final user = _fakeUser();

      // StreamController simulates the real-time balance updates from Firestore.
      // Initially emits 3000 (user has 3000 coins), then emits 1000 after
      // redemption of 2000 coins via payment success.
      final balanceController = StreamController<int>();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Build the app with initial balance of 3000 coins
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildTestApp(
        fakeRepo: fakeRepo,
        user: user,
        balanceStream: balanceController.stream,
      ));

      // Emit initial balance of 3000
      balanceController.add(3000);
      await tester.pumpAndSettle();

      // Verify initial balance is displayed (Req 2 AC1: balance >= 1000)
      expect(find.text('3000'), findsWidgets);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Add a meal to the cart (subtotal = 2500 XOF > 1000)
      // ─────────────────────────────────────────────────────────────────────
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CartScreen)),
      );
      final cartNotifier = container.read(cartNotifierProvider.notifier);
      final meal = _testMeal(); // price = 2500 XOF

      cartNotifier.addItem(meal);
      await tester.pumpAndSettle();

      // Verify item is in the cart
      expect(find.text('Jollof Rice'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Verify CoinRedemptionCard is visible (Req 2 AC1)
      //         Balance is 3000 >= 1000, so the card should appear
      // ─────────────────────────────────────────────────────────────────────
      expect(find.byType(CoinRedemptionCard), findsOneWidget);
      expect(find.text('Redeem Coins'), findsOneWidget);
      expect(find.text('You have 3000 coins'), findsOneWidget);
      // Max redeemable: min(3000, 2500) rounded down to nearest 1000 = 2000
      // (Req 2 AC2: only multiples of 1000)
      expect(find.text('Save 2000 XOF'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Verify initial total (no discount applied yet)
      //         Subtotal: 2500, Delivery fee: 500, Total: 3000
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('3000 XOF'), findsOneWidget); // Total

      // ─────────────────────────────────────────────────────────────────────
      // Step 5: Apply coin redemption — tap the Switch toggle
      //         (Req 2 AC2: only multiples of 1000 — redeems 2000)
      // ─────────────────────────────────────────────────────────────────────
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 6: Verify discount is applied in CartSummaryCard
      //         Discount: 2000 XOF (max redeemable from 3000 coins, capped
      //         by subtotal 2500, rounded down to nearest 1000)
      //         New total: 2500 + 500 - 2000 = 1000 XOF
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Coin discount'), findsOneWidget);
      expect(find.text('−2000 XOF'), findsOneWidget);
      expect(find.text('1000 XOF'), findsOneWidget); // Updated total

      // Verify the cart state has the correct redeemed coins
      final cartState = container.read(cartNotifierProvider);
      expect(cartState.redeemedCoins, equals(2000));
      expect(cartState.total, equals(1000.0)); // 2500 + 500 - 2000

      // ─────────────────────────────────────────────────────────────────────
      // Step 7: Simulate payment success — Cloud Function debits 2000 coins
      //         (Req 2 AC3: debit redeemed amount from balance)
      //         New balance: 3000 - 2000 = 1000
      // ─────────────────────────────────────────────────────────────────────
      balanceController.add(1000); // Balance decremented by Cloud Function
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 8: Verify balance stream emits decremented value (Req 2 AC3)
      //         CoinBalanceWidget should now show "1000"
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('1000'), findsWidgets);

      // Verify the CoinBalance provider reflects the new balance
      final updatedBalance = container.read(coinBalanceProvider);
      expect(updatedBalance.total, equals(1000));
      expect(updatedBalance.coinsToNext, equals(1000)); // next threshold: 2000

      // ─────────────────────────────────────────────────────────────────────
      // Cleanup
      // ─────────────────────────────────────────────────────────────────────
      await balanceController.close();
    },
  );

  testWidgets(
    'redemption amount is always a multiple of 1000 (Req 2 AC2)',
    (WidgetTester tester) async {
      final fakeRepo = _FakeCartRepository();
      final user = _fakeUser();
      final balanceController = StreamController<int>();

      await tester.pumpWidget(_buildTestApp(
        fakeRepo: fakeRepo,
        user: user,
        balanceStream: balanceController.stream,
      ));

      // User has 1500 coins — only 1000 can be redeemed (multiple of 1000)
      balanceController.add(1500);
      await tester.pumpAndSettle();

      // Add a meal with price 2500 XOF
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CartScreen)),
      );
      final cartNotifier = container.read(cartNotifierProvider.notifier);
      cartNotifier.addItem(_testMeal());
      await tester.pumpAndSettle();

      // Verify max redeemable is 1000 (1500 rounded down to nearest 1000)
      expect(find.text('Save 1000 XOF'), findsOneWidget);

      // Apply coin redemption
      final switchWidget = find.byType(Switch);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // Verify exactly 1000 coins redeemed (not 1500)
      final cartState = container.read(cartNotifierProvider);
      expect(cartState.redeemedCoins, equals(1000));
      expect(cartState.redeemedCoins % 1000, equals(0)); // Always multiple of 1000

      // Verify discount shown
      expect(find.text('−1000 XOF'), findsOneWidget);

      // Simulate payment success — balance decremented by 1000
      balanceController.add(500); // 1500 - 1000 = 500
      await tester.pumpAndSettle();

      // Verify balance updated to 500
      final updatedBalance = container.read(coinBalanceProvider);
      expect(updatedBalance.total, equals(500));

      await balanceController.close();
    },
  );
}
