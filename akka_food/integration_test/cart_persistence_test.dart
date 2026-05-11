// integration_test/cart_persistence_test.dart
//
// Task 7.3 — Cart persists across app restart
//
// Tests that the cart is auto-saved after modification (Req 9.1) and restored
// on app relaunch (Req 9.2). Simulates an app restart by:
// 1. Adding items to the cart via CartNotifier (triggers listenSelf auto-save)
// 2. Verifying the FakeCartRepository received the saved cart
// 3. Creating a new ProviderScope with the same FakeCartRepository (now
//    returning the saved cart from load()) to simulate a fresh app launch
// 4. Verifying the CartScreen shows the previously added items
//
// Follows the same pattern as cart_flow_test.dart.

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
      uid: 'uid-persistence-test',
      email: 'persist@example.com',
      displayName: 'Persistence Tester',
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
// FakeCartRepository — simulates Hive persistence in memory
// =============================================================================

/// A fake repository that stores the cart in memory, simulating Hive.
///
/// - [save] stores the cart in [savedCart].
/// - [load] returns [cartToLoad] (set externally to simulate a pre-existing
///   persisted cart on app relaunch).
/// - After the first session saves, we set [cartToLoad] = [savedCart] so the
///   next "app launch" restores it.
class FakeCartRepository implements ICartRepository {
  Cart? savedCart;
  Cart? cartToLoad;

  @override
  Future<void> save(Cart cart) async {
    savedCart = cart;
  }

  @override
  Future<Cart?> load() async => cartToLoad;

  @override
  Future<void> clear() async {
    savedCart = null;
    cartToLoad = null;
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
}) {
  return ProviderScope(
    overrides: [
      cartRepositoryProvider.overrideWith((_) async => fakeRepo),
      currentUserProvider.overrideWith((ref) => user),
      coinBalanceProvider.overrideWithValue(
        CoinBalance.fromTotal(0),
      ),
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
    'cart persists across app restart (Req 9.1, 9.2)',
    (WidgetTester tester) async {
      final fakeRepo = FakeCartRepository();
      final user = _fakeUser();

      // ─────────────────────────────────────────────────────────────────────
      // SESSION 1: Add items to cart — auto-save should persist them
      // ─────────────────────────────────────────────────────────────────────

      await tester.pumpWidget(_buildCartApp(
        fakeRepo: fakeRepo,
        user: user,
      ));
      await tester.pumpAndSettle();

      // Cart starts empty
      expect(find.text('Your cart is empty'), findsOneWidget);

      // Add a meal via CartNotifier (Req 1.1)
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CartScreen)),
      );
      final cartNotifier = container.read(cartNotifierProvider.notifier);
      final meal = _testMeal();

      cartNotifier.addItem(meal);
      await tester.pumpAndSettle();

      // Verify item appears in the cart
      expect(find.text('Jollof Rice'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // quantity

      // ─────────────────────────────────────────────────────────────────────
      // Verify auto-save (Req 9.1): the listenSelf callback should have
      // persisted the cart to the FakeCartRepository
      // ─────────────────────────────────────────────────────────────────────
      // Allow async save to complete
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.savedCart, isNotNull,
          reason: 'Cart should be auto-saved after modification (Req 9.1)');
      expect(fakeRepo.savedCart!.items.length, equals(1));
      expect(fakeRepo.savedCart!.items.first.mealId, equals('meal-1'));
      expect(fakeRepo.savedCart!.items.first.mealName, equals('Jollof Rice'));

      // ─────────────────────────────────────────────────────────────────────
      // SESSION 2: Simulate app restart — set cartToLoad to the saved cart
      // so that _restoreCart() picks it up on the new ProviderScope
      // ─────────────────────────────────────────────────────────────────────
      fakeRepo.cartToLoad = fakeRepo.savedCart;

      // Rebuild the widget tree with a fresh ProviderScope (simulates restart)
      await tester.pumpWidget(_buildCartApp(
        fakeRepo: fakeRepo,
        user: user,
      ));
      await tester.pumpAndSettle();

      // ─────────────────────────────────────────────────────────────────────
      // Verify cart is restored (Req 9.2): the CartNotifier should have
      // called _restoreCart() and loaded the previously saved cart
      // ─────────────────────────────────────────────────────────────────────
      expect(find.text('Your cart is empty'), findsNothing,
          reason: 'Cart should be restored from storage on relaunch (Req 9.2)');
      expect(find.text('Jollof Rice'), findsOneWidget,
          reason: 'Previously added item should appear after restore');
      expect(find.text('2500 XOF'), findsWidgets,
          reason: 'Item price should be displayed after restore');
    },
  );

  testWidgets(
    'cart with multiple items persists and restores correctly (Req 9.1, 9.2)',
    (WidgetTester tester) async {
      final fakeRepo = FakeCartRepository();
      final user = _fakeUser();

      // ─────────────────────────────────────────────────────────────────────
      // SESSION 1: Add multiple items with different quantities
      // ─────────────────────────────────────────────────────────────────────

      await tester.pumpWidget(_buildCartApp(
        fakeRepo: fakeRepo,
        user: user,
      ));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CartScreen)),
      );
      final cartNotifier = container.read(cartNotifierProvider.notifier);

      // Add two different meals
      final meal1 = _testMeal(id: 'meal-1', name: 'Jollof Rice', price: 2500);
      final meal2 = _testMeal(id: 'meal-2', name: 'Fried Plantain', price: 1500);

      cartNotifier.addItem(meal1);
      cartNotifier.addItem(meal2);
      // Increase quantity of meal1 to 2
      cartNotifier.updateQuantity('meal-1', 2);
      await tester.pumpAndSettle();

      // Allow async save to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Verify auto-save captured both items with correct quantities
      expect(fakeRepo.savedCart, isNotNull);
      expect(fakeRepo.savedCart!.items.length, equals(2));

      final savedMeal1 =
          fakeRepo.savedCart!.items.firstWhere((i) => i.mealId == 'meal-1');
      final savedMeal2 =
          fakeRepo.savedCart!.items.firstWhere((i) => i.mealId == 'meal-2');
      expect(savedMeal1.quantity, equals(2));
      expect(savedMeal2.quantity, equals(1));

      // ─────────────────────────────────────────────────────────────────────
      // SESSION 2: Simulate app restart
      // ─────────────────────────────────────────────────────────────────────
      fakeRepo.cartToLoad = fakeRepo.savedCart;

      await tester.pumpWidget(_buildCartApp(
        fakeRepo: fakeRepo,
        user: user,
      ));
      await tester.pumpAndSettle();

      // Verify both items are restored
      expect(find.text('Jollof Rice'), findsOneWidget,
          reason: 'First item should be restored');
      expect(find.text('Fried Plantain'), findsOneWidget,
          reason: 'Second item should be restored');
      // Verify quantity of meal1 is still 2
      expect(find.text('2'), findsOneWidget,
          reason: 'Quantity of first item should be preserved');
    },
  );
}
