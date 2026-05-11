import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/payment_processing/domain/entities/payment_status.dart';
import 'package:akka_food/features/payment_processing/domain/entities/transaction.dart';

void main() {
  group('Transaction', () {
    final baseCreatedAt = DateTime(2024, 6, 15, 10, 30);
    final baseUpdatedAt = DateTime(2024, 6, 15, 10, 35);

    Transaction makeTransaction({
      PaymentStatus status = PaymentStatus.pending,
      String? orderId,
    }) =>
        Transaction(
          id: 'txn_001',
          reference: '550e8400-e29b-41d4-a716-446655440000',
          uid: 'user_123',
          amount: 2500.0,
          status: status,
          orderId: orderId,
          createdAt: baseCreatedAt,
          updatedAt: baseUpdatedAt,
        );

    // ── fromMap / toMap round-trip ─────────────────────────────────────────

    test('fromMap creates a Transaction from a valid map', () {
      final map = {
        'id': 'txn_001',
        'reference': '550e8400-e29b-41d4-a716-446655440000',
        'uid': 'user_123',
        'amount': 2500.0,
        'status': 'pending',
        'orderId': null,
        'createdAt': '2024-06-15T10:30:00.000',
        'updatedAt': '2024-06-15T10:35:00.000',
      };

      final transaction = Transaction.fromMap(map);

      expect(transaction.id, equals('txn_001'));
      expect(transaction.reference,
          equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(transaction.uid, equals('user_123'));
      expect(transaction.amount, equals(2500.0));
      expect(transaction.status, equals(PaymentStatus.pending));
      expect(transaction.orderId, isNull);
      expect(transaction.createdAt, equals(baseCreatedAt));
      expect(transaction.updatedAt, equals(baseUpdatedAt));
    });

    test('toMap → fromMap round-trip preserves all fields', () {
      final original = makeTransaction(
        status: PaymentStatus.success,
        orderId: 'order_abc',
      );
      final map = original.toMap();
      final restored = Transaction.fromMap(map);

      expect(restored, equals(original));
    });

    test('fromMap handles DateTime objects directly', () {
      final map = {
        'id': 'txn_002',
        'reference': 'ref-uuid',
        'uid': 'user_456',
        'amount': 1000.0,
        'status': 'processing',
        'orderId': null,
        'createdAt': DateTime(2024, 1, 1),
        'updatedAt': DateTime(2024, 1, 2),
      };

      final transaction = Transaction.fromMap(map);

      expect(transaction.createdAt, equals(DateTime(2024, 1, 1)));
      expect(transaction.updatedAt, equals(DateTime(2024, 1, 2)));
    });

    test('fromMap handles null timestamps by defaulting to DateTime.now()', () {
      final map = {
        'id': 'txn_003',
        'reference': 'ref-uuid-2',
        'uid': 'user_789',
        'amount': 500.0,
        'status': 'failed',
        'orderId': null,
        'createdAt': null,
        'updatedAt': null,
      };

      final before = DateTime.now();
      final transaction = Transaction.fromMap(map);
      final after = DateTime.now();

      // Should default to approximately now
      expect(transaction.createdAt.isAfter(before.subtract(
        const Duration(seconds: 1),
      )), isTrue);
      expect(transaction.updatedAt.isBefore(after.add(
        const Duration(seconds: 1),
      )), isTrue);
    });

    test('fromMap handles Firestore Timestamp-like objects via duck-typing',
        () {
      final fakeTimestamp = _FakeTimestamp(DateTime(2024, 3, 20, 14, 0));

      final map = {
        'id': 'txn_004',
        'reference': 'ref-uuid-3',
        'uid': 'user_abc',
        'amount': 3000.0,
        'status': 'success',
        'orderId': 'order_xyz',
        'createdAt': fakeTimestamp,
        'updatedAt': fakeTimestamp,
      };

      final transaction = Transaction.fromMap(map);

      expect(transaction.createdAt, equals(DateTime(2024, 3, 20, 14, 0)));
      expect(transaction.updatedAt, equals(DateTime(2024, 3, 20, 14, 0)));
    });

    // ── PaymentStatus serialization ─────────────────────────────────────────

    test('status is serialized as string name in toMap', () {
      final transaction = makeTransaction(status: PaymentStatus.success);
      final map = transaction.toMap();

      expect(map['status'], equals('success'));
    });

    test('fromMap parses all PaymentStatus values correctly', () {
      for (final status in PaymentStatus.values) {
        final map = {
          'id': 'txn_status',
          'reference': 'ref',
          'uid': 'uid',
          'amount': 100.0,
          'status': status.name,
          'orderId': null,
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        };

        final transaction = Transaction.fromMap(map);
        expect(transaction.status, equals(status));
      }
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    test('copyWith updates status while preserving other fields', () {
      final original = makeTransaction(status: PaymentStatus.pending);
      final updated = original.copyWith(status: PaymentStatus.success);

      expect(updated.status, equals(PaymentStatus.success));
      expect(updated.id, equals(original.id));
      expect(updated.reference, equals(original.reference));
      expect(updated.amount, equals(original.amount));
    });

    test('copyWith can set orderId on success', () {
      final original = makeTransaction();
      final updated = original.copyWith(
        status: PaymentStatus.success,
        orderId: 'order_123',
      );

      expect(updated.orderId, equals('order_123'));
      expect(updated.status, equals(PaymentStatus.success));
    });

    // ── equality ─────────────────────────────────────────────────────────────

    test('two transactions with same data are equal', () {
      final a = makeTransaction();
      final b = makeTransaction();

      expect(a, equals(b));
    });

    test('transactions with different status are not equal', () {
      final pending = makeTransaction(status: PaymentStatus.pending);
      final success = makeTransaction(status: PaymentStatus.success);

      expect(pending, isNot(equals(success)));
    });

    // ── orderId nullable ─────────────────────────────────────────────────────

    test('orderId is nullable and defaults to null', () {
      final transaction = makeTransaction();
      expect(transaction.orderId, isNull);
    });

    test('orderId can be set to a value', () {
      final transaction = makeTransaction(orderId: 'order_456');
      expect(transaction.orderId, equals('order_456'));
    });
  });

  group('PaymentStatus', () {
    test('fromString parses valid status names', () {
      expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
      expect(PaymentStatus.fromString('processing'), PaymentStatus.processing);
      expect(PaymentStatus.fromString('success'), PaymentStatus.success);
      expect(PaymentStatus.fromString('failed'), PaymentStatus.failed);
      expect(PaymentStatus.fromString('cancelled'), PaymentStatus.cancelled);
      expect(PaymentStatus.fromString('refunded'), PaymentStatus.refunded);
    });

    test('fromString returns pending for null', () {
      expect(PaymentStatus.fromString(null), PaymentStatus.pending);
    });

    test('fromString returns pending for unrecognized value', () {
      expect(PaymentStatus.fromString('unknown'), PaymentStatus.pending);
    });
  });
}

/// Mimics Firestore `Timestamp` with a `.toDate()` method for duck-typing tests.
class _FakeTimestamp {
  final DateTime _dateTime;
  _FakeTimestamp(this._dateTime);

  DateTime toDate() => _dateTime;
}
