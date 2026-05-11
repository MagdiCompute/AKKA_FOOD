import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/user_profile/data/datasources/firestore_order_data_source.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Seeds [count] orders into [fakeFirestore] for [uid], ordered by
/// [createdAt] with the most recent first (index 0 = newest).
///
/// Returns the list of seeded document IDs in newest-first order.
Future<List<String>> _seedOrders(
  FakeFirebaseFirestore fakeFirestore,
  String uid,
  int count,
) async {
  final ids = <String>[];
  for (var i = 0; i < count; i++) {
    // Newer orders have a higher index in the date (i=0 → oldest, i=count-1 → newest).
    final ref = await fakeFirestore.collection('orders').add({
      'uid': uid,
      'items': [
        {'name': 'Item $i', 'quantity': 1, 'unitPrice': 1000.0},
      ],
      'totalAmount': 1000.0,
      'status': 'delivered',
      'deliveryAddress': 'Address $i',
      'paymentMethod': 'card',
      'createdAt': Timestamp.fromDate(DateTime(2024, 1, i + 1)),
    });
    ids.add(ref.id);
  }
  // Return newest-first (highest date index first).
  return ids.reversed.toList();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreOrderDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreOrderDataSource(firestore: fakeFirestore);
  });

  // -------------------------------------------------------------------------
  // getOrders
  // -------------------------------------------------------------------------

  group('getOrders', () {
    test('returns empty list when user has no orders', () async {
      final result = await dataSource.getOrders('user-1');
      expect(result, isEmpty);
    });

    test('returns orders for the given uid only', () async {
      await _seedOrders(fakeFirestore, 'user-1', 3);
      await _seedOrders(fakeFirestore, 'user-2', 5);

      final result = await dataSource.getOrders('user-1');

      expect(result, hasLength(3));
    });

    test('orders are sorted by createdAt descending (newest first)', () async {
      await _seedOrders(fakeFirestore, 'user-1', 3);

      final result = await dataSource.getOrders('user-1');

      expect(result, hasLength(3));
      // Each order's date should be >= the next one.
      for (var i = 0; i < result.length - 1; i++) {
        expect(
          result[i].orderDate.isAfter(result[i + 1].orderDate) ||
              result[i].orderDate.isAtSameMomentAs(result[i + 1].orderDate),
          isTrue,
          reason: 'Orders should be sorted newest-first',
        );
      }
    });

    test('respects pageSize — returns at most pageSize results', () async {
      await _seedOrders(fakeFirestore, 'user-1', 10);

      final result = await dataSource.getOrders('user-1', pageSize: 5);

      expect(result, hasLength(5));
    });

    test('default pageSize is 20', () async {
      await _seedOrders(fakeFirestore, 'user-1', 25);

      final result = await dataSource.getOrders('user-1');

      expect(result, hasLength(20));
    });

    test(
        'cursor-based pagination: second page returns next set of results '
        'with no overlap', () async {
      await _seedOrders(fakeFirestore, 'user-1', 5);

      // Fetch the first page snapshot using the same collection reference
      // and query structure as the data source, so the DocumentSnapshot
      // is compatible with startAfterDocument.
      final firstPageSnapshot = await fakeFirestore
          .collection('orders')
          .where('uid', isEqualTo: 'user-1')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      expect(firstPageSnapshot.docs, hasLength(2));
      final firstPageIds = firstPageSnapshot.docs.map((d) => d.id).toSet();

      // Use the last document of the first page as the cursor.
      final lastDoc = firstPageSnapshot.docs.last;
      final secondPage = await dataSource.getOrders(
        'user-1',
        pageSize: 2,
        lastDocument: lastDoc,
      );

      // No overlap between pages.
      final secondIds = secondPage.map((o) => o.orderId).toSet();
      expect(firstPageIds.intersection(secondIds), isEmpty,
          reason: 'Second page must not contain documents from the first page');
    });

    test('returns empty list when cursor is past the last document', () async {
      await _seedOrders(fakeFirestore, 'user-1', 3);

      // Fetch all docs using the same query structure as the data source.
      final allSnapshot = await fakeFirestore
          .collection('orders')
          .where('uid', isEqualTo: 'user-1')
          .orderBy('createdAt', descending: true)
          .get();

      expect(allSnapshot.docs, hasLength(3));

      final lastDoc = allSnapshot.docs.last;
      final result = await dataSource.getOrders(
        'user-1',
        pageSize: 20,
        lastDocument: lastDoc,
      );

      expect(result, isEmpty);
    });

    test('maps orderId from document id', () async {
      await _seedOrders(fakeFirestore, 'user-1', 1);

      final result = await dataSource.getOrders('user-1');

      expect(result.first.orderId, isNotEmpty);
    });

    test('maps items list correctly', () async {
      await fakeFirestore.collection('orders').add({
        'uid': 'user-1',
        'items': [
          {'name': 'Burger', 'quantity': 2, 'unitPrice': 2500.0},
          {'name': 'Fries', 'quantity': 1, 'unitPrice': 800.0},
        ],
        'totalAmount': 5800.0,
        'status': 'delivered',
        'paymentMethod': 'cash',
        'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1)),
      });

      final result = await dataSource.getOrders('user-1');

      expect(result.first.items, hasLength(2));
      expect(result.first.items.first.name, 'Burger');
      expect(result.first.items.first.quantity, 2);
      expect(result.first.totalAmount, 5800.0);
    });
  });

  // -------------------------------------------------------------------------
  // getOrderById
  // -------------------------------------------------------------------------

  group('getOrderById', () {
    test('returns the correct OrderSummary for a valid orderId', () async {
      final ref = await fakeFirestore.collection('orders').add({
        'uid': 'user-1',
        'items': [
          {'name': 'Pizza', 'quantity': 1, 'unitPrice': 5000.0},
        ],
        'totalAmount': 5000.0,
        'status': 'delivered',
        'deliveryAddress': '10 Rue de la Paix',
        'paymentMethod': 'card',
        'createdAt': Timestamp.fromDate(DateTime(2024, 3, 15)),
      });

      final result = await dataSource.getOrderById(ref.id);

      expect(result.orderId, ref.id);
      expect(result.totalAmount, 5000.0);
      expect(result.status, 'delivered');
      expect(result.deliveryAddress, '10 Rue de la Paix');
      expect(result.paymentMethod, 'card');
      expect(result.items, hasLength(1));
      expect(result.items.first.name, 'Pizza');
    });

    test('throws StateError when orderId does not exist', () async {
      expect(
        () => dataSource.getOrderById('non-existent-id'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('non-existent-id'),
          ),
        ),
      );
    });

    test('maps orderId from document id, not from data fields', () async {
      final ref = await fakeFirestore.collection('orders').add({
        'uid': 'user-1',
        'items': [],
        'totalAmount': 0.0,
        'status': 'pending',
        'paymentMethod': 'cash',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      });

      final result = await dataSource.getOrderById(ref.id);

      expect(result.orderId, ref.id);
    });
  });
}
