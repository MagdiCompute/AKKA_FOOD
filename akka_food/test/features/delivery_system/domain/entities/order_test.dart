import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_address.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_option.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order.dart';
import 'package:akka_food/features/delivery_system/domain/entities/order_item.dart';

void main() {
  group('Order', () {
    final baseCreatedAt = DateTime(2024, 6, 15, 10, 30);

    Order makeOrder({
      DeliveryOption deliveryOption = DeliveryOption.delivery,
      DeliveryAddress? deliveryAddress,
      DeliveryStatus status = DeliveryStatus.pending,
      int? etaMinutes,
      DateTime? deliveredAt,
      String? failureReason,
    }) {
      return Order(
        id: 'order_001',
        uid: 'user_123',
        items: const [
          OrderItem(
            mealId: 'meal_1',
            mealName: 'Jollof Rice',
            quantity: 2,
            unitPrice: 2500.0,
          ),
        ],
        subtotal: 5000.0,
        deliveryFee: 500.0,
        discount: 0.0,
        total: 5500.0,
        deliveryOption: deliveryOption,
        deliveryAddress: deliveryAddress ??
            const DeliveryAddress(
              street: '123 Main St',
              city: 'Abidjan',
              latitude: 5.3600,
              longitude: -4.0083,
              label: 'Home',
            ),
        status: status,
        etaMinutes: etaMinutes,
        createdAt: baseCreatedAt,
        deliveredAt: deliveredAt,
        failureReason: failureReason,
      );
    }

    // ── fromMap / toMap ─────────────────────────────────────────────────────

    test('fromMap creates Order with all fields', () {
      final map = <String, dynamic>{
        'uid': 'user_abc',
        'items': [
          {
            'mealId': 'meal_1',
            'mealName': 'Thieboudienne',
            'quantity': 1,
            'unitPrice': 3000.0,
          },
        ],
        'subtotal': 3000.0,
        'deliveryFee': 500.0,
        'discount': 200.0,
        'total': 3300.0,
        'deliveryOption': 'delivery',
        'deliveryAddress': {
          'street': '45 Rue du Commerce',
          'city': 'Dakar',
          'latitude': 14.6928,
          'longitude': -17.4467,
          'label': 'Work',
        },
        'status': 'confirmed',
        'etaMinutes': 25,
        'createdAt': '2024-06-15T10:30:00.000',
        'deliveredAt': null,
        'failureReason': null,
      };

      final order = Order.fromMap('order_xyz', map);

      expect(order.id, equals('order_xyz'));
      expect(order.uid, equals('user_abc'));
      expect(order.items.length, equals(1));
      expect(order.items.first.mealName, equals('Thieboudienne'));
      expect(order.subtotal, equals(3000.0));
      expect(order.deliveryFee, equals(500.0));
      expect(order.discount, equals(200.0));
      expect(order.total, equals(3300.0));
      expect(order.deliveryOption, equals(DeliveryOption.delivery));
      expect(order.deliveryAddress, isNotNull);
      expect(order.deliveryAddress!.street, equals('45 Rue du Commerce'));
      expect(order.deliveryAddress!.latitude, equals(14.6928));
      expect(order.status, equals(DeliveryStatus.confirmed));
      expect(order.etaMinutes, equals(25));
      expect(order.deliveredAt, isNull);
      expect(order.failureReason, isNull);
    });

    test('fromMap handles missing optional fields gracefully', () {
      final map = <String, dynamic>{
        'uid': 'user_abc',
        'items': <dynamic>[],
        'subtotal': 0,
        'deliveryFee': 0,
        'discount': 0,
        'total': 0,
        'deliveryOption': 'pickup',
        'status': 'pending',
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final order = Order.fromMap('order_min', map);

      expect(order.deliveryAddress, isNull);
      expect(order.etaMinutes, isNull);
      expect(order.deliveredAt, isNull);
      expect(order.failureReason, isNull);
      expect(order.deliveryOption, equals(DeliveryOption.pickup));
    });

    test('toMap → fromMap round-trip preserves all fields', () {
      final original = makeOrder(
        status: DeliveryStatus.delivered,
        etaMinutes: 30,
        deliveredAt: DateTime(2024, 6, 15, 11, 0),
      );

      final map = original.toMap();
      final restored = Order.fromMap(original.id, map);

      expect(restored.id, equals(original.id));
      expect(restored.uid, equals(original.uid));
      expect(restored.items.length, equals(original.items.length));
      expect(restored.subtotal, equals(original.subtotal));
      expect(restored.deliveryFee, equals(original.deliveryFee));
      expect(restored.discount, equals(original.discount));
      expect(restored.total, equals(original.total));
      expect(restored.deliveryOption, equals(original.deliveryOption));
      expect(restored.deliveryAddress, equals(original.deliveryAddress));
      expect(restored.status, equals(original.status));
      expect(restored.etaMinutes, equals(original.etaMinutes));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.deliveredAt, equals(original.deliveredAt));
      expect(restored.failureReason, equals(original.failureReason));
    });

    test('toMap omits null optional fields', () {
      final order = makeOrder(
        etaMinutes: null,
        deliveredAt: null,
        failureReason: null,
      );

      final map = order.toMap();

      expect(map.containsKey('etaMinutes'), isFalse);
      expect(map.containsKey('deliveredAt'), isFalse);
      expect(map.containsKey('failureReason'), isFalse);
    });

    test('toMap includes non-null optional fields', () {
      final order = makeOrder(
        status: DeliveryStatus.failed,
        failureReason: 'Customer unreachable',
      );

      final map = order.toMap();

      expect(map['failureReason'], equals('Customer unreachable'));
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith preserves all fields when no arguments given', () {
      final order = makeOrder();
      final copy = order.copyWith();

      expect(copy, equals(order));
    });

    test('copyWith can update status', () {
      final order = makeOrder(status: DeliveryStatus.pending);
      final updated = order.copyWith(status: DeliveryStatus.confirmed);

      expect(updated.status, equals(DeliveryStatus.confirmed));
      expect(updated.id, equals(order.id));
    });

    test('copyWith can set nullable fields to null explicitly', () {
      final order = makeOrder(
        etaMinutes: 30,
        failureReason: 'some reason',
        deliveredAt: DateTime(2024, 6, 15, 11, 0),
      );

      final cleared = order.copyWith(
        etaMinutes: null,
        failureReason: null,
        deliveredAt: null,
        deliveryAddress: null,
      );

      expect(cleared.etaMinutes, isNull);
      expect(cleared.failureReason, isNull);
      expect(cleared.deliveredAt, isNull);
      expect(cleared.deliveryAddress, isNull);
    });

    // ── equality ─────────────────────────────────────────────────────────────

    test('two orders with same data are equal', () {
      final a = makeOrder();
      final b = makeOrder();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('orders with different status are not equal', () {
      final a = makeOrder(status: DeliveryStatus.pending);
      final b = makeOrder(status: DeliveryStatus.delivered);

      expect(a, isNot(equals(b)));
    });

    // ── toString ─────────────────────────────────────────────────────────────

    test('toString contains key fields', () {
      final order = makeOrder();
      final str = order.toString();

      expect(str, contains('order_001'));
      expect(str, contains('user_123'));
      expect(str, contains('pending'));
    });
  });

  group('DeliveryAddress', () {
    test('fromMap creates address with all fields', () {
      final map = <String, dynamic>{
        'street': '10 Avenue Houphouet',
        'city': 'Abidjan',
        'latitude': 5.3167,
        'longitude': -4.0333,
        'label': 'Office',
      };

      final address = DeliveryAddress.fromMap(map);

      expect(address.street, equals('10 Avenue Houphouet'));
      expect(address.city, equals('Abidjan'));
      expect(address.latitude, equals(5.3167));
      expect(address.longitude, equals(-4.0333));
      expect(address.label, equals('Office'));
    });

    test('toMap → fromMap round-trip preserves data', () {
      const original = DeliveryAddress(
        street: '5 Rue de la Paix',
        city: 'Bamako',
        latitude: 12.6392,
        longitude: -8.0029,
        label: 'Home',
      );

      final restored = DeliveryAddress.fromMap(original.toMap());

      expect(restored, equals(original));
    });

    test('toMap omits label when null', () {
      const address = DeliveryAddress(
        street: 'Street',
        city: 'City',
        latitude: 0.0,
        longitude: 0.0,
      );

      final map = address.toMap();

      expect(map.containsKey('label'), isFalse);
    });

    test('copyWith can set label to null', () {
      const address = DeliveryAddress(
        street: 'Street',
        city: 'City',
        latitude: 0.0,
        longitude: 0.0,
        label: 'Home',
      );

      final cleared = address.copyWith(label: null);

      expect(cleared.label, isNull);
      expect(cleared.street, equals('Street'));
    });
  });

  group('OrderItem', () {
    test('lineTotal computes correctly', () {
      const item = OrderItem(
        mealId: 'meal_1',
        mealName: 'Attiéké',
        quantity: 3,
        unitPrice: 1500.0,
      );

      expect(item.lineTotal, equals(4500.0));
    });

    test('fromMap → toMap round-trip preserves data', () {
      const original = OrderItem(
        mealId: 'meal_2',
        mealName: 'Alloco',
        quantity: 2,
        unitPrice: 1000.0,
      );

      final restored = OrderItem.fromMap(original.toMap());

      expect(restored, equals(original));
    });
  });
}
