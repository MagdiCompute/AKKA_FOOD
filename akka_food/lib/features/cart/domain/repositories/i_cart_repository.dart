import 'package:akka_food/features/cart/domain/entities/cart.dart';

/// Abstract interface for cart persistence and availability validation.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implementations live in the data layer (e.g. [CartRepository]).
///
/// The domain layer depends only on this interface, keeping it decoupled
/// from any specific storage technology or remote data source.
abstract class ICartRepository {
  /// Persists [cart] to local storage.
  ///
  /// Called after every cart modification to ensure the cart survives
  /// app restarts (Requirement 9.1).
  Future<void> save(Cart cart);

  /// Loads the previously persisted cart from local storage.
  ///
  /// Returns `null` if no cart has been saved yet.
  /// Called on app launch to restore the cart (Requirement 9.2).
  Future<Cart?> load();

  /// Removes the persisted cart from local storage.
  ///
  /// Called after a successful order placement or when the user
  /// explicitly clears the cart.
  Future<void> clear();

  /// Re-checks the availability of every [CartItem] in [cart] against the
  /// remote meal catalog and returns an updated [Cart] with each item's
  /// [CartItem.isAvailable] flag set to the current value from the catalog.
  ///
  /// Items whose meal is not found in the catalog are marked unavailable.
  /// Called during checkout validation (Requirement 8.4, 9.3).
  Future<Cart> recheckAvailability(Cart cart);
}
