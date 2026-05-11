import 'package:akka_food/features/cart/domain/entities/cart.dart';

/// Abstract interface for cart persistence.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implementations live in the data layer (e.g. [HiveCartDataSource]).
///
/// The domain layer depends only on this interface, keeping it decoupled
/// from any specific storage technology.
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
}
