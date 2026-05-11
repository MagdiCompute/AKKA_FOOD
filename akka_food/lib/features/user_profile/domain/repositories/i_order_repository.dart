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

  /// Returns a stale-while-revalidate stream of the first page of
  /// [OrderSummary] records for [uid], ordered by order date descending.
  ///
  /// Emits the cached first page immediately (if available), then fetches
  /// fresh data from Firestore in the background and emits the updated list.
  ///
  /// On network error:
  /// - If cached data was emitted, the stream completes silently (caller
  ///   should display a connectivity banner).
  /// - If no cached data was available, the stream emits an error.
  Stream<List<OrderSummary>> watchOrderHistory(
    String uid, {
    int pageSize = 20,
  });
}
