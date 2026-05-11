import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/payment_processing/domain/entities/payment_result.dart';
import 'package:akka_food/features/payment_processing/domain/entities/payment_status.dart';

void main() {
  group('PaymentResult', () {
    PaymentResult makeResult({
      PaymentStatus status = PaymentStatus.pending,
      String? orderId,
    }) =>
        PaymentResult(
          transactionId: 'txn_001',
          status: status,
          orderId: orderId,
        );

    // ── Construction ──────────────────────────────────────────────────────────

    test('constructs with required fields and nullable orderId', () {
      final result = makeResult();

      expect(result.transactionId, equals('txn_001'));
      expect(result.status, equals(PaymentStatus.pending));
      expect(result.orderId, isNull);
    });

    test('constructs with all fields including orderId', () {
      final result = makeResult(
        status: PaymentStatus.success,
        orderId: 'order_abc',
      );

      expect(result.transactionId, equals('txn_001'));
      expect(result.status, equals(PaymentStatus.success));
      expect(result.orderId, equals('order_abc'));
    });

    // ── fromMap / toMap round-trip ─────────────────────────────────────────────

    test('fromMap creates a PaymentResult from a valid map', () {
      final map = {
        'transactionId': 'txn_002',
        'status': 'success',
        'orderId': 'order_xyz',
      };

      final result = PaymentResult.fromMap(map);

      expect(result.transactionId, equals('txn_002'));
      expect(result.status, equals(PaymentStatus.success));
      expect(result.orderId, equals('order_xyz'));
    });

    test('toMap → fromMap round-trip preserves all fields', () {
      final original = makeResult(
        status: PaymentStatus.success,
        orderId: 'order_123',
      );
      final map = original.toMap();
      final restored = PaymentResult.fromMap(map);

      expect(restored, equals(original));
    });

    test('toMap → fromMap round-trip preserves null orderId', () {
      final original = makeResult(status: PaymentStatus.failed);
      final map = original.toMap();
      final restored = PaymentResult.fromMap(map);

      expect(restored, equals(original));
      expect(restored.orderId, isNull);
    });

    // ── PaymentStatus serialization ───────────────────────────────────────────

    test('status is serialized as string name in toMap', () {
      final result = makeResult(status: PaymentStatus.processing);
      final map = result.toMap();

      expect(map['status'], equals('processing'));
    });

    test('fromMap parses all PaymentStatus values correctly', () {
      for (final status in PaymentStatus.values) {
        final map = {
          'transactionId': 'txn_status',
          'status': status.name,
          'orderId': null,
        };

        final result = PaymentResult.fromMap(map);
        expect(result.status, equals(status));
      }
    });

    // ── copyWith ──────────────────────────────────────────────────────────────

    test('copyWith updates status while preserving other fields', () {
      final original = makeResult(status: PaymentStatus.pending);
      final updated = original.copyWith(status: PaymentStatus.success);

      expect(updated.status, equals(PaymentStatus.success));
      expect(updated.transactionId, equals(original.transactionId));
      expect(updated.orderId, equals(original.orderId));
    });

    test('copyWith can set orderId on success', () {
      final original = makeResult(status: PaymentStatus.pending);
      final updated = original.copyWith(
        status: PaymentStatus.success,
        orderId: 'order_456',
      );

      expect(updated.status, equals(PaymentStatus.success));
      expect(updated.orderId, equals('order_456'));
    });

    test('copyWith can clear orderId back to null', () {
      final original = makeResult(
        status: PaymentStatus.success,
        orderId: 'order_789',
      );
      final updated = original.copyWith(orderId: null);

      expect(updated.orderId, isNull);
    });

    // ── Equality ──────────────────────────────────────────────────────────────

    test('two PaymentResults with same data are equal', () {
      final a = makeResult(status: PaymentStatus.success, orderId: 'order_1');
      final b = makeResult(status: PaymentStatus.success, orderId: 'order_1');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('PaymentResults with different status are not equal', () {
      final pending = makeResult(status: PaymentStatus.pending);
      final failed = makeResult(status: PaymentStatus.failed);

      expect(pending, isNot(equals(failed)));
    });

    test('PaymentResults with different orderId are not equal', () {
      final a = makeResult(status: PaymentStatus.success, orderId: 'order_a');
      final b = makeResult(status: PaymentStatus.success, orderId: 'order_b');

      expect(a, isNot(equals(b)));
    });

    test('PaymentResult with null orderId differs from one with orderId', () {
      final withOrder =
          makeResult(status: PaymentStatus.success, orderId: 'order_x');
      final withoutOrder = makeResult(status: PaymentStatus.success);

      expect(withOrder, isNot(equals(withoutOrder)));
    });

    // ── Nullable orderId handling ─────────────────────────────────────────────

    test('orderId is nullable and defaults to null', () {
      final result = makeResult();
      expect(result.orderId, isNull);
    });

    test('orderId can be set to a value', () {
      final result = makeResult(orderId: 'order_set');
      expect(result.orderId, equals('order_set'));
    });

    test('fromMap handles null orderId', () {
      final map = {
        'transactionId': 'txn_null_order',
        'status': 'pending',
        'orderId': null,
      };

      final result = PaymentResult.fromMap(map);
      expect(result.orderId, isNull);
    });

    test('fromMap handles missing orderId key', () {
      final map = {
        'transactionId': 'txn_missing_order',
        'status': 'cancelled',
      };

      final result = PaymentResult.fromMap(map);
      expect(result.orderId, isNull);
    });
  });
}
