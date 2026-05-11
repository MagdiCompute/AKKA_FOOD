import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import '../../domain/entities/transaction.dart';

/// Data source that reads transaction data from Firestore.
///
/// Provides real-time listeners and one-time reads on the
/// `/transactions/{transactionId}` collection. The Firestore real-time
/// listener (`snapshots()`) on a transaction document drives the payment
/// UI state machine.
///
/// Accepts an optional [FirebaseFirestore] instance for testability;
/// defaults to [FirebaseFirestore.instance] in production.
class FirestoreTransactionDataSource {
  FirestoreTransactionDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('transactions');

  /// Converts a Firestore [DocumentSnapshot] into a domain [Transaction].
  ///
  /// Merges the document ID into the data map so the entity receives its `id`.
  /// Throws [TransactionNotFoundException] if the document does not exist.
  Transaction _documentToTransaction(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists || doc.data() == null) {
      throw TransactionNotFoundException(
        'Transaction document not found: ${doc.id}',
      );
    }

    final data = <String, dynamic>{
      'id': doc.id,
      ...doc.data()!,
    };

    return Transaction.fromMap(data);
  }

  // ---------------------------------------------------------------------------
  // Real-time listener
  // ---------------------------------------------------------------------------

  /// Watches a single transaction document for real-time status updates.
  ///
  /// Returns a [Stream] that emits the latest [Transaction] state whenever
  /// the Firestore document at `/transactions/{transactionId}` changes
  /// (e.g., status transitions from `pending` → `processing` → `success`).
  ///
  /// The stream will emit an error of type [TransactionNotFoundException]
  /// if the document does not exist or is deleted.
  Stream<Transaction> watchTransaction(String transactionId) {
    return _transactionsCollection
        .doc(transactionId)
        .snapshots()
        .map(_documentToTransaction);
  }

  // ---------------------------------------------------------------------------
  // One-time read
  // ---------------------------------------------------------------------------

  /// Fetches a single [Transaction] by its document ID.
  ///
  /// Throws [TransactionNotFoundException] if the document does not exist.
  Future<Transaction> getTransaction(String transactionId) async {
    final doc = await _transactionsCollection.doc(transactionId).get();
    return _documentToTransaction(doc);
  }

  // ---------------------------------------------------------------------------
  // Paginated user transactions (Payment History — Req 5)
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [Transaction] records for [uid], ordered
  /// by `createdAt` descending.
  ///
  /// [limit] defaults to 20 (per Requirement 5 AC1).
  ///
  /// [startAfter] is the last [DocumentSnapshot] from the previous page.
  /// Pass `null` (or omit it) to fetch the first page. This cursor-based
  /// approach avoids re-reading already-seen documents and scales to large
  /// histories.
  ///
  /// Each [Transaction] includes: reference, amount, status, timestamp,
  /// and linked Order ID (Requirement 5 AC2).
  ///
  /// Returns an empty list when there are no more results.
  Future<List<Transaction>> getUserTransactions(
    String uid, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    assert(limit >= 1, 'limit must be >= 1');

    Query<Map<String, dynamic>> query = _transactionsCollection
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = <String, dynamic>{
        'id': doc.id,
        ...doc.data(),
      };
      return Transaction.fromMap(data);
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Thrown when a transaction document is not found in Firestore.
class TransactionNotFoundException implements Exception {
  TransactionNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'TransactionNotFoundException: $message';
}
