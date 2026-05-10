import '../entities/admin_order_view.dart';
import '../entities/admin_user_view.dart';

/// Abstract repository interface for admin user operations.
abstract interface class IAdminUserRepository {
  /// Returns a real-time stream of all registered users.
  Stream<List<AdminUserView>> watchAllUsers();

  /// Fetches a single user by [uid].
  Future<AdminUserView?> getUserById(String uid);

  /// Fetches the order history for the user identified by [uid].
  ///
  /// Returns up to 20 most recent orders, sorted by [createdAt] descending.
  Future<List<AdminOrderView>> getUserOrders(String uid);

  /// Deactivates the user account identified by [uid].
  Future<void> deactivateUser(String uid);

  /// Reactivates the user account identified by [uid].
  Future<void> reactivateUser(String uid);
}
