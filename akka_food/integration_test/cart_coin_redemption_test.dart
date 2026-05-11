// integration_test/cart_coin_redemption_test.dart
//
// Task 7.2 — Coin redemption applied and removed
//
// Tests that the CoinRedemptionCard appears when the user has ≥ 1000 coins,
// that toggling the switch applies the discount, and that toggling it off
// removes the discount. Follows the same pattern as cart_flow_test.dart.

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
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/coin_history_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-coin-test',
      email: 'coin@example.com',
      displayName: 'Coin Tester',
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

class FakeCartRepository implements ICartRepository {
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
// Helper — builds CartScreen wrapped in ProviderScope with overrides
// =============================================================================

Widget _buildCartApp({
  required FakeCartRepository fakeRepo,
  required AppUser user,
  required int coinBalance,
}) {
  return ProviderScope(
    overrides: [
      // Override cart repository to avoid Hive/Firebase.
      cartRepositoryProvider.overrideWith((_) async => fakeRepo),
      // Override current user so auth guards don't interfere.
      currentUserProvider.overrideWith((ref) => user),
      // Override coin balance to the specified value.
      coinBalanceProvider.overrideWith((ref) {
        final controller = StreamController<int>();
        controller.add(coinBalance);
        ref.onDispose(controller.close);
        return controller.stream;
      }),
      // Override address notifier to return an empty list.
      addressNotifierProvider.overrideWith(() => _FakeAddressNotifier()),
    ],
    child: const MaterialApp(
      home: CartScreen(),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'coin redemption: card visible, apply discount, remove discount',
    (WidgetTester tester) async {
      final fakeRepo = FakeCartRepository();
      final user = _fakeUser();

      // ─────────────────────────────────────────────────────────────────────
      // Setup: Build the cart screen with 3000 coins available
      // ─────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(_buildCartApp(
        fakeRepo: fakeRepo,
        user: user,
        coinBalance: 3000,
      ));
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Add a meal to the cart (subtotal = 2500 XOF > 1000)
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
      // Step 2: Verify CoinRedemptionCard is visible (Req 7.1)
      //         Balance is 3000 ≥ 1000, so the card should appear
      // ─────────────────────────────────────────────────────────────────────
      expect(find.byType(CoinRedemptionCard), findsOneWidget);
      expect(find.text('Redeem Coins'), findsOneWidget);
      expect(find.text('You have 3000 coins'), findsOneWidget);
      // Max redeemable: min(3000, 2500) rounded down to nearest 1000 = 2000
      expect(find.text('Save 2000 XOF'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Verify initial total (no discount applied yet)
      //         Subtotal: 2500, Delivery fee: 500, Total: 3000
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('3000 XOF'), findsOneWidget); // Total

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Apply coin redemption — tap the Switch toggle (Req 7.3)
      // ─────────────────────────────────────────────────────────────────────
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 5: Verify discount is applied in CartSummaryCard (Req 7.3)
      //         Discount: 2000 XOF (max redeemable from 3000 coins, capped by subtotal 2500)
      //         New total: 2500 + 500 - 2000 = 1000 XOF
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Coin discount'), findsOneWidget);
      expect(find.text('−2000 XOF'), findsOneWidget);
      expect(find.text('1000 XOF'), findsOneWidget); // Updated total

      // ─────────────────────────────────────────────────────────────────────
      // Step 6: Remove coin redemption — tap the Switch toggle again (Req 7.5)
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 7: Verify discount is removed (Req 7.5)
      //         Total should return to original: 2500 + 500 = 3000 XOF
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Coin discount'), findsNothing);
      expect(find.text('−2000 XOF'), findsNothing);
      expect(find.text('3000 XOF'), findsOneWidget); // Original total restored
    },
  );
}
