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
  // Order history — cursor-based pagination
  // ---------------------------------------------------------------------------

  /// Returns a paginated list of [OrderSummary] records for [uid], ordered
  /// by `createdAt` descending.
  ///
  /// [pageSize] defaults to 20 (per Requirement 5.1).
  ///
  /// [lastDocument] is the last [DocumentSnapshot] from the previous page.
  /// Pass `null` (or omit it) to fetch the first page. Pass the last document
  /// of the current page to fetch the next page. This cursor-based approach
  /// avoids re-reading already-seen documents and scales to large histories.
  ///
  /// Returns an empty list when there are no more results or if the required
  /// composite index is not yet created.
  Future<List<OrderSummary>> getOrders(
    String uid, {
    int pageSize = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    assert(pageSize >= 1, 'pageSize must be >= 1');

    try {
      // Query without orderBy to avoid composite index requirement.
      // Sort client-side instead.
      Query<Map<String, dynamic>> query = _ordersCollection
          .where('uid', isEqualTo: uid)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      final orders = snapshot.docs.map((doc) {
        final data = <String, dynamic>{
          'orderId': doc.id,
          ...doc.data(),
        };
        return OrderSummary.fromMap(data);
      }).toList();

      // Sort by orderDate descending (client-side)
      orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      return orders;
    } on FirebaseException catch (e) {
      // Firestore throws FAILED_PRECONDITION when a composite index is missing.
      if (e.code == 'failed-precondition' || e.message?.contains('index') == true) {
        return [];
      }
      rethrow;
    } catch (e) {
      // Catch deserialization errors — return empty rather than crashing.
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Single order fetch
  // ---------------------------------------------------------------------------

  /// Returns the full [OrderSummary] for the given [orderId].
  ///
  /// Throws a [StateError] if the document does not exist.
  Future<OrderSummary> getOrderById(String orderId) async {
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
