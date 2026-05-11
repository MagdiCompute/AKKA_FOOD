// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cartRepositoryHash() => r'2f64ab4c9ce6c10f26e273eedc1df40671a4e4cf';

/// Provides the concrete [CartRepository] bound to [ICartRepository].
///
/// Opens the Hive cart box and wires up the [MealRepository] for
/// availability re-checks at checkout.
///
/// Requires an authenticated user — returns `null` when no user is signed in.
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [cartRepository].
@ProviderFor(cartRepository)
final cartRepositoryProvider =
    AutoDisposeFutureProvider<ICartRepository?>.internal(
      cartRepository,
      name: r'cartRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cartRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CartRepositoryRef = AutoDisposeFutureProviderRef<ICartRepository?>;
String _$cartNotifierHash() => r'555a4b5a90489a1c303fe6f1f6ab051301a241df';

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
///
/// Copied from [CartNotifier].
@ProviderFor(CartNotifier)
final cartNotifierProvider =
    AutoDisposeNotifierProvider<CartNotifier, Cart>.internal(
      CartNotifier.new,
      name: r'cartNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cartNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CartNotifier = AutoDisposeNotifier<Cart>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
