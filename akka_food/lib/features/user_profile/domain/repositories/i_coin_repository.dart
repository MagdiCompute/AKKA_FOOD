import '../entities/coin_transaction.dart';

/// Abstract repository interface for coin balance and transaction operations.
///
/// Pure Dart — zero Flutter or Firebase imports.
/// Implementations live in the data layer.
abstract class ICoinRepository {
  /// Returns the current coin balance for [uid].
  ///
  /// Returns 0 when the user has no transactions.
  Future<int> getCoinBalance(String uid);

  /// Returns a paginated list of [CoinTransaction] records for [uid], ordered
  /// by timestamp descending.
  ///
  /// [page] is 1-indexed; [pageSize] defaults to 20.
  /// Returns an empty list when the user has no transactions.
  Future<List<CoinTransaction>> getCoinTransactions(
    String uid, {
    int page = 1,
    int pageSize = 20,
  });

  /// Emits the current coin balance for [uid] and pushes a new value
  /// whenever the balance changes (real-time Firestore listener).
  ///
  /// The stream never closes unless the caller cancels the subscription.
  Stream<int> watchCoinBalance(String uid);

  /// Returns a stale-while-revalidate stream of the first page of
  /// [CoinTransaction] records for [uid], ordered by timestamp descending.
  ///
  /// Emits the cached first page immediately (if available), then fetches
  /// fresh data from Firestore in the background and emits the updated list.
  ///
  /// On network error:
  /// - If cached data was emitted, the stream completes silently (caller
  ///   should display a connectivity banner).
  /// - If no cached data was available, the stream emits an error.
  Stream<List<CoinTransaction>> watchCoinTransactions(
    String uid, {
    int pageSize = 20,
  });
}
