// integration_test/cart_flow_test.dart
//
// Task 7.1 — Add meal → view cart → update quantity → remove item
//
// Tests the complete cart flow using a ProviderScope with overrides so no
// real Firebase / Hive connection is needed. Follows the same pattern as
// auth_flow_test.dart.

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
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';
import 'package:akka_food/features/coins/presentation/notifiers/coin_notifier.dart';
import 'package:akka_food/features/coins/domain/entities/coin_balance.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-cart-test',
      email: 'cart@example.com',
      displayName: 'Cart Tester',
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
// Helper — builds CartScreen wrapped in ProviderScope with overrides
// =============================================================================

Widget _buildCartApp({
  required FakeCartRepository fakeRepo,
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
// FakeAddressNotifier — returns empty address list
// =============================================================================

class _FakeAddressNotifier extends AddressNotifier {
  @override
  Future<List<DeliveryAddress>> build() async => [];
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'add meal → view cart → update quantity → remove item',
    (WidgetTester tester) async {
      final fakeRepo = FakeCartRepository();
      final user = _fakeUser();

      await tester.pumpWidget(_buildCartApp(
        fakeRepo: fakeRepo,
        user: user,
      ));
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 1: Cart starts empty — verify empty state is shown (Req 2.3)
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Browse Menu'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 2: Add a meal to the cart via the CartNotifier (Req 1.1)
      // ─────────────────────────────────────────────────────────────────────
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CartScreen)),
      );
      final cartNotifier = container.read(cartNotifierProvider.notifier);
      final meal = _testMeal();

      cartNotifier.addItem(meal);
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Step 3: View cart — verify item appears with correct details (Req 2.1)
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Your cart is empty'), findsNothing);
      expect(find.text('Jollof Rice'), findsOneWidget);
      expect(find.text('2500 XOF'), findsWidgets); // unit price and/or line total
      // Quantity should be 1
      expect(find.text('1'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 4: Update quantity — tap + button to increase to 2 (Req 3.1)
      // ─────────────────────────────────────────────────────────────────────
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Quantity should now be 2
      expect(find.text('2'), findsOneWidget);
      // Line total should be 5000 XOF (2500 × 2)
      expect(find.text('5000 XOF'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 5: Tap + again to increase to 3 (Req 3.1)
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('7500 XOF'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 6: Decrease quantity — tap − button to go from 3 → 2 (Req 3.1)
      // ─────────────────────────────────────────────────────────────────────
      final removeButton = find.byIcon(Icons.remove);
      expect(removeButton, findsOneWidget);
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 7: Decrease to 1 (Req 3.1)
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      // ─────────────────────────────────────────────────────────────────────
      // Step 8: Decrease to 0 — item should be removed (Req 3.2)
      //         Cart should show empty state again (Req 4.2)
      // ─────────────────────────────────────────────────────────────────────
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(find.text('Jollof Rice'), findsNothing);
      expect(find.text('Your cart is empty'), findsOneWidget);
    },
  );
}
