import '../entities/admin_order_view.dart';
import '../repositories/i_admin_order_repository.dart';

/// Returns a real-time stream of all active orders for the admin dashboard.
///
/// Active orders are those whose status is not `delivered` or `cancelled`,
/// sorted by creation time ascending (oldest first).
///
/// Wraps [IAdminOrderRepository.watchActiveOrders] as a single-responsibility
/// use case following Clean Architecture conventions.
class GetActiveOrdersUseCase {
  const GetActiveOrdersUseCase(this._repository);

  final IAdminOrderRepository _repository;

  /// Executes the use case.
  ///
  /// Returns a [Stream] that emits the list of active [AdminOrderView]s
  /// whenever the Firestore `/orders` collection changes.
  Stream<List<AdminOrderView>> call() => _repository.watchActiveOrders();
}
