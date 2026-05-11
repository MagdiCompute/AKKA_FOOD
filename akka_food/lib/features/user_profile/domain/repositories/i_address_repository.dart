import '../entities/delivery_address.dart';

/// Abstract repository interface for delivery address operations.
///
/// Pure Dart — zero Flutter or Firebase imports.
/// Implementations live in the data layer.
abstract class IAddressRepository {
  /// Returns all [DeliveryAddress] records for [uid].
  ///
  /// The list is sorted with the default address first, followed by the
  /// remaining addresses in creation order (oldest first).
  Future<List<DeliveryAddress>> getAddresses(String uid);

  /// Persists a new [address] and returns the saved [DeliveryAddress]
  /// (including any server-assigned identifier).
  ///
  /// Enforces the 10-address-per-user limit; throws if the limit is reached.
  Future<DeliveryAddress> addAddress(DeliveryAddress address);

  /// Persists changes to an existing [address] and returns the updated
  /// [DeliveryAddress].
  ///
  /// Throws if the address does not exist or the caller is unauthorised.
  Future<DeliveryAddress> updateAddress(DeliveryAddress address);

  /// Permanently removes the address identified by [addressId] from [uid]'s
  /// account.
  ///
  /// Throws if the address does not exist or the caller is unauthorised.
  Future<void> deleteAddress(String uid, String addressId);

  /// Atomically marks [addressId] as the default address for [uid] and
  /// removes the default designation from any previously default address.
  ///
  /// Throws if the address does not exist or the caller is unauthorised.
  Future<void> setDefaultAddress(String uid, String addressId);

  /// Returns a stale-while-revalidate stream of [DeliveryAddress] records for
  /// [uid].
  ///
  /// Emits the cached address list immediately (if available), then fetches
  /// fresh data from Firestore in the background and emits the updated list.
  ///
  /// On network error:
  /// - If cached data was emitted, the stream completes silently (caller
  ///   should display a connectivity banner).
  /// - If no cached data was available, the stream emits an error.
  Stream<List<DeliveryAddress>> watchAddresses(String uid);
}
