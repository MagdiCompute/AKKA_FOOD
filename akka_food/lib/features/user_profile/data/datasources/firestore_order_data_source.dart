import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order_summary.dart';

/// Handles all Firestore read operations for the `/orders` top-level
/// collection, scoped to a specific user.
///
/// Orders are stored at `/orders/{orderId}` with a `uid` field that
/// identifies the owning user. This data source is read-only from the
/// profile feature's perspective — order creation is handled by the
/// order/cart feature.
///
/// Accepts an optional [FirebaseFirestore] instance for testability;
/// defaults to [FirebaseFirestore.instance] in production.
class FirestoreOrderDataSource {
  FirestoreOrderDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  // ---------------------------------------------------------------------------
  // Order history
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [OrderSummary] records for [uid], ordered
  /// by `createdAt` descending.
  ///
  /// [page] is 1-indexed; [pageSize] defaults to 20.
  ///
  /// Implementation note: fetches `pageSize * page` documents from Firestore
  /// and slices the result in Dart. This is a simple approach suitable for
  /// moderate history sizes. For very large histories, cursor-based pagination
  /// (using [DocumentSnapshot] cursors) would be more efficient.
  Future<List<OrderSummary>> getOrderHistory(
    String uid, {
    int page = 1,
    int pageSize = 20,
  }) async {
    assert(page >= 1, 'page must be >= 1');
    assert(pageSize >= 1, 'pageSize must be >= 1');

    final totalToFetch = pageSize * page;

    final snapshot = await _ordersCollection
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
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
        'orderId': doc.id,
        ...doc.data(),
      };
      return OrderSummary.fromMap(data);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Order detail
  // ---------------------------------------------------------------------------

  /// Returns the full [OrderSummary] for the given [orderId].
  ///
  /// Throws a [StateError] if the document does not exist.
  Future<OrderSummary> getOrderDetail(String orderId) async {
    final snapshot = await _ordersCollection.doc(orderId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError('Order document not found for orderId: $orderId');
    }

    final data = <String, dynamic>{
      'orderId': snapshot.id,
      ...snapshot.data()!,
    };

    return OrderSummary.fromMap(data);
  }
}
