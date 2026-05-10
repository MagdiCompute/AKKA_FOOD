import '../../domain/entities/admin_order_view.dart';
import '../../domain/entities/admin_user_view.dart';
import '../../domain/repositories/i_admin_user_repository.dart';
import '../datasources/cloud_function_admin_data_source.dart';
import '../datasources/firestore_admin_user_data_source.dart';

/// Concrete implementation of [IAdminUserRepository].
class AdminUserRepository implements IAdminUserRepository {
  const AdminUserRepository(
    this._firestoreDataSource,
    this._cloudFunctionDataSource,
  );

  final FirestoreAdminUserDataSource _firestoreDataSource;
  final CloudFunctionAdminDataSource _cloudFunctionDataSource;

  @override
  Stream<List<AdminUserView>> watchAllUsers() =>
      _firestoreDataSource.watchAllUsers();

  @override
  Future<AdminUserView?> getUserById(String uid) =>
      _firestoreDataSource.getUserById(uid);

  @override
  Future<List<AdminOrderView>> getUserOrders(String uid) =>
      _firestoreDataSource.getOrdersByUserId(uid);

  @override
  Future<void> deactivateUser(String uid) =>
      _cloudFunctionDataSource.deactivateUser(uid);

  @override
  Future<void> reactivateUser(String uid) =>
      _cloudFunctionDataSource.reactivateUser(uid);
}
