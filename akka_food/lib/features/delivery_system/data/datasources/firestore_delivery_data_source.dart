import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import 'package:akka_food/features/delivery_system/domain/entities/order.dart';
import 'package:akka_food/features/delivery_system/domain/entities/tracking_update.dart';

/// Firestore data source for the delivery system.
///
/// Handles all direct Firestore interactions for the `/orders` collection,
/// providing both real-time streams and one-shot reads.
/// Firebase imports are intentionally confined to this data-layer class.
class FirestoreDeliveryDataSource {
  FirestoreDeliveryDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'orders';
  static const String _trackingUpdatesSubcollection = 'trackingUpdates';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of [Order] updates for the given [orderId].
  ///
  /// Listens to `/orders/{orderId}` document snapshots and maps each snapshot
  /// to an [Order] entity. Throws a [StateError] if the document does not
  /// exist or has null data.
  Stream<Order> watchOrder(String orderId) {
    return _firestore
        .collection(_collection)
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Order document "$orderId" does not exist.');
      }
      return Order.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  /// Fetches a single [Order] by its [orderId].
  ///
  /// Returns `null` if the document does not exist.
  Future<Order?> getOrder(String orderId) async {
    final doc =
        await _firestore.collection(_collection).doc(orderId).get();

    if (!doc.exists || doc.data() == null) return null;

    return Order.fromMap(doc.id, doc.data()!);
  }

  /// Returns a real-time stream of active (non-terminal) orders.
  ///
  /// Active orders are those whose status is not `delivered` or `failed`.
  /// Results are sorted by `createdAt` ascending (oldest first).
  Stream<List<Order>> watchActiveOrders() {
    return _firestore
        .collection(_collection)
        .where('status', whereNotIn: ['delivered', 'failed'])
        .orderBy('status')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => _snapshotToOrders(snapshot));
  }

  /// Updates the delivery status of an order.
  ///
  /// Optionally sets [etaMinutes] and [deliveredAt] based on the new status.
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    int? etaMinutes,
    DateTime? deliveredAt,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus,
    };

    if (etaMinutes != null) {
      updates['etaMinutes'] = etaMinutes;
    }

    if (deliveredAt != null) {
      updates['deliveredAt'] = Timestamp.fromDate(deliveredAt);
    }

    await _firestore.collection(_collection).doc(orderId).update(updates);
  }

  // ---------------------------------------------------------------------------
  // Tracking Updates
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of [TrackingUpdate]s for the given [orderId].
  ///
  /// Listens to `/orders/{orderId}/trackingUpdates` subcollection ordered by
  /// `timestamp` ascending. Each snapshot is mapped to a list of
  /// [TrackingUpdate] entities.
  Stream<List<TrackingUpdate>> watchTrackingUpdates(String orderId) {
    return _firestore
        .collection(_collection)
        .doc(orderId)
        .collection(_trackingUpdatesSubcollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => _snapshotToTrackingUpdates(orderId, snapshot));
  }

  /// Fetches all [TrackingUpdate]s for the given [orderId] as a one-shot read.
  ///
  /// Results are ordered by `timestamp` ascending.
  Future<List<TrackingUpdate>> getTrackingUpdates(String orderId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(orderId)
        .collection(_trackingUpdatesSubcollection)
        .orderBy('timestamp', descending: false)
        .get();

    return _snapshotToTrackingUpdates(orderId, snapshot);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts a Firestore [QuerySnapshot] to a list of [Order]s.
  List<Order> _snapshotToOrders(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((doc) {
      return Order.fromMap(doc.id, doc.data());
    }).toList();
  }

  /// Converts a Firestore [QuerySnapshot] to a list of [TrackingUpdate]s.
  List<TrackingUpdate> _snapshotToTrackingUpdates(
    String orderId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) {
      return TrackingUpdate.fromMap(orderId, doc.data());
    }).toList();
  }
}
