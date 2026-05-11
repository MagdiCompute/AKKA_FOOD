import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/tracking_update.dart';

void main() {
  group('TrackingUpdate', () {
    final baseTimestamp = DateTime(2024, 6, 15, 10, 30);

    TrackingUpdate makeUpdate({
      String orderId = 'order_001',
      DeliveryStatus status = DeliveryStatus.confirmed,
      DateTime? timestamp,
      String? note,
    }) {
      return TrackingUpdate(
        orderId: orderId,
        status: status,
        timestamp: timestamp ?? baseTimestamp,
        note: note,
      );
    }

    // ── fromMap / toMap ─────────────────────────────────────────────────────

    test('fromMap creates TrackingUpdate with all fields', () {
      final map = <String, dynamic>{
        'status': 'out_for_delivery',
        'timestamp': '2024-06-15T11:00:00.000',
        'note': 'Driver en route',
      };

      final update = TrackingUpdate.fromMap('order_xyz', map);

      expect(update.orderId, equals('order_xyz'));
      expect(update.status, equals(DeliveryStatus.outForDelivery));
      expect(update.timestamp, equals(DateTime(2024, 6, 15, 11, 0)));
      expect(update.note, equals('Driver en route'));
    });

    test('fromMap handles missing optional note', () {
      final map = <String, dynamic>{
        'status': 'pending',
        'timestamp': '2024-01-01T00:00:00.000',
      };

      final update = TrackingUpdate.fromMap('order_min', map);

      expect(update.orderId, equals('order_min'));
      expect(update.status, equals(DeliveryStatus.pending));
      expect(update.note, isNull);
    });

    test('fromMap handles DateTime value directly', () {
      final dt = DateTime(2024, 3, 20, 14, 45);
      final map = <String, dynamic>{
        'status': 'confirmed',
        'timestamp': dt,
        'note': null,
      };

      final update = TrackingUpdate.fromMap('order_dt', map);

      expect(update.timestamp, equals(dt));
    });

    test('fromMap handles duck-typed Timestamp object', () {
      final expectedDate = DateTime(2024, 7, 1, 9, 0);
      final fakeTimestamp = _FakeTimestamp(expectedDate);
      final map = <String, dynamic>{
        'status': 'preparing',
        'timestamp': fakeTimestamp,
      };

      final update = TrackingUpdate.fromMap('order_ts', map);

      expect(update.timestamp, equals(expectedDate));
    });

    test('toMap → fromMap round-trip preserves all fields', () {
      final original = makeUpdate(
        orderId: 'order_round',
        status: DeliveryStatus.delivered,
        timestamp: DateTime(2024, 6, 15, 12, 0),
        note: 'Left at door',
      );

      final map = original.toMap();
      final restored = TrackingUpdate.fromMap(original.orderId, map);

      expect(restored.orderId, equals(original.orderId));
      expect(restored.status, equals(original.status));
      expect(restored.timestamp, equals(original.timestamp));
      expect(restored.note, equals(original.note));
    });

    test('toMap omits note when null', () {
      final update = makeUpdate(note: null);
      final map = update.toMap();

      expect(map.containsKey('note'), isFalse);
    });

    test('toMap includes note when present', () {
      final update = makeUpdate(note: 'Order picked up');
      final map = update.toMap();

      expect(map['note'], equals('Order picked up'));
    });

    test('toMap does not include orderId (stored as parent doc path)', () {
      final update = makeUpdate();
      final map = update.toMap();

      expect(map.containsKey('orderId'), isFalse);
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith preserves all fields when no arguments given', () {
      final update = makeUpdate(note: 'Some note');
      final copy = update.copyWith();

      expect(copy, equals(update));
    });

    test('copyWith can update status', () {
      final update = makeUpdate(status: DeliveryStatus.pending);
      final updated = update.copyWith(status: DeliveryStatus.preparing);

      expect(updated.status, equals(DeliveryStatus.preparing));
      expect(updated.orderId, equals(update.orderId));
    });

    test('copyWith can set note to null explicitly', () {
      final update = makeUpdate(note: 'Has a note');
      final cleared = update.copyWith(note: null);

      expect(cleared.note, isNull);
      expect(cleared.orderId, equals(update.orderId));
      expect(cleared.status, equals(update.status));
    });

    test('copyWith can change orderId', () {
      final update = makeUpdate(orderId: 'order_old');
      final changed = update.copyWith(orderId: 'order_new');

      expect(changed.orderId, equals('order_new'));
    });

    // ── equality ─────────────────────────────────────────────────────────────

    test('two updates with same data are equal', () {
      final a = makeUpdate(note: 'Same');
      final b = makeUpdate(note: 'Same');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('updates with different status are not equal', () {
      final a = makeUpdate(status: DeliveryStatus.pending);
      final b = makeUpdate(status: DeliveryStatus.delivered);

      expect(a, isNot(equals(b)));
    });

    test('updates with different note are not equal', () {
      final a = makeUpdate(note: 'Note A');
      final b = makeUpdate(note: 'Note B');

      expect(a, isNot(equals(b)));
    });

    test('updates with different orderId are not equal', () {
      final a = makeUpdate(orderId: 'order_1');
      final b = makeUpdate(orderId: 'order_2');

      expect(a, isNot(equals(b)));
    });

    // ── toString ─────────────────────────────────────────────────────────────

    test('toString contains key fields', () {
      final update = makeUpdate(
        orderId: 'order_str',
        status: DeliveryStatus.outForDelivery,
        note: 'Almost there',
      );
      final str = update.toString();

      expect(str, contains('order_str'));
      expect(str, contains('outForDelivery'));
      expect(str, contains('Almost there'));
    });
  });
}

/// Fake Timestamp class that mimics Firestore's Timestamp.toDate() method
/// for testing the duck-typing _parseDateTime helper.
class _FakeTimestamp {
  final DateTime _date;

  _FakeTimestamp(this._date);

  DateTime toDate() => _date;
}
