import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_order_view.dart';
import '../../domain/repositories/i_admin_order_repository.dart';
import '../datasources/cloud_function_admin_data_source.dart';
import '../datasources/firestore_admin_order_data_source.dart';

/// Concrete implementation of [IAdminOrderRepository].
///
/// Delegates read operations to [FirestoreAdminOrderDataSource].
/// Write operations go directly to Firestore (Cloud Functions not yet deployed).
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
  Stream<List<AdminOrderView>> watchAllOrders() =>
      _firestoreDataSource.watchAllOrders();

  @override
  Future<AdminOrderView?> getOrderById(String orderId) =>
      _firestoreDataSource.getOrderById(orderId);

  @override
  Future<void> updateOrderStatus(
    String orderId,
    DeliveryStatus status, {
    int? etaMinutes,
  }) async {
    final data = <String, dynamic>{
      'status': status.toFirestoreString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (etaMinutes != null) {
      data['etaMinutes'] = etaMinutes;
    }
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update(data);
  }
}
