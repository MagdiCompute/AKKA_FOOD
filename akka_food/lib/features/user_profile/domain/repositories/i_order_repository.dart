import '../entities/order_summary.dart';

/// Abstract repository interface for order history operations.
///
/// Pure Dart — zero Flutter or Firebase imports.
/// Implementations live in the data layer.
abstract class IOrderRepository {
  /// Returns a paginated list of [OrderSummary] records for [uid], ordered
  /// by order date descending.
  ///
  /// [page] is 1-indexed; [pageSize] defaults to 20.
  /// Returns an empty list when the user has no orders.
  Future<List<OrderSummary>> getOrderHistory(
    String uid, {
    int page = 1,
    int pageSize = 20,
  });

  /// Returns the full [OrderSummary] for the given [orderId], including all
  /// line items, delivery address, payment method, and final status.
  ///
  /// Throws if the order does not exist or the caller is unauthorised.
  Future<OrderSummary> getOrderDetail(String orderId);
}
