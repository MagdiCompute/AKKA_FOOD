import '../entities/coin_transaction.dart';

/// Abstract repository interface for the Coins feature.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implementations live in `data/repositories/`.
abstract class ICoinRepository {
  /// Real-time stream of the user's current coin balance.
  ///
  /// Emits a new value whenever the balance changes (e.g. after a purchase
  /// reward or redemption).
  Stream<int> watchBalance(String uid);

  /// Returns a paginated list of [CoinTransaction]s for the given user,
  /// ordered by timestamp descending.
  ///
  /// [page] is zero-indexed. Each page contains [pageSize] items.
  Future<List<CoinTransaction>> getTransactionHistory({
    required String uid,
    int page = 0,
    int pageSize = 20,
  });

  /// Calls the Cloud Function to redeem coins for the given order.
  ///
  /// [amount] must be a positive multiple of 1000 and not exceed the user's
  /// current balance. The server performs the authoritative validation.
  Future<void> redeemCoins({
    required String uid,
    required int amount,
    required String orderId,
  });
}
