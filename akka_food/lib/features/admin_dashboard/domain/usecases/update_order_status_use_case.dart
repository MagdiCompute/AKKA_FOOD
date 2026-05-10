import '../entities/admin_order_view.dart';
import '../repositories/i_admin_order_repository.dart';

/// Updates the delivery status of an order via the admin Cloud Function.
///
/// When [status] is [DeliveryStatus.outForDelivery], [etaMinutes] must be
/// provided (Requirement 4.5).
///
/// Wraps [IAdminOrderRepository.updateOrderStatus] as a single-responsibility
/// use case following Clean Architecture conventions.
class UpdateOrderStatusUseCase {
  const UpdateOrderStatusUseCase(this._repository);

  final IAdminOrderRepository _repository;

  /// Executes the use case.
  ///
  /// Throws an [ArgumentError] if [status] is [DeliveryStatus.outForDelivery]
  /// and [etaMinutes] is not provided.
  /// Throws a [FirebaseFunctionsException] on Cloud Function errors.
  Future<void> call(
    String orderId,
    DeliveryStatus status, {
    int? etaMinutes,
  }) {
    if (status == DeliveryStatus.outForDelivery && etaMinutes == null) {
      throw ArgumentError(
        'etaMinutes is required when status is outForDelivery.',
      );
    }
    return _repository.updateOrderStatus(
      orderId,
      status,
      etaMinutes: etaMinutes,
    );
  }
}
