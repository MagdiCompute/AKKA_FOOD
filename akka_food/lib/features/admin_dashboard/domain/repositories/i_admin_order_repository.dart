import '../entities/admin_order_view.dart';

/// Abstract repository interface for admin order operations.
///
/// Implementations live in the data layer and depend on Firebase.
/// The domain layer only depends on this interface.
abstract interface class IAdminOrderRepository {
  /// Returns a real-time stream of all active orders.
  ///
  /// Active orders are those whose status is not `delivered` or `cancelled`.
  /// The stream emits a new list whenever the `/orders` collection changes,
  /// sorted by [AdminOrderView.createdAt] ascending (oldest first).
  Stream<List<AdminOrderView>> watchActiveOrders();

  /// Returns a real-time stream of ALL orders (including delivered/cancelled).
  ///
  /// The stream emits a new list whenever the `/orders` collection changes,
  /// sorted by [AdminOrderView.createdAt] descending (newest first).
  Stream<List<AdminOrderView>> watchAllOrders();

  /// Fetches a single order by its [orderId].
  ///
  /// Returns `null` if no order with the given ID exists.
  /// Throws on network or permission errors.
  Future<AdminOrderView?> getOrderById(String orderId);

  /// Updates the delivery status of the order identified by [orderId].
  ///
  /// [etaMinutes] is required when [status] is [DeliveryStatus.outForDelivery].
  /// Delegates to the `adminUpdateOrderStatus` Cloud Function.
  /// Throws a [FirebaseFunctionsException] on error.
  Future<void> updateOrderStatus(
    String orderId,
    DeliveryStatus status, {
    int? etaMinutes,
  });
}
