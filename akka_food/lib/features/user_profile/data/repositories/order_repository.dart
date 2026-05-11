import '../../data/datasources/firestore_order_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../domain/entities/order_summary.dart';
import '../../domain/repositories/i_order_repository.dart';

/// Concrete implementation of [IOrderRepository].
///
/// Orchestrates:
/// - [FirestoreOrderDataSource] — reads from the `/orders` collection
/// - [HiveProfileCache] — local 5-minute TTL cache for the first page of
///   order history
///
/// Cache strategy (Requirement 5.5):
/// - [getOrderHistory] page 1: return fresh cache if within
///   [HiveProfileCache.cacheTtl]; otherwise fetch from Firestore, write to
///   cache, and return. On Firestore error, fall back to stale cache; rethrow
///   if cache is also empty.
/// - [getOrderHistory] page > 1: always fetch from Firestore (no caching for
///   subsequent pages).
/// - [getOrderDetail]: always fetch from Firestore — individual orders are
///   not cached.
class OrderRepository implements IOrderRepository {
  OrderRepository({
    required FirestoreOrderDataSource firestoreDataSource,
    required HiveProfileCache cache,
  })  : _firestoreDataSource = firestoreDataSource,
        _cache = cache;

  final FirestoreOrderDataSource _firestoreDataSource;
  final HiveProfileCache _cache;

  // ---------------------------------------------------------------------------
  // IOrderRepository — order history
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [OrderSummary] records for [uid], ordered
  /// by order date descending.
  ///
  /// For page 1 (the default), a cache-first strategy is applied:
  /// 1. If the cache entry is fresh (within [HiveProfileCache.cacheTtl]),
  ///    return it immediately.
  /// 2. Otherwise fetch from Firestore, write to cache, and return.
  /// 3. On Firestore error, fall back to stale cache if available.
  /// 4. If both Firestore and cache are unavailable, rethrow the error.
  ///
  /// For pages > 1, Firestore is always queried directly (no caching).
  @override
  Future<List<OrderSummary>> getOrderHistory(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    assert(page >= 1, 'page must be >= 1');
    assert(pageSize >= 1, 'pageSize must be >= 1');

    // Only cache the first page.
    if (page == 1) {
      // 1. Return fresh cache hit.
      final cached = _cache.getOrderHistory(uid);
      if (cached != null) return cached;

      // 2. Fetch from Firestore (first page = no cursor).
      try {
        final orders = await _firestoreDataSource.getOrders(
          uid,
          pageSize: pageSize,
        );
        await _cache.saveOrderHistory(uid, orders);
        return orders;
      } catch (e) {
        // 3. Network error — fall back to stale cache.
        final stale = _cache.getOrderHistoryStale(uid);
        if (stale != null) return stale;
        // 4. Nothing in cache either — rethrow.
        rethrow;
      }
    }

    // Pages > 1: fetch directly from Firestore using offset-based simulation.
    // The Firestore data source uses cursor-based pagination; to reach page N
    // we must first fetch (page - 1) * pageSize documents to obtain the
    // cursor, then fetch the target page.
    //
    // This is intentionally simple: for the profile feature, deep pagination
    // is rare and the first page is the common case (cached above).
    final skipCount = (page - 1) * pageSize;
    final allUpToPage = await _firestoreDataSource.getOrders(
      uid,
      pageSize: skipCount + pageSize,
    );

    if (allUpToPage.length <= skipCount) return [];
    return allUpToPage.sublist(skipCount);
  }

  // ---------------------------------------------------------------------------
  // IOrderRepository — single order
  // ---------------------------------------------------------------------------

  /// Returns the full [OrderSummary] for [orderId].
  ///
  /// Always fetches from Firestore — individual orders are not cached.
  @override
  Future<OrderSummary> getOrderDetail(String orderId) =>
      _firestoreDataSource.getOrderById(orderId);

  // ---------------------------------------------------------------------------
  // IOrderRepository — SWR stream
  // ---------------------------------------------------------------------------

  /// Returns a stale-while-revalidate stream of the first page of
  /// [OrderSummary] records for [uid], ordered by order date descending.
  ///
  /// 1. If a cached entry exists (even stale), it is emitted immediately.
  /// 2. Fresh data is fetched from Firestore in the background and emitted
  ///    once available; the cache is updated with the fresh data.
  /// 3. On network error:
  ///    - If stale data was emitted, the stream completes silently (the caller
  ///      should display a connectivity banner).
  ///    - If no cached data was available, the error is rethrown.
  @override
  Stream<List<OrderSummary>> watchOrderHistory(
    String uid, {
    int pageSize = 20,
  }) async* {
    // 1. Emit stale cache immediately if available.
    final stale = _cache.getOrderHistoryStale(uid);
    if (stale != null) yield stale;

    // 2. Fetch fresh data from Firestore (first page).
    try {
      final fresh = await _firestoreDataSource.getOrders(
        uid,
        pageSize: pageSize,
      );
      await _cache.saveOrderHistory(uid, fresh);
      yield fresh;
    } catch (e) {
      // 3. If we already emitted stale data, complete silently so the caller
      //    can show a connectivity banner. Otherwise rethrow.
      if (stale == null) rethrow;
    }
  }
}
