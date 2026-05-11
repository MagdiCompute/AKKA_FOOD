import 'package:akka_food/features/cart/data/datasources/hive_cart_datasource.dart';
import 'package:akka_food/features/cart/domain/entities/cart.dart';
import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/domain/repositories/i_cart_repository.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_meal_repository.dart';

// ---------------------------------------------------------------------------
// CartRepository
// ---------------------------------------------------------------------------

/// Concrete implementation of [ICartRepository].
///
/// Composes:
/// - [HiveCartDataSource] — local Hive persistence (save, load, clear).
/// - [IMealRepository] — remote meal catalog (availability re-check at
///   checkout).
///
/// The [uid] identifies the currently signed-in user. It is provided at
/// construction time so that [save], [load], and [clear] can delegate to the
/// uid-keyed [HiveCartDataSource] API without exposing the uid in the
/// [ICartRepository] interface.
///
/// Firebase imports are intentionally absent from this class; all remote
/// access is mediated through [IMealRepository].
class CartRepository implements ICartRepository {
  CartRepository({
    required String uid,
    required HiveCartDataSource cartDataSource,
    required IMealRepository mealRepository,
  })  : _uid = uid,
        _cartDataSource = cartDataSource,
        _mealRepository = mealRepository;

  final String _uid;
  final HiveCartDataSource _cartDataSource;
  final IMealRepository _mealRepository;

  // -------------------------------------------------------------------------
  // ICartRepository — persistence
  // -------------------------------------------------------------------------

  /// Persists [cart] to local Hive storage, keyed by the current user's [uid].
  ///
  /// Satisfies Requirement 9.1: cart is saved after every modification.
  @override
  Future<void> save(Cart cart) => _cartDataSource.saveCart(_uid, cart);

  /// Loads the persisted [Cart] for the current user from Hive.
  ///
  /// Returns `null` when no cart has been saved yet or when the stored data
  /// cannot be deserialized (e.g. after a schema migration).
  ///
  /// Satisfies Requirement 9.2: cart is restored on app launch.
  @override
  Future<Cart?> load() async => _cartDataSource.loadCart(_uid);

  /// Removes the persisted cart for the current user from Hive.
  ///
  /// Called after a successful order or when the user explicitly clears the
  /// cart.
  @override
  Future<void> clear() => _cartDataSource.clearCart(_uid);

  // -------------------------------------------------------------------------
  // ICartRepository — availability re-check
  // -------------------------------------------------------------------------

  /// Re-checks the availability of every [CartItem] in [cart] against the
  /// remote meal catalog and returns an updated [Cart] with each item's
  /// [CartItem.isAvailable] flag reflecting the current catalog state.
  ///
  /// For each item:
  /// - If the meal is found in the catalog, [CartItem.isAvailable] is set to
  ///   [Meal.isAvailable].
  /// - If the meal is **not found** (deleted from catalog), the item is marked
  ///   unavailable (`isAvailable = false`).
  ///
  /// Availability checks are performed concurrently via [Future.wait] to
  /// minimise latency when the cart contains multiple items.
  ///
  /// Errors from individual meal lookups are caught and treated as
  /// unavailable so a single network failure does not block the entire
  /// checkout flow.
  ///
  /// Satisfies Requirements 8.4 and 9.3.
  @override
  Future<Cart> recheckAvailability(Cart cart) async {
    final updatedItems = await Future.wait(
      cart.items.map(_recheckItem),
    );

    return cart.copyWith(items: updatedItems);
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Fetches the current availability for a single [item] from the catalog.
  ///
  /// Returns a copy of [item] with [CartItem.isAvailable] updated to match
  /// the catalog. If the lookup fails for any reason, the item is marked
  /// unavailable.
  Future<CartItem> _recheckItem(CartItem item) async {
    try {
      final meal = await _mealRepository.getMealById(item.mealId);
      // Meal not found in catalog → treat as unavailable.
      final available = meal?.isAvailable ?? false;
      return item.copyWith(isAvailable: available);
    } catch (_) {
      // Network or deserialization error → conservatively mark unavailable.
      return item.copyWith(isAvailable: false);
    }
  }
}
