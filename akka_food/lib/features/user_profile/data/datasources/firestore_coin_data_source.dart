import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coin_transaction.dart';

/// Handles all Firestore read operations for the
/// `/users/{uid}/coinTransactions` subcollection.
///
/// Provides:
/// - [getCoinBalance] — one-shot fetch that sums all transaction amounts.
/// - [getCoinTransactions] — paginated list ordered by timestamp descending.
/// - [watchCoinBalance] — real-time [Stream] that emits the running balance
///   whenever the subcollection changes.
///
/// Accepts an optional [FirebaseFirestore] instance for testability;
/// defaults to [FirebaseFirestore.instance] in production.
class FirestoreCoinDataSource {
  FirestoreCoinDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _coinTransactions(String uid) =>
      _firestore.collection('users').doc(uid).collection('coinTransactions');

  // ---------------------------------------------------------------------------
  // Coin balance (one-shot)
  // ---------------------------------------------------------------------------

  /// Returns the current coin balance for [uid] by fetching all transactions
  /// and summing their [CoinTransaction.amount] fields.
  ///
  /// Positive amounts are credits; negative amounts are debits.
  /// Returns `0` when the user has no transactions.
  Future<int> getCoinBalance(String uid) async {
    final snapshot = await _coinTransactions(uid).get();

    if (snapshot.docs.isEmpty) return 0;

    return snapshot.docs.fold<int>(0, (acc, doc) {
      final amount = (doc.data()['amount'] as num?)?.toInt() ?? 0;
      return acc + amount;
    });
  }

  // ---------------------------------------------------------------------------
  // Paginated transaction list
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [CoinTransaction] records for [uid], ordered
  /// by `timestamp` descending.
  ///
  /// [page] is 1-indexed; [pageSize] defaults to 20.
  ///
  /// Implementation note: fetches `pageSize * page` documents from Firestore
  /// and slices the result in Dart. This is a simple approach suitable for
  /// moderate transaction histories. For very large histories, cursor-based
  /// pagination (using [DocumentSnapshot] cursors) would be more efficient.
  Future<List<CoinTransaction>> getCoinTransactions(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    assert(page >= 1, 'page must be >= 1');
    assert(pageSize >= 1, 'pageSize must be >= 1');

    final totalToFetch = pageSize * page;

    final snapshot = await _coinTransactions(uid)
        .orderBy('timestamp', descending: true)
        .limit(totalToFetch)
        .get();

    final allDocs = snapshot.docs;

    // Skip the first (page - 1) * pageSize results to get the current page.
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= allDocs.length) {
      return const [];
    }

    final pageDocs = allDocs.sublist(startIndex);

    return pageDocs.map((doc) {
      final data = <String, dynamic>{
        'id': doc.id,
        'uid': uid,
        ...doc.data(),
      };
      return CoinTransaction.fromMap(data);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Real-time coin balance stream
  // ---------------------------------------------------------------------------

  /// Returns a [Stream<int>] that emits the current coin balance for [uid]
  /// and pushes a new value whenever the subcollection changes.
  ///
  /// The balance is computed by summing all [CoinTransaction.amount] fields
  /// in each snapshot. The stream never closes unless the caller cancels the
  /// subscription.
  Stream<int> watchCoinBalance(String uid) {
    return _coinTransactions(uid).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return 0;

      return snapshot.docs.fold<int>(0, (acc, doc) {
        final amount = (doc.data()['amount'] as num?)?.toInt() ?? 0;
        return acc + amount;
      });
    });
  }
}
