import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coin_transaction.dart';

/// Handles all Firestore read operations for the
/// `/users/{uid}/coinTransactions` subcollection.
///
/// Provides:
/// - [getCoinTransactions] — cursor-based paginated list ordered by timestamp
///   descending (Requirement 6.2, default page size 20).
/// - [watchCoinBalance] — real-time [Stream] that emits the running balance
///   whenever the subcollection changes (Requirement 6.6, updates within 5 s).
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
  // Paginated transaction list — cursor-based
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [CoinTransaction] records for [uid], ordered
  /// by `timestamp` descending.
  ///
  /// [pageSize] defaults to 20 (per Requirement 6.2).
  ///
  /// [lastDocument] is the last [DocumentSnapshot] from the previous page.
  /// Pass `null` (or omit it) to fetch the first page. Pass the last document
  /// of the current page to fetch the next page. This cursor-based approach
  /// avoids re-reading already-seen documents and scales to large histories.
  ///
  /// Returns an empty list when there are no more results.
  Future<List<CoinTransaction>> getCoinTransactions(
    String uid, {
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    assert(pageSize >= 1, 'pageSize must be >= 1');

    Query<Map<String, dynamic>> query = _coinTransactions(uid)
        .orderBy('timestamp', descending: true)
        .limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
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
  /// in each snapshot. Emits `0` when the user has no transactions
  /// (Requirement 6.5). The stream never closes unless the caller cancels
  /// the subscription. Updates are delivered within 5 seconds of a new
  /// transaction being written to Firestore (Requirement 6.6).
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
