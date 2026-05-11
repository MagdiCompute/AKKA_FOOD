import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/coin_transaction.dart';
import '../../domain/repositories/i_coin_repository.dart';
import '../datasources/firestore_coin_data_source.dart';

/// Concrete implementation of [ICoinRepository] for the Coins feature.
///
/// Composes:
/// - [FirestoreCoinDataSource] — real-time balance stream and paginated
///   transaction history from Firestore.
/// - [FirebaseFunctions] — calls the `redeemCoins` HTTPS Callable Cloud
///   Function for coin redemption (server-side authoritative validation).
///
/// All dependencies are injected via the constructor for testability.
class CoinRepository implements ICoinRepository {
  CoinRepository({
    required FirestoreCoinDataSource firestoreDataSource,
    FirebaseFunctions? functions,
  })  : _firestoreDataSource = firestoreDataSource,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirestoreCoinDataSource _firestoreDataSource;
  final FirebaseFunctions _functions;

  // ---------------------------------------------------------------------------
  // ICoinRepository — real-time balance stream
  // ---------------------------------------------------------------------------

  /// Emits the current coin balance for [uid] and pushes a new value
  /// whenever the balance changes.
  ///
  /// Delegates to [FirestoreCoinDataSource.watchBalance].
  @override
  Stream<int> watchBalance(String uid) {
    return _firestoreDataSource.watchBalance(uid);
  }

  // ---------------------------------------------------------------------------
  // ICoinRepository — paginated transaction history
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [CoinTransaction] records for [uid], ordered
  /// by timestamp descending.
  ///
  /// [page] is zero-indexed. Each page contains [pageSize] items (default 20).
  ///
  /// Converts the page-based interface to the cursor-based pagination used by
  /// [FirestoreCoinDataSource]. For pages beyond the first, all preceding
  /// documents are fetched to obtain the correct cursor position.
  @override
  Future<List<CoinTransaction>> getTransactionHistory({
    required String uid,
    int page = 0,
    int pageSize = 20,
  }) async {
    assert(page >= 0, 'page must be >= 0');
    assert(pageSize >= 1, 'pageSize must be >= 1');

    if (page == 0) {
      // First page — no cursor needed.
      return _firestoreDataSource.getCoinTransactions(
        uid,
        pageSize: pageSize,
      );
    }

    // For subsequent pages, fetch all documents up to the target page using
    // the snapshot to obtain the cursor for startAfterDocument.
    final skipCount = page * pageSize;
    final precedingSnapshot =
        await _firestoreDataSource.getCoinTransactionsSnapshot(
      uid,
      pageSize: skipCount,
    );

    if (precedingSnapshot.docs.isEmpty ||
        precedingSnapshot.docs.length < skipCount) {
      return [];
    }

    final lastDoc = precedingSnapshot.docs.last;
    return _firestoreDataSource.getCoinTransactions(
      uid,
      pageSize: pageSize,
      lastDocument: lastDoc,
    );
  }

  // ---------------------------------------------------------------------------
  // ICoinRepository — coin redemption
  // ---------------------------------------------------------------------------

  /// Calls the `redeemCoins` HTTPS Callable Cloud Function to redeem coins
  /// for the given order.
  ///
  /// [amount] must be a positive multiple of 1000 and not exceed the user's
  /// current balance. The server performs the authoritative validation.
  ///
  /// Throws [FirebaseFunctionsException] if the Cloud Function returns an
  /// error (e.g. insufficient balance, invalid amount).
  @override
  Future<void> redeemCoins({
    required String uid,
    required int amount,
    required String orderId,
  }) async {
    final callable = _functions.httpsCallable('redeemCoins');
    await callable.call<void>(<String, dynamic>{
      'uid': uid,
      'amount': amount,
      'orderId': orderId,
    });
  }
}
