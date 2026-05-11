import '../../data/datasources/firestore_coin_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../domain/repositories/i_coin_repository.dart';

/// Concrete implementation of [ICoinRepository].
///
/// Orchestrates:
/// - [FirestoreCoinDataSource] — reads from `/users/{uid}/coinTransactions`
/// - [HiveProfileCache] — local 5-minute TTL cache for the first page of
///   coin transaction history
///
/// Cache strategy (Requirement 6):
/// - [getCoinTransactions] page 1: return fresh cache if within
///   [HiveProfileCache.cacheTtl]; otherwise fetch from Firestore, write to
///   cache, and return. On Firestore error, fall back to stale cache; rethrow
///   if cache is also empty.
/// - [getCoinTransactions] page > 1: always fetch from Firestore.
/// - [getCoinBalance]: derived from the first page of transactions in cache
///   when available; otherwise fetches from Firestore.
/// - [watchCoinBalance]: delegates directly to
///   [FirestoreCoinDataSource.watchCoinBalance] — real-time stream, no
///   caching.
class CoinRepository implements ICoinRepository {
  CoinRepository({
    required FirestoreCoinDataSource firestoreDataSource,
    required HiveProfileCache cache,
  })  : _firestoreDataSource = firestoreDataSource,
        _cache = cache;

  final FirestoreCoinDataSource _firestoreDataSource;
  final HiveProfileCache _cache;

  // ---------------------------------------------------------------------------
  // ICoinRepository — balance
  // ---------------------------------------------------------------------------

  /// Returns the current coin balance for [uid].
  ///
  /// Attempts to derive the balance from the cached first page of
  /// transactions when the cache is fresh. Falls back to a live Firestore
  /// query when the cache is stale or empty.
  ///
  /// Note: the balance derived from a single page may be incomplete for users
  /// with many transactions. For an authoritative real-time balance, use
  /// [watchCoinBalance] instead.
  @override
  Future<int> getCoinBalance(String uid) async {
    // Try to derive balance from fresh cache.
    final cached = _cache.getCoinHistory(uid);
    if (cached != null) {
      return cached.fold<int>(0, (acc, tx) => acc + tx.amount);
    }

    // Fetch first page from Firestore and cache it.
    try {
      final transactions = await _firestoreDataSource.getCoinTransactions(uid);
      await _cache.saveCoinHistory(uid, transactions);
      return transactions.fold<int>(0, (acc, tx) => acc + tx.amount);
    } catch (e) {
      // Fall back to stale cache.
      final stale = _cache.getCoinHistoryStale(uid);
      if (stale != null) {
        return stale.fold<int>(0, (acc, tx) => acc + tx.amount);
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ICoinRepository — transaction history
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [CoinTransaction] records for [uid], ordered
  /// by timestamp descending.
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
  Future<List<CoinTransaction>> getCoinTransactions(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    assert(page >= 1, 'page must be >= 1');
    assert(pageSize >= 1, 'pageSize must be >= 1');

    // Only cache the first page.
    if (page == 1) {
      // 1. Return fresh cache hit.
      final cached = _cache.getCoinHistory(uid);
      if (cached != null) return cached;

      // 2. Fetch from Firestore (first page = no cursor).
      try {
        final transactions = await _firestoreDataSource.getCoinTransactions(
          uid,
          pageSize: pageSize,
        );
        await _cache.saveCoinHistory(uid, transactions);
        return transactions;
      } catch (e) {
        // 3. Network error — fall back to stale cache.
        final stale = _cache.getCoinHistoryStale(uid);
        if (stale != null) return stale;
        // 4. Nothing in cache either — rethrow.
        rethrow;
      }
    }

    // Pages > 1: fetch directly from Firestore using offset-based simulation.
    // The Firestore data source uses cursor-based pagination; to reach page N
    // we must first fetch (page - 1) * pageSize documents to obtain the
    // cursor, then fetch the target page.
    final skipCount = (page - 1) * pageSize;
    final allUpToPage = await _firestoreDataSource.getCoinTransactions(
      uid,
      pageSize: skipCount + pageSize,
    );

    if (allUpToPage.length <= skipCount) return [];
    return allUpToPage.sublist(skipCount);
  }

  // ---------------------------------------------------------------------------
  // ICoinRepository — real-time balance stream
  // ---------------------------------------------------------------------------

  /// Emits the current coin balance for [uid] and pushes a new value
  /// whenever the balance changes.
  ///
  /// Delegates directly to [FirestoreCoinDataSource.watchCoinBalance] —
  /// real-time streams are not cached (Requirement 6.6).
  @override
  Stream<int> watchCoinBalance(String uid) =>
      _firestoreDataSource.watchCoinBalance(uid);

  // ---------------------------------------------------------------------------
  // ICoinRepository — SWR stream
  // ---------------------------------------------------------------------------

  /// Returns a stale-while-revalidate stream of the first page of
  /// [CoinTransaction] records for [uid], ordered by timestamp descending.
  ///
  /// 1. If a cached entry exists (even stale), it is emitted immediately.
  /// 2. Fresh data is fetched from Firestore in the background and emitted
  ///    once available; the cache is updated with the fresh data.
  /// 3. On network error:
  ///    - If stale data was emitted, the stream completes silently (the caller
  ///      should display a connectivity banner).
  ///    - If no cached data was available, the error is rethrown.
  @override
  Stream<List<CoinTransaction>> watchCoinTransactions(
    String uid, {
    int pageSize = 20,
  }) async* {
    // 1. Emit stale cache immediately if available.
    final stale = _cache.getCoinHistoryStale(uid);
    if (stale != null) yield stale;

    // 2. Fetch fresh data from Firestore (first page).
    try {
      final fresh = await _firestoreDataSource.getCoinTransactions(
        uid,
        pageSize: pageSize,
      );
      await _cache.saveCoinHistory(uid, fresh);
      yield fresh;
    } catch (e) {
      // 3. If we already emitted stale data, complete silently so the caller
      //    can show a connectivity banner. Otherwise rethrow.
      if (stale == null) rethrow;
    }
  }
}
