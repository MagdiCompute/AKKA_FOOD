// integration_test/cart_checkout_blocked_test.dart
//
// Task 7.4 — Checkout blocked when unavailable item present
//
// Validates:
// - Req 8.4: Block checkout when unavailable item present
// - Req 5.1: Highlight unavailable items in red with Remove prompt
//
// Uses a FakeCartRepository whose recheckAvailability() marks a specific
// item as unavailable, then verifies the checkout button is disabled,
// the unavailable item is highlighted, and removing it re-enables checkout.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/cart/presentation/screens/cart_screen.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/domain/entities/coin_balance.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-checkout-blocked-test',
      email: 'checkout@example.com',
      displayName: 'Checkout Tester',
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
// FakeCartRepository — marks a specific meal as unavailable on recheckAvailability
// =============================================================================

class _FakeCartRepository implements ICartRepository {
  _FakeCartRepository({this.unavailableMealIds = const {}});

  /// Set of meal IDs that should be marked unavailable during recheckAvailability.
  final Set<String> unavailableMealIds;

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
  Future<Cart> recheckAvailability(Cart cart) async {
    // Mark items in unavailableMealIds as unavailable.
    final updatedItems = cart.items.map((item) {
      if (unavailableMealIds.contains(item.mealId)) {
        return item.copyWith(isAvailable: false);
      }
      return item.copyWith(isAvailable: true);
    }).toList();
    return cart.copyWith(items: updatedItems);
  }
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
  required _FakeCartRepository fakeRepo,
  required AppUser user,
}) {
  return ProviderScope(
    overrides: [
      // Override cart repository to avoid Hive/Firebase.
      cartRepositoryProvider.overrideWith((_) async => fakeRepo),
      // Override current user so auth guards don't interfere.
      currentUserProvider.overrideWith((ref) => user),
      // Override coin balance to 0 (no coin redemption in this test).
      coinBalanceProvider.overrideWithValue(
        CoinBalance.fromTotal(0),
      ),
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
    'checkout blocked when unavailable item present (Req 8.4, 5.1)',
    (WidgetTester tester) async {
      // FakeCartRepository that marks 'meal-1' as unavailable on recheck.
      final fakeRepo = _FakeCartRepository(
        unavailableMealIds: {'meal-1'},
      );
      final user = _fakeUser();

      await tester.pumpWidget(_buildCartApp(
        fakeRepo: fakeRepo,
        user: user,
      ));
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Cart starts empty
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Your cart is empty'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Add a meal to the cart via CartNotifier
      // ─────────────────────────────────────────────────────────────────────
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CartScreen)),
      );
      final cartNotifier = container.read(cartNotifierProvider.notifier);
      final meal = _testMeal();

      cartNotifier.addItem(meal);
      await tester.pumpAndSettle();

      // Verify item is in the cart and checkout button is enabled.
      expect(find.text('Jollof Rice'), findsOneWidget);
      expect(find.text('Item unavailable'), findsNothing);

      // The checkout button should be enabled (onPressed is not null).
      // Since delivery is selected but no address is set, the button may be
      // disabled due to missing address. Switch to pickup to isolate the
      // unavailability test.
      cartNotifier.setDeliveryOption(
        DeliveryOption.pickup,
      );
      await tester.pumpAndSettle();

      // Now with pickup selected and all items available, checkout should be enabled.
      final checkoutButtonFinder = find.widgetWithText(FilledButton, 'Checkout');
      expect(checkoutButtonFinder, findsOneWidget);
      final checkoutButton =
          tester.widget<FilledButton>(checkoutButtonFinder);
      expect(checkoutButton.onPressed, isNotNull,
          reason: 'Checkout should be enabled when all items are available');

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: Simulate unavailable item by calling validateForCheckout()
      //         which triggers recheckAvailability on the FakeCartRepository
      // ─────────────────────────────────────────────────────────────────────
      await cartNotifier.validateForCheckout();
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Verify checkout button is disabled (Req 8.4)
      // ─────────────────────────────────────────────────────────────────────
      final disabledCheckoutFinder =
          find.widgetWithText(FilledButton, 'Checkout');
      expect(disabledCheckoutFinder, findsOneWidget);
      final disabledCheckoutButton =
          tester.widget<FilledButton>(disabledCheckoutFinder);
      expect(disabledCheckoutButton.onPressed, isNull,
          reason: 'Checkout should be disabled when unavailable item present');

      // ─────────────────────────────────────────────────────────────────────
      // Step 5: Verify unavailable item is highlighted (Req 5.1)
      //         - "Item unavailable" text visible
      //         - "Remove" button visible
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Item unavailable'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 6: Tap Remove button — verify item is removed
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Item should be removed — cart is now empty.
      expect(find.text('Jollof Rice'), findsNothing);
      expect(find.text('Item unavailable'), findsNothing);
      expect(find.text('Your cart is empty'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 7: Verify checkout button is gone (empty cart shows empty state)
      //         If we add a new available item, checkout should be enabled.
      // ─────────────────────────────────────────────────────────────────────
      // Add a second meal that won't be marked unavailable.
      final meal2 = _testMeal(id: 'meal-2', name: 'Fried Plantain', price: 1500.0);
      cartNotifier.addItem(meal2);
      await tester.pumpAndSettle();

      // Ensure pickup is still selected.
      cartNotifier.setDeliveryOption(DeliveryOption.pickup);
      await tester.pumpAndSettle();

      // Checkout button should be enabled since meal-2 is not in the
      // unavailable set and all items are available.
      final enabledCheckoutFinder =
          find.widgetWithText(FilledButton, 'Checkout');
      expect(enabledCheckoutFinder, findsOneWidget);
      final enabledCheckoutButton =
          tester.widget<FilledButton>(enabledCheckoutFinder);
      expect(enabledCheckoutButton.onPressed, isNotNull,
          reason:
              'Checkout should be enabled after removing unavailable item');
    },
  );
}
