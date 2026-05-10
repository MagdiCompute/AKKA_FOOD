import '../entities/admin_order_view.dart';
import '../repositories/i_admin_user_repository.dart';

/// Fetches the order history for a specific user (admin view).
class GetUserOrdersUseCase {
  const GetUserOrdersUseCase(this._repository);
  final IAdminUserRepository _repository;

  Future<List<AdminOrderView>> call(String uid) =>
      _repository.getUserOrders(uid);
}
