import '../../data/datasources/firestore_address_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../domain/entities/delivery_address.dart';
import '../../domain/repositories/i_address_repository.dart';

/// Concrete implementation of [IAddressRepository].
///
/// Orchestrates:
/// - [FirestoreAddressDataSource] — CRUD on `/users/{uid}/addresses`
/// - [HiveProfileCache] — local 5-minute TTL cache for the address list
///
/// Cache strategy (Requirement 1.3, 4):
/// - [getAddresses]: return fresh cache if within [HiveProfileCache.cacheTtl];
///   otherwise fetch from Firestore, write to cache, and return. On Firestore
///   error, fall back to stale cache; rethrow if cache is also empty.
/// - Write operations (add, update, delete, setDefault) always go to Firestore
///   first, then invalidate the cache by writing the refreshed list.
class AddressRepository implements IAddressRepository {
  AddressRepository({
    required FirestoreAddressDataSource firestoreDataSource,
    required HiveProfileCache cache,
  })  : _firestoreDataSource = firestoreDataSource,
        _cache = cache;

  final FirestoreAddressDataSource _firestoreDataSource;
  final HiveProfileCache _cache;

  // ---------------------------------------------------------------------------
  // IAddressRepository — read
  // ---------------------------------------------------------------------------

  /// Returns all [DeliveryAddress] records for [uid].
  ///
  /// Cache-first strategy:
  /// 1. If the cache entry is fresh (within [HiveProfileCache.cacheTtl]),
  ///    return it immediately.
  /// 2. Otherwise fetch from Firestore, write to cache, and return.
  /// 3. On Firestore error, fall back to stale cache if available.
  /// 4. If both Firestore and cache are unavailable, rethrow the error.
  @override
  Future<List<DeliveryAddress>> getAddresses(String uid) async {
    // 1. Return fresh cache hit.
    final cached = _cache.getAddresses(uid);
    if (cached != null) return cached;

    // 2. Fetch from Firestore.
    try {
      final addresses = await _firestoreDataSource.getAddresses(uid);
      await _cache.saveAddresses(uid, addresses);
      return addresses;
    } catch (e) {
      // 3. Network error — fall back to stale cache.
      final stale = _cache.getAddressesStale(uid);
      if (stale != null) return stale;
      // 4. Nothing in cache either — rethrow.
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // IAddressRepository — write
  // ---------------------------------------------------------------------------

  /// Adds a new [address] and refreshes the cache.
  ///
  /// Enforces the 10-address-per-user limit (delegated to
  /// [FirestoreAddressDataSource]).
  @override
  Future<DeliveryAddress> addAddress(DeliveryAddress address) async {
    final saved = await _firestoreDataSource.addAddress(address);
    await _refreshCache(address.uid);
    return saved;
  }

  /// Updates an existing [address] and refreshes the cache.
  @override
  Future<DeliveryAddress> updateAddress(DeliveryAddress address) async {
    final updated = await _firestoreDataSource.updateAddress(address);
    await _refreshCache(address.uid);
    return updated;
  }

  /// Deletes the address identified by [addressId] and refreshes the cache.
  @override
  Future<void> deleteAddress(String uid, String addressId) async {
    await _firestoreDataSource.deleteAddress(uid, addressId);
    await _refreshCache(uid);
  }

  /// Atomically sets [addressId] as the default address and refreshes the
  /// cache.
  @override
  Future<void> setDefaultAddress(String uid, String addressId) async {
    await _firestoreDataSource.setDefaultAddress(uid, addressId);
    await _refreshCache(uid);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fetches the latest address list from Firestore and writes it to the
  /// cache, resetting the TTL clock.
  Future<void> _refreshCache(String uid) async {
    try {
      final addresses = await _firestoreDataSource.getAddresses(uid);
      await _cache.saveAddresses(uid, addresses);
    } catch (_) {
      // Cache refresh failure is non-fatal; the write already succeeded.
    }
  }

  // ---------------------------------------------------------------------------
  // IAddressRepository — SWR stream
  // ---------------------------------------------------------------------------

  /// Returns a stale-while-revalidate stream of [DeliveryAddress] records for
  /// [uid].
  ///
  /// 1. If a cached entry exists (even stale), it is emitted immediately.
  /// 2. Fresh data is fetched from Firestore in the background and emitted
  ///    once available; the cache is updated with the fresh data.
  /// 3. On network error:
  ///    - If stale data was emitted, the stream completes silently (the caller
  ///      should display a connectivity banner).
  ///    - If no cached data was available, the error is rethrown.
  @override
  Stream<List<DeliveryAddress>> watchAddresses(String uid) async* {
    // 1. Emit stale cache immediately if available.
    final stale = _cache.getAddressesStale(uid);
    if (stale != null) yield stale;

    // 2. Fetch fresh data from Firestore.
    try {
      final fresh = await _firestoreDataSource.getAddresses(uid);
      await _cache.saveAddresses(uid, fresh);
      yield fresh;
    } catch (e) {
      // 3. If we already emitted stale data, complete silently so the caller
      //    can show a connectivity banner. Otherwise rethrow.
      if (stale == null) rethrow;
    }
  }
}
