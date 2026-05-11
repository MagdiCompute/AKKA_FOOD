import 'package:akka_food/features/delivery_system/data/datasources/firestore_delivery_data_source.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order.dart';
import 'package:akka_food/features/delivery_system/domain/entities/tracking_update.dart';
import 'package:akka_food/features/delivery_system/domain/repositories/i_delivery_repository.dart';

/// Concrete implementation of [IDeliveryRepository].
///
/// Bridges the domain layer and the data layer by delegating all operations
/// to [FirestoreDeliveryDataSource].
class DeliveryRepository implements IDeliveryRepository {
  DeliveryRepository(this._dataSource);

  final FirestoreDeliveryDataSource _dataSource;

  @override
  Stream<Order> watchOrder(String orderId) {
    return _dataSource.watchOrder(orderId);
  }

  @override
  Future<Order?> getOrder(String orderId) {
    return _dataSource.getOrder(orderId);
  }

  @override
  Future<List<TrackingUpdate>> getTrackingUpdates(String orderId) {
    return _dataSource.getTrackingUpdates(orderId);
  }

  @override
  Stream<List<TrackingUpdate>> watchTrackingUpdates(String orderId) {
    return _dataSource.watchTrackingUpdates(orderId);
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    DeliveryStatus newStatus, {
    int? etaMinutes,
  }) {
    return _dataSource.updateOrderStatus(
      orderId,
      newStatus.toFirestoreString(),
      etaMinutes: etaMinutes,
      deliveredAt:
          newStatus == DeliveryStatus.delivered ? DateTime.now() : null,
    );
  }

  @override
  Stream<List<Order>> getActiveOrders() {
    return _dataSource.watchActiveOrders();
  }
}
