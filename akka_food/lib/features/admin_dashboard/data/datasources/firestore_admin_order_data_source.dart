import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_order_view.dart';

/// Handles all Firestore read operations for the `/orders` collection
/// in the context of the admin dashboard.
///
/// Filters to active orders only (status not in ['delivered', 'cancelled'])
/// and sorts by [createdAt] ascending so the oldest order appears first.
///
/// Note: Firestore does not support `not-in` combined with `orderBy` on a
/// different field without a composite index. We therefore fetch all orders
/// ordered by `createdAt` and filter the terminal statuses client-side.
/// This is acceptable because the admin dashboard only shows active orders
/// and the collection size is bounded by the restaurant's throughput.
class FirestoreAdminOrderDataSource {
  FirestoreAdminOrderDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  /// The set of terminal status strings that are excluded from the active list.
  static const _terminalStatuses = {'delivered', 'cancelled'};

  /// Returns a real-time stream of active orders sorted by [createdAt] asc.
  ///
  /// Active orders: status not in ['delivered', 'cancelled'].
  /// Sorted by createdAt ascending (oldest first) per Requirement 4.1.
  Stream<List<AdminOrderView>> watchActiveOrders() {
    return _ordersCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminOrderView.fromMap(doc.id, doc.data()))
          .where((order) =>
              !_terminalStatuses.contains(order.status.toFirestoreString()))
          .toList();
    });
  }

  /// Returns a real-time stream of ALL orders sorted by [createdAt] desc.
  ///
  /// Includes delivered and cancelled orders. Used by the admin dashboard
  /// to provide a complete order history view.
  Stream<List<AdminOrderView>> watchAllOrders() {
    return _ordersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminOrderView.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Fetches a single order document by [orderId].
  ///
  /// Returns `null` if the document does not exist.
  Future<AdminOrderView?> getOrderById(String orderId) async {
    final doc = await _ordersCollection.doc(orderId).get();
    if (!doc.exists) return null;
    return AdminOrderView.fromMap(doc.id, doc.data()!);
  }
}
