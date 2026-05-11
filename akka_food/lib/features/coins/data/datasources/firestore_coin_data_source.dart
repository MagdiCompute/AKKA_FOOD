import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/coin_transaction.dart';

/// Firestore data source for the Coins feature.
///
/// Handles all direct Firestore interactions for coin-related data:
/// - Real-time balance stream from the denormalized `/users/{uid}.coinBalance`
///   field (Requirement 3 AC1, AC2).
/// - Paginated transaction history from `/users/{uid}/coinTransactions`
///   (Requirement 4 AC1) — implemented in Task 3.2.
///
/// Accepts a [FirebaseFirestore] instance for testability; defaults to
/// [FirebaseFirestore.instance] in production.
class FirestoreCoinDataSource {
  FirestoreCoinDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _coinTransactions(String uid) =>
      _userDoc(uid).collection('coinTransactions');

  // ---------------------------------------------------------------------------
  // Real-time coin balance stream
  // ---------------------------------------------------------------------------

  /// Returns a [Stream<int>] that emits the current coin balance for [uid]
  /// whenever the `/users/{uid}` document changes.
  ///
  /// Reads the denormalized `coinBalance` field on the user document.
  /// This field is kept in sync atomically by Cloud Functions alongside
  /// each coin transaction write.
  ///
  /// Emits `0` when the field is absent or null (new user with no coins).
  /// Updates are delivered within seconds of a balance change
  /// (Requirement 3 AC2).
  Stream<int> watchBalance(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return 0;
      final data = snapshot.data()!;
      return (data['coinBalance'] as num?)?.toInt() ?? 0;
    });
  }

  // ---------------------------------------------------------------------------
  // Paginated transaction history (Task 3.2)
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [CoinTransaction] records for [uid], ordered
  /// by `timestamp` descending.
  ///
  /// [pageSize] defaults to 20 (per Requirement 4 AC1).
  ///
  /// [lastDocument] is the last [DocumentSnapshot] from the previous page.
  /// Pass `null` (or omit) to fetch the first page.
  ///
  /// Returns an empty list when there are no more results.
  Future<List<CoinTransaction>> getCoinTransactions(
    String uid, {
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
  }) async {
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

  /// Returns the raw [QuerySnapshot] for the last transaction query.
  ///
  /// Useful for obtaining the last [DocumentSnapshot] to pass as a cursor
  /// for the next page. Call [getCoinTransactions] first, then use this
  /// to get the snapshot for cursor-based pagination.
  Future<QuerySnapshot<Map<String, dynamic>>> getCoinTransactionsSnapshot(
    String uid, {
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _coinTransactions(uid)
        .orderBy('timestamp', descending: true)
        .limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.get();
  }
}
