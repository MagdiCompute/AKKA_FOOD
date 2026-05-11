import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/data/datasources/firestore_delivery_data_source.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreDeliveryDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreDeliveryDataSource(fakeFirestore);
  });

  // ---------------------------------------------------------------------------
  // Helper to seed tracking updates
  // ---------------------------------------------------------------------------

  Future<void> seedTrackingUpdate(
    String orderId, {
    required String status,
    required DateTime timestamp,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      if (note != null) 'note': note,
    };
    await fakeFirestore
        .collection('orders')
        .doc(orderId)
        .collection('trackingUpdates')
        .add(data);
  }

  // ---------------------------------------------------------------------------
  // getTrackingUpdates
  // ---------------------------------------------------------------------------

  group('getTrackingUpdates', () {
    test('returns empty list when no tracking updates exist', () async {
      final result = await dataSource.getTrackingUpdates('order_empty');
      expect(result, isEmpty);
    });

    test('returns all tracking updates for the given orderId', () async {
      await seedTrackingUpdate(
        'order_1',
        status: 'pending',
        timestamp: DateTime(2024, 6, 1, 10, 0),
      );
      await seedTrackingUpdate(
        'order_1',
        status: 'confirmed',
        timestamp: DateTime(2024, 6, 1, 10, 5),
        note: 'Order confirmed by restaurant',
      );

      final result = await dataSource.getTrackingUpdates('order_1');

      expect(result, hasLength(2));
    });

    test('maps orderId from parent document path', () async {
      await seedTrackingUpdate(
        'order_abc',
        status: 'pending',
        timestamp: DateTime(2024, 6, 1, 10, 0),
      );

      final result = await dataSource.getTrackingUpdates('order_abc');

      expect(result.first.orderId, equals('order_abc'));
    });

    test('maps status correctly', () async {
      await seedTrackingUpdate(
        'order_1',
        status: 'out_for_delivery',
        timestamp: DateTime(2024, 6, 1, 11, 0),
        note: 'Driver en route',
      );

      final result = await dataSource.getTrackingUpdates('order_1');

      expect(result.first.status, equals(DeliveryStatus.outForDelivery));
      expect(result.first.note, equals('Driver en route'));
    });

    test('results are ordered by timestamp ascending', () async {
      // Seed in reverse order to verify sorting
      await seedTrackingUpdate(
        'order_1',
        status: 'confirmed',
        timestamp: DateTime(2024, 6, 1, 10, 5),
      );
      await seedTrackingUpdate(
        'order_1',
        status: 'pending',
        timestamp: DateTime(2024, 6, 1, 10, 0),
      );
      await seedTrackingUpdate(
        'order_1',
        status: 'preparing',
        timestamp: DateTime(2024, 6, 1, 10, 10),
      );

      final result = await dataSource.getTrackingUpdates('order_1');

      expect(result, hasLength(3));
      expect(result[0].status, equals(DeliveryStatus.pending));
      expect(result[1].status, equals(DeliveryStatus.confirmed));
      expect(result[2].status, equals(DeliveryStatus.preparing));
    });

    test('does not return tracking updates from other orders', () async {
      await seedTrackingUpdate(
        'order_1',
        status: 'pending',
        timestamp: DateTime(2024, 6, 1, 10, 0),
      );
      await seedTrackingUpdate(
        'order_2',
        status: 'confirmed',
        timestamp: DateTime(2024, 6, 1, 10, 5),
      );

      final result = await dataSource.getTrackingUpdates('order_1');

      expect(result, hasLength(1));
      expect(result.first.orderId, equals('order_1'));
    });
  });

  // ---------------------------------------------------------------------------
  // watchTrackingUpdates
  // ---------------------------------------------------------------------------

  group('watchTrackingUpdates', () {
    test('emits empty list initially when no updates exist', () async {
      final stream = dataSource.watchTrackingUpdates('order_empty');

      await expectLater(
        stream,
        emits(isEmpty),
      );
    });

    test('emits tracking updates ordered by timestamp ascending', () async {
      await seedTrackingUpdate(
        'order_1',
        status: 'confirmed',
        timestamp: DateTime(2024, 6, 1, 10, 5),
      );
      await seedTrackingUpdate(
        'order_1',
        status: 'pending',
        timestamp: DateTime(2024, 6, 1, 10, 0),
      );

      final stream = dataSource.watchTrackingUpdates('order_1');

      await expectLater(
        stream,
        emits(
          allOf(
            hasLength(2),
            predicate<List>((list) =>
                list[0].status == DeliveryStatus.pending &&
                list[1].status == DeliveryStatus.confirmed),
          ),
        ),
      );
    });

    test('maps orderId correctly in stream results', () async {
      await seedTrackingUpdate(
        'order_stream',
        status: 'preparing',
        timestamp: DateTime(2024, 6, 1, 10, 10),
        note: 'Being prepared',
      );

      final stream = dataSource.watchTrackingUpdates('order_stream');

      await expectLater(
        stream,
        emits(
          predicate<List>((list) =>
              list.length == 1 &&
              list[0].orderId == 'order_stream' &&
              list[0].note == 'Being prepared'),
        ),
      );
    });
  });
}
