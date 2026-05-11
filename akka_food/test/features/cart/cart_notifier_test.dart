import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

/// A simple in-memory [ICartRepository] that records save/load calls and
/// allows tests to control the [recheckAvailability] response.
class FakeCartRepository implements ICartRepository {
  Cart? savedCart;
  Cart? cartToLoad;

  /// When set, [recheckAvailability] returns this cart instead of the input.
  Cart? recheckResult;

  @override
  Future<void> save(Cart cart) async {
    savedCart = cart;
  }

  @override
  Future<Cart?> load() async => cartToLoad;

  @override
  Future<void> clear() async {
    savedCart = null;
  }

  @override
  Future<Cart> recheckAvailability(Cart cart) async {
    return recheckResult ?? cart;
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Builds a [ProviderContainer] with the [FakeCartRepository] injected and
/// the [cartRepositoryProvider] overridden so no Hive / Firebase is touched.
///
/// The [cartRepositoryProvider] is an async provider (`Future<ICartRepository?>`),
/// so we override it with a synchronous value.
ProviderContainer makeContainer(FakeCartRepository repo) {
  return ProviderContainer(
    overrides: [
      cartRepositoryProvider.overrideWith((_) async => repo),
    ],
  );
}

/// Creates a test [Meal] with sensible defaults.
Meal makeMeal({
  String id = 'meal-1',
  String name = 'Test Meal',
  double price = 2000.0,
  bool isAvailable = true,
  List<String> imageUrls = const ['https://example.com/img.jpg'],
}) =>
    Meal(
      id: id,
      name: name,
      description: 'A test meal',
      price: price,
      categoryId: 'cat-1',
      imageUrls: imageUrls,
      isAvailable: isAvailable,
      isFeatured: false,
      featuredOrder: 0,
      nutritionalInfo: null,
      dietaryTags: const [],
      popularityScore: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

/// Creates a test [DeliveryAddress].
DeliveryAddress makeAddress({String id = 'addr-1'}) => DeliveryAddress(
      id: id,
      uid: 'user-1',
      label: 'Home',
      streetAddress: '123 Main St',
      city: 'Abidjan',
      isDefault: true,
      createdAt: DateTime(2024, 1, 1),
    );

/// Reads the current [Cart] state from [container].
Cart cartState(ProviderContainer container) =>
    container.read(cartNotifierProvider);

/// Reads the [CartNotifier] from [container].
CartNotifier notifier(ProviderContainer container) =>
    container.read(cartNotifierProvider.notifier);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // addItem
  // -------------------------------------------------------------------------
  group('CartNotifier.addItem', () {
    test('adding an available meal creates a CartItem with quantity 1', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);

      final cart = cartState(container);
      expect(cart.items.length, 1);
      expect(cart.items.first.mealId, meal.id);
      expect(cart.items.first.quantity, 1);
      expect(cart.items.first.unitPrice, meal.price);
      expect(cart.items.first.mealName, meal.name);
      expect(cart.items.first.isAvailable, isTrue);
    });

    test('adding the same meal again increments quantity to 2', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).addItem(meal);

      final cart = cartState(container);
      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 2);
    });

    test('adding an unavailable meal is rejected — cart stays empty', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal(isAvailable: false);
      notifier(container).addItem(meal);

      final cart = cartState(container);
      expect(cart.items, isEmpty);
    });

    test('adding a meal when quantity is already 20 keeps it at 20 (max cap)',
        () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      // Add 20 times to reach the cap.
      for (var i = 0; i < 20; i++) {
        notifier(container).addItem(meal);
      }
      // One more — should stay at 20.
      notifier(container).addItem(meal);

      final cart = cartState(container);
      expect(cart.items.first.quantity, 20);
    });
  });

  // -------------------------------------------------------------------------
  // removeItem
  // -------------------------------------------------------------------------
  group('CartNotifier.removeItem', () {
    test('removing an existing item removes it from the cart', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal1 = makeMeal(id: 'meal-1');
      final meal2 = makeMeal(id: 'meal-2');
      notifier(container).addItem(meal1);
      notifier(container).addItem(meal2);

      notifier(container).removeItem('meal-1');

      final cart = cartState(container);
      expect(cart.items.length, 1);
      expect(cart.items.first.mealId, 'meal-2');
    });

    test('removing the last item results in an empty cart', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).removeItem(meal.id);

      final cart = cartState(container);
      expect(cart.items, isEmpty);
    });

    test('removing a non-existent mealId does nothing', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);

      notifier(container).removeItem('non-existent-id');

      final cart = cartState(container);
      expect(cart.items.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // updateQuantity
  // -------------------------------------------------------------------------
  group('CartNotifier.updateQuantity', () {
    test('setting quantity to 5 updates the item', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).updateQuantity(meal.id, 5);

      final cart = cartState(container);
      expect(cart.items.first.quantity, 5);
    });

    test('setting quantity to 0 removes the item', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).updateQuantity(meal.id, 0);

      final cart = cartState(container);
      expect(cart.items, isEmpty);
    });

    test('setting quantity to -1 removes the item', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).updateQuantity(meal.id, -1);

      final cart = cartState(container);
      expect(cart.items, isEmpty);
    });

    test('setting quantity to 21 caps at 20', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).updateQuantity(meal.id, 21);

      final cart = cartState(container);
      expect(cart.items.first.quantity, 20);
    });

    test('updating a non-existent mealId does nothing', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);

      notifier(container).updateQuantity('non-existent-id', 5);

      final cart = cartState(container);
      // Original item is unchanged.
      expect(cart.items.length, 1);
      expect(cart.items.first.quantity, 1);
    });
  });

  // -------------------------------------------------------------------------
  // clearCart
  // -------------------------------------------------------------------------
  group('CartNotifier.clearCart', () {
    test('clearCart removes all items', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      notifier(container).addItem(makeMeal(id: 'meal-1'));
      notifier(container).addItem(makeMeal(id: 'meal-2'));
      notifier(container).clearCart();

      final cart = cartState(container);
      expect(cart.items, isEmpty);
    });

    test('clearCart resets delivery option to delivery', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      notifier(container).setDeliveryOption(DeliveryOption.pickup);
      notifier(container).clearCart();

      final cart = cartState(container);
      expect(cart.deliveryOption, DeliveryOption.delivery);
    });

    test('clearCart resets redeemedCoins to 0', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      // Add a meal so subtotal > 0, then apply coins.
      notifier(container).addItem(makeMeal(price: 3000.0));
      notifier(container).applyCoins(2000);
      expect(cartState(container).redeemedCoins, 2000);

      notifier(container).clearCart();

      final cart = cartState(container);
      expect(cart.redeemedCoins, 0);
    });
  });

  // -------------------------------------------------------------------------
  // applyCoins / removeCoins
  // -------------------------------------------------------------------------
  group('CartNotifier.applyCoins / removeCoins', () {
    test(
        'applyCoins with balance 2500 and subtotal 3000 → redeemedCoins = 2000',
        () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      // subtotal = 3000 (1 item × 3000 XOF)
      notifier(container).addItem(makeMeal(price: 3000.0));
      notifier(container).applyCoins(2500);

      // maxByBalance = (2500 ~/ 1000) * 1000 = 2000
      // maxBySubtotal = 3000.floor() = 3000
      // min(2000, 3000) = 2000 → (2000 ~/ 1000) * 1000 = 2000
      expect(cartState(container).redeemedCoins, 2000);
    });

    test('applyCoins with balance 500 (< 1000) → redeemedCoins = 0', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      notifier(container).addItem(makeMeal(price: 3000.0));
      notifier(container).applyCoins(500);

      // maxByBalance = (500 ~/ 1000) * 1000 = 0
      expect(cartState(container).redeemedCoins, 0);
    });

    test(
        'applyCoins where subtotal < balance → capped at subtotal rounded down to nearest 1000',
        () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      // subtotal = 1500 XOF, balance = 5000 coins
      notifier(container).addItem(makeMeal(price: 1500.0));
      notifier(container).applyCoins(5000);

      // maxByBalance = (5000 ~/ 1000) * 1000 = 5000
      // maxBySubtotal = 1500.floor() = 1500
      // min(5000, 1500) = 1500 → (1500 ~/ 1000) * 1000 = 1000
      expect(cartState(container).redeemedCoins, 1000);
    });

    test('removeCoins resets redeemedCoins to 0', () {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      notifier(container).addItem(makeMeal(price: 3000.0));
      notifier(container).applyCoins(2000);
      expect(cartState(container).redeemedCoins, 2000);

      notifier(container).removeCoins();

      expect(cartState(container).redeemedCoins, 0);
    });
  });

  // -------------------------------------------------------------------------
  // validateForCheckout
  // -------------------------------------------------------------------------
  group('CartNotifier.validateForCheckout', () {
    test('empty cart returns isValid=false, emptyCart=true', () async {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final result = await notifier(container).validateForCheckout();

      expect(result.isValid, isFalse);
      expect(result.emptyCart, isTrue);
      expect(result.unavailableMealIds, isEmpty);
      expect(result.missingDeliveryAddress, isFalse);
    });

    test(
        'cart with unavailable item returns isValid=false, '
        'unavailableMealIds contains the mealId', () async {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal(id: 'meal-unavailable');
      notifier(container).addItem(meal);

      // recheckAvailability returns the cart with the item marked unavailable.
      final unavailableItem = CartItem(
        mealId: meal.id,
        mealName: meal.name,
        mealImageUrl: meal.imageUrls.first,
        unitPrice: meal.price,
        quantity: 1,
        isAvailable: false,
      );
      repo.recheckResult = cartState(container).copyWith(
        items: [unavailableItem],
      );

      // Set a delivery address so that's not the failure reason.
      notifier(container).setDeliveryAddress(makeAddress());

      final result = await notifier(container).validateForCheckout();

      expect(result.isValid, isFalse);
      expect(result.unavailableMealIds, contains('meal-unavailable'));
      expect(result.emptyCart, isFalse);
    });

    test(
        'delivery selected but no address returns isValid=false, '
        'missingDeliveryAddress=true', () async {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);

      // recheckAvailability returns the cart unchanged (all items available).
      // No address is set and delivery is the default option.

      final result = await notifier(container).validateForCheckout();

      expect(result.isValid, isFalse);
      expect(result.missingDeliveryAddress, isTrue);
      expect(result.emptyCart, isFalse);
      expect(result.unavailableMealIds, isEmpty);
    });

    test(
        'valid cart (items available, delivery address set) returns isValid=true',
        () async {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).setDeliveryAddress(makeAddress());

      // recheckAvailability returns the cart unchanged (all items available).

      final result = await notifier(container).validateForCheckout();

      expect(result.isValid, isTrue);
      expect(result.emptyCart, isFalse);
      expect(result.unavailableMealIds, isEmpty);
      expect(result.missingDeliveryAddress, isFalse);
    });

    test('valid cart with pickup option (no address needed) returns isValid=true',
        () async {
      final repo = FakeCartRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);

      final meal = makeMeal();
      notifier(container).addItem(meal);
      notifier(container).setDeliveryOption(DeliveryOption.pickup);

      final result = await notifier(container).validateForCheckout();

      expect(result.isValid, isTrue);
      expect(result.missingDeliveryAddress, isFalse);
    });
  });
}
