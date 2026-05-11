import '../entities/delivery_status.dart';
import '../entities/order.dart';
import '../entities/tracking_update.dart';

/// Abstract interface for the delivery repository.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implementations live in `data/repositories/`.
abstract class IDeliveryRepository {
  /// Real-time listener on a single order.
  ///
  /// Emits the latest [Order] snapshot whenever the document changes.
  Stream<Order> watchOrder(String orderId);

  /// Fetches a single order by its ID.
  ///
  /// Returns `null` if the order does not exist.
  Future<Order?> getOrder(String orderId);

  /// Retrieves all tracking updates for the given order.
  Future<List<TrackingUpdate>> getTrackingUpdates(String orderId);

  /// Real-time listener on tracking updates for the given order.
  ///
  /// Emits the full list of [TrackingUpdate]s whenever the subcollection
  /// changes.
  Stream<List<TrackingUpdate>> watchTrackingUpdates(String orderId);

  /// Updates the delivery status of an order (admin action).
  ///
  /// Optionally sets [etaMinutes] when transitioning to
  /// [DeliveryStatus.outForDelivery].
  Future<void> updateOrderStatus(
    String orderId,
    DeliveryStatus newStatus, {
    int? etaMinutes,
  });

  /// Stream of active (non-terminal) orders for admin monitoring.
  ///
  /// Active orders are those whose status is not
  /// [DeliveryStatus.delivered] or [DeliveryStatus.failed].
  Stream<List<Order>> getActiveOrders();
}
