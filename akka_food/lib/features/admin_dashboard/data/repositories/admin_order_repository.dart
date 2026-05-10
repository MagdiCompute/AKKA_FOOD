import '../../domain/entities/admin_order_view.dart';
import '../../domain/repositories/i_admin_order_repository.dart';
import '../datasources/cloud_function_admin_data_source.dart';
import '../datasources/firestore_admin_order_data_source.dart';

/// Concrete implementation of [IAdminOrderRepository].
///
/// Delegates read operations to [FirestoreAdminOrderDataSource] and
/// write operations to [CloudFunctionAdminDataSource].
class AdminOrderRepository implements IAdminOrderRepository {
  AdminOrderRepository(
    this._firestoreDataSource, {
    CloudFunctionAdminDataSource? cloudFunctionDataSource,
  }) : _cloudFunctionDataSource =
           cloudFunctionDataSource ?? CloudFunctionAdminDataSource();

  final FirestoreAdminOrderDataSource _firestoreDataSource;
  final CloudFunctionAdminDataSource _cloudFunctionDataSource;

  @override
  Stream<List<AdminOrderView>> watchActiveOrders() =>
      _firestoreDataSource.watchActiveOrders();

  @override
  Future<AdminOrderView?> getOrderById(String orderId) =>
      _firestoreDataSource.getOrderById(orderId);

  @override
  Future<void> updateOrderStatus(
    String orderId,
    DeliveryStatus status, {
    int? etaMinutes,
  }) =>
      _cloudFunctionDataSource.updateOrderStatus(
        orderId,
        status.toFirestoreString(),
        etaMinutes: etaMinutes,
      );
}
