import 'dart:math' show min;

import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/cart/data/datasources/hive_cart_datasource.dart';
import 'package:akka_food/features/cart/data/repositories/cart_repository.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/domain/entities/cart_validation_result.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_notifier.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cart_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [CartRepository] bound to [ICartRepository].
///
/// Opens the Hive cart box and wires up the [MealRepository] for
/// availability re-checks at checkout.
///
/// Requires an authenticated user — returns `null` when no user is signed in.
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
Future<ICartRepository?> cartRepository(Ref ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final cartDataSource = await HiveCartDataSource.open();
  final mealRepository = ref.watch(mealRepositoryProvider);

  return CartRepository(
    uid: currentUser.uid,
    cartDataSource: cartDataSource,
    mealRepository: mealRepository,
  );
}

// ---------------------------------------------------------------------------
// CartNotifier
// ---------------------------------------------------------------------------

/// Manages the in-memory [Cart] state for the UI layer.
///
/// Synchronous [Notifier<Cart>] — all cart mutations are local and
/// instantaneous; persistence to Hive is handled by a separate listener
/// (Task 3.5).
///
/// Exposed methods:
/// - [addItem]               — add a [Meal] to the cart (Req 1.1, 1.2, 1.3)
/// - [removeItem]            — remove a CartItem by mealId (Req 4.1)
/// - [updateQuantity]        — set a CartItem's quantity (Req 3.1–3.4)
/// - [clearCart]             — reset to an empty cart (Req 5.1)
/// - [setDeliveryOption]     — switch between Delivery and Pickup (Req 6.1–6.3)
/// - [setDeliveryAddress]    — set the delivery address (Req 6.2)
/// - [applyCoins]            — redeem max coins against the current subtotal (Req 7.2–7.4)
/// - [removeCoins]           — remove coin redemption discount (Req 7.5)
/// - [validateForCheckout]   — validate cart before checkout (Req 8.1, 8.2, 8.4, 9.3)
@riverpod
class CartNotifier extends _$CartNotifier {
  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  /// Returns an empty [Cart] as the initial state.
  ///
  /// Delivery is the default option; no address or coin redemption is set.
  ///
  /// Registers a [ref.listenSelf] listener that persists the cart to Hive on
  /// every state change (Req 9.1). Errors are logged silently so the cart
  /// continues to work in-memory even when persistence fails.
  ///
  /// Schedules an async restore from Hive via [Future.microtask] so that the
  /// previously saved cart is loaded after the initial synchronous build
  /// completes (Req 9.2).
  /// Whether the cart has been restored from Hive. Used to prevent the
  /// auto-save listener from overwriting the saved cart with an empty one
  /// before the restore completes.
  bool _restored = false;

  @override
  Cart build() {
    // Watch the current user — when auth state changes (e.g. after page
    // refresh and session restore), the notifier rebuilds and restores the
    // cart from Hive.
    final currentUser = ref.watch(currentUserProvider);
    _restored = false;

    // Auto-save listener: persist cart to Hive on every state change (Req 9.1).
    // Only saves after the initial restore is complete to avoid overwriting
    // the saved cart with an empty one.
    listenSelf((_, cart) async {
      if (!_restored) return; // Don't save until restore is done.
      final repository = await ref.read(cartRepositoryProvider.future);
      if (repository == null) return; // No authenticated user — skip saving.
      try {
        await repository.save(cart);
      } catch (e) {
        // Log silently — cart still works in-memory (design.md: "Hive save fails → Log error silently").
        debugPrint('CartNotifier: failed to save cart to Hive: $e');
      }
    });

    // Restore cart from Hive asynchronously after the initial build (Req 9.2).
    if (currentUser != null) {
      Future.microtask(_restoreCart);
    }

    return Cart.empty();
  }

  // ---------------------------------------------------------------------------
  // _restoreCart
  // ---------------------------------------------------------------------------

  /// Loads the previously saved [Cart] from Hive and restores it as the
  /// current state.
  ///
  /// Called once after [build] via [Future.microtask] so it does not block
  /// the synchronous build cycle.
  ///
  /// Business rules:
  /// - If no authenticated user is available, the restore is skipped.
  /// - If no saved cart exists in Hive, the empty initial state is kept.
  /// - Restored items retain their persisted [CartItem.isAvailable] flag;
  ///   availability is re-validated at checkout via [validateForCheckout]
  ///   (Req 9.3).
  /// - Errors are logged silently so the cart continues to work in-memory.
  Future<void> _restoreCart() async {
    try {
      final repository = await ref.read(cartRepositoryProvider.future);
      if (repository == null) {
        _restored = true;
        return;
      }

      final savedCart = await repository.load();
      if (savedCart != null) {
        state = savedCart;
      }
      _restored = true;
    } catch (e) {
      // Log silently — cart still works in-memory.
      debugPrint('CartNotifier: failed to restore cart from Hive: $e');
      _restored = true;
    }
  }

  // ---------------------------------------------------------------------------
  // addItem
  // ---------------------------------------------------------------------------

  /// Adds [meal] to the cart, or increments its quantity if already present.
  ///
  /// Business rules:
  /// - If [meal.isAvailable] is `false`, the action is silently ignored.
  ///   The UI layer is responsible for showing an "Item unavailable" error
  ///   (Requirement 1.3).
  /// - If the meal is already in the cart, its quantity is incremented by 1,
  ///   capped at [_maxQuantity] (Requirement 1.2, 3.4).
  /// - Otherwise a new [CartItem] is added with quantity 1 (Requirement 1.1).
  void addItem(Meal meal) {
    // Req 1.3 — reject unavailable meals.
    if (!meal.isAvailable) return;

    final currentItems = state.items;
    final existingIndex =
        currentItems.indexWhere((item) => item.mealId == meal.id);

    if (existingIndex >= 0) {
      // Req 1.2 — increment quantity, capped at max (Req 3.4).
      final existing = currentItems[existingIndex];
      final newQuantity = (existing.quantity + 1).clamp(1, _maxQuantity);
      final updatedItems = List<CartItem>.from(currentItems);
      updatedItems[existingIndex] = existing.copyWith(quantity: newQuantity);
      state = state.copyWith(items: updatedItems);
    } else {
      // Req 1.1 — add new item with quantity 1.
      final newItem = CartItem(
        mealId: meal.id,
        mealName: meal.name,
        mealImageUrl: meal.imageUrls.isNotEmpty ? meal.imageUrls.first : '',
        unitPrice: meal.price,
        quantity: 1,
        isAvailable: true,
      );
      state = state.copyWith(items: [...currentItems, newItem]);
    }
  }

  // ---------------------------------------------------------------------------
  // removeItem
  // ---------------------------------------------------------------------------

  /// Removes the [CartItem] with [mealId] from the cart.
  ///
  /// If no item with [mealId] exists, the state is unchanged.
  ///
  /// Satisfies Requirement 4.1.
  void removeItem(String mealId) {
    final updatedItems =
        state.items.where((item) => item.mealId != mealId).toList();
    state = state.copyWith(items: updatedItems);
  }

  // ---------------------------------------------------------------------------
  // updateQuantity
  // ---------------------------------------------------------------------------

  /// Sets the quantity of the [CartItem] identified by [mealId] to [quantity].
  ///
  /// Business rules:
  /// - [quantity] ≤ 0 → item is removed (Req 3.2, 3.3).
  /// - [quantity] > [_maxQuantity] → capped at [_maxQuantity] (Req 3.4).
  /// - Otherwise the quantity is set to [quantity] (Req 3.1).
  ///
  /// If no item with [mealId] exists, the state is unchanged.
  void updateQuantity(String mealId, int quantity) {
    if (quantity <= 0) {
      // Req 3.2 / 3.3 — decreasing to 0 removes the item.
      removeItem(mealId);
      return;
    }

    final clampedQuantity = quantity.clamp(1, _maxQuantity);
    final updatedItems = state.items.map((item) {
      if (item.mealId == mealId) {
        return item.copyWith(quantity: clampedQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  // ---------------------------------------------------------------------------
  // clearCart
  // ---------------------------------------------------------------------------

  /// Resets the cart to its empty initial state.
  ///
  /// The confirmation dialog is handled by the UI layer before calling this
  /// method (Requirement 5.1).
  void clearCart() {
    state = Cart(
      items: const [],
      deliveryOption: DeliveryOption.delivery,
      selectedAddress: null,
      redeemedCoins: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // setDeliveryOption
  // ---------------------------------------------------------------------------

  /// Switches the cart's delivery method to [option].
  ///
  /// Business rules:
  /// - Switching to [DeliveryOption.pickup] clears [Cart.selectedAddress]
  ///   because no address is needed for pickup (Req 6.3).
  /// - Switching to [DeliveryOption.delivery] preserves any existing address
  ///   so the user does not have to re-select it (Req 6.2).
  ///
  /// Satisfies Requirements 6.1, 6.2, 6.3.
  void setDeliveryOption(DeliveryOption option) {
    if (option == DeliveryOption.pickup) {
      // Req 6.3 — Pickup: zero delivery fee, no address required.
      state = state.copyWith(
        deliveryOption: option,
        selectedAddress: null,
      );
    } else {
      // Req 6.2 — Delivery: apply delivery fee, keep existing address if any.
      state = state.copyWith(deliveryOption: option);
    }
  }

  // ---------------------------------------------------------------------------
  // setDeliveryAddress
  // ---------------------------------------------------------------------------

  /// Sets the delivery address to [address].
  ///
  /// Only meaningful when [Cart.deliveryOption] is [DeliveryOption.delivery].
  /// The UI layer is responsible for ensuring this is only called in that
  /// context (Req 6.2).
  ///
  /// Satisfies Requirement 6.2.
  void setDeliveryAddress(DeliveryAddress address) {
    state = state.copyWith(selectedAddress: address);
  }

  // ---------------------------------------------------------------------------
  // applyCoins
  // ---------------------------------------------------------------------------

  /// Applies the maximum redeemable coins from [coinBalance] as a discount.
  ///
  /// The maximum redeemable amount is the largest multiple of 1 000 that:
  /// - does not exceed [coinBalance] (rounded down to the nearest 1 000), AND
  /// - does not exceed the current [Cart.subtotal] in XOF (1 coin = 1 XOF).
  ///
  /// The result is always a non-negative multiple of 1 000.
  ///
  /// Satisfies Requirements 7.2, 7.3, 7.4.
  void applyCoins(int coinBalance) {
    final coins = _calculateMaxRedeemableCoins(coinBalance, state.subtotal);
    state = state.copyWith(redeemedCoins: coins);
  }

  // ---------------------------------------------------------------------------
  // removeCoins
  // ---------------------------------------------------------------------------

  /// Removes any active coin redemption, resetting the discount to zero.
  ///
  /// Satisfies Requirement 7.5.
  void removeCoins() {
    state = state.copyWith(redeemedCoins: 0);
  }

  // ---------------------------------------------------------------------------
  // validateForCheckout
  // ---------------------------------------------------------------------------

  /// Validates the cart before proceeding to checkout.
  ///
  /// Validation steps:
  /// 1. Check if cart is empty (Req 8.1)
  /// 2. Re-check availability of all items against the remote catalog (Req 8.4, 9.3)
  /// 3. Update state with re-checked availability flags
  /// 4. Collect unavailable meal IDs
  /// 5. Check if delivery address is required but missing (Req 8.2)
  /// 6. Return [CartValidationResult] with all validation flags
  ///
  /// [CartValidationResult.isValid] is `true` only when:
  /// - Cart is not empty
  /// - All items are available
  /// - Delivery address is present when delivery is selected
  ///
  /// Satisfies Requirements 8.1, 8.2, 8.4, 9.3.
  Future<CartValidationResult> validateForCheckout() async {
    // Step 1: Check if cart is empty (Req 8.1).
    if (state.items.isEmpty) {
      return const CartValidationResult(
        isValid: false,
        unavailableMealIds: [],
        missingDeliveryAddress: false,
        emptyCart: true,
      );
    }

    // Step 2: Re-check availability via CartRepository (Req 8.4, 9.3).
    final repository = await ref.read(cartRepositoryProvider.future);
    if (repository == null) {
      // No authenticated user — treat as validation failure.
      return const CartValidationResult(
        isValid: false,
        unavailableMealIds: [],
        missingDeliveryAddress: false,
        emptyCart: false,
      );
    }

    final recheckedCart = await repository.recheckAvailability(state);

    // Step 3: Update state with re-checked cart so UI can highlight unavailable items.
    state = recheckedCart;

    // Step 4: Collect unavailable meal IDs.
    final unavailableMealIds = recheckedCart.items
        .where((item) => !item.isAvailable)
        .map((item) => item.mealId)
        .toList();

    // Step 5: Check if delivery address is required but missing (Req 8.2).
    final missingDeliveryAddress = recheckedCart.deliveryOption ==
            DeliveryOption.delivery &&
        recheckedCart.selectedAddress == null;

    // Step 6: Determine overall validity.
    final isValid = unavailableMealIds.isEmpty && !missingDeliveryAddress;

    return CartValidationResult(
      isValid: isValid,
      unavailableMealIds: unavailableMealIds,
      missingDeliveryAddress: missingDeliveryAddress,
      emptyCart: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Maximum allowed quantity per CartItem (Requirement 3.4).
  static const int _maxQuantity = 20;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Calculates the maximum redeemable coins given [coinBalance] and [subtotal].
  ///
  /// Formula:
  /// 1. Round [coinBalance] down to the nearest 1 000 → maxByBalance
  /// 2. Floor [subtotal] to an integer → maxBySubtotal
  /// 3. Take the minimum of the two → maxRedeemable
  /// 4. Round down to the nearest 1 000 → final result
  ///
  /// This ensures:
  /// - Redemption never exceeds the user's balance (Req 7.2)
  /// - Redemption never exceeds the subtotal (Req 7.2)
  /// - Redemption is always a multiple of 1 000 (Req 7.2)
  /// - Total never goes negative (Req 7.4, enforced by Cart.total getter)
  static int _calculateMaxRedeemableCoins(int coinBalance, double subtotal) {
    final maxByBalance = (coinBalance ~/ 1000) * 1000;
    final maxBySubtotal = subtotal.floor();
    final maxRedeemable = min(maxByBalance, maxBySubtotal);
    return (maxRedeemable ~/ 1000) * 1000; // round down to nearest 1000
  }
}
