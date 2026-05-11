import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliveryStatus enum', () {
    test('has exactly 6 values', () {
      expect(DeliveryStatus.values.length, equals(6));
    });

    test('values are in expected order', () {
      expect(DeliveryStatus.values, [
        DeliveryStatus.pending,
        DeliveryStatus.confirmed,
        DeliveryStatus.preparing,
        DeliveryStatus.outForDelivery,
        DeliveryStatus.delivered,
        DeliveryStatus.failed,
      ]);
    });
  });

  group('DeliveryStatus.fromString', () {
    test('parses "pending"', () {
      expect(DeliveryStatus.fromString('pending'), DeliveryStatus.pending);
    });

    test('parses "confirmed"', () {
      expect(DeliveryStatus.fromString('confirmed'), DeliveryStatus.confirmed);
    });

    test('parses "preparing"', () {
      expect(DeliveryStatus.fromString('preparing'), DeliveryStatus.preparing);
    });

    test('parses "out_for_delivery"', () {
      expect(
        DeliveryStatus.fromString('out_for_delivery'),
        DeliveryStatus.outForDelivery,
      );
    });

    test('parses "delivered"', () {
      expect(DeliveryStatus.fromString('delivered'), DeliveryStatus.delivered);
    });

    test('parses "failed"', () {
      expect(DeliveryStatus.fromString('failed'), DeliveryStatus.failed);
    });

    test('defaults to pending for null', () {
      expect(DeliveryStatus.fromString(null), DeliveryStatus.pending);
    });

    test('defaults to pending for unknown string', () {
      expect(DeliveryStatus.fromString('unknown'), DeliveryStatus.pending);
    });
  });

  group('DeliveryStatus.toFirestoreString', () {
    test('pending → "pending"', () {
      expect(DeliveryStatus.pending.toFirestoreString(), 'pending');
    });

    test('confirmed → "confirmed"', () {
      expect(DeliveryStatus.confirmed.toFirestoreString(), 'confirmed');
    });

    test('preparing → "preparing"', () {
      expect(DeliveryStatus.preparing.toFirestoreString(), 'preparing');
    });

    test('outForDelivery → "out_for_delivery"', () {
      expect(
        DeliveryStatus.outForDelivery.toFirestoreString(),
        'out_for_delivery',
      );
    });

    test('delivered → "delivered"', () {
      expect(DeliveryStatus.delivered.toFirestoreString(), 'delivered');
    });

    test('failed → "failed"', () {
      expect(DeliveryStatus.failed.toFirestoreString(), 'failed');
    });

    test('roundtrip: fromString(toFirestoreString()) returns same value', () {
      for (final status in DeliveryStatus.values) {
        expect(
          DeliveryStatus.fromString(status.toFirestoreString()),
          equals(status),
          reason: '$status should survive a roundtrip conversion',
        );
      }
    });
  });

  group('DeliveryStatus.label', () {
    test('pending label is "Pending"', () {
      expect(DeliveryStatus.pending.label, 'Pending');
    });

    test('confirmed label is "Confirmed"', () {
      expect(DeliveryStatus.confirmed.label, 'Confirmed');
    });

    test('preparing label is "Preparing"', () {
      expect(DeliveryStatus.preparing.label, 'Preparing');
    });

    test('outForDelivery label is "Out for Delivery"', () {
      expect(DeliveryStatus.outForDelivery.label, 'Out for Delivery');
    });

    test('delivered label is "Delivered"', () {
      expect(DeliveryStatus.delivered.label, 'Delivered');
    });

    test('failed label is "Failed"', () {
      expect(DeliveryStatus.failed.label, 'Failed');
    });
  });

  group('DeliveryStatus.isActive', () {
    test('pending is active', () {
      expect(DeliveryStatus.pending.isActive, isTrue);
    });

    test('confirmed is active', () {
      expect(DeliveryStatus.confirmed.isActive, isTrue);
    });

    test('preparing is active', () {
      expect(DeliveryStatus.preparing.isActive, isTrue);
    });

    test('outForDelivery is active', () {
      expect(DeliveryStatus.outForDelivery.isActive, isTrue);
    });

    test('delivered is NOT active (terminal)', () {
      expect(DeliveryStatus.delivered.isActive, isFalse);
    });

    test('failed is NOT active (terminal)', () {
      expect(DeliveryStatus.failed.isActive, isFalse);
    });
  });

  group('Status transition validation', () {
    group('valid transitions are allowed', () {
      test('pending → confirmed', () {
        expect(
          isValidTransition(DeliveryStatus.pending, DeliveryStatus.confirmed),
          isTrue,
        );
      });

      test('confirmed → preparing', () {
        expect(
          isValidTransition(DeliveryStatus.confirmed, DeliveryStatus.preparing),
          isTrue,
        );
      });

      test('preparing → outForDelivery', () {
        expect(
          isValidTransition(
            DeliveryStatus.preparing,
            DeliveryStatus.outForDelivery,
          ),
          isTrue,
        );
      });

      test('outForDelivery → delivered', () {
        expect(
          isValidTransition(
            DeliveryStatus.outForDelivery,
            DeliveryStatus.delivered,
          ),
          isTrue,
        );
      });

      test('outForDelivery → failed', () {
        expect(
          isValidTransition(
            DeliveryStatus.outForDelivery,
            DeliveryStatus.failed,
          ),
          isTrue,
        );
      });
    });

    group('invalid transitions are rejected', () {
      test('pending → delivered (skip to terminal)', () {
        expect(
          isValidTransition(DeliveryStatus.pending, DeliveryStatus.delivered),
          isFalse,
        );
      });

      test('delivered → pending (backward from terminal)', () {
        expect(
          isValidTransition(DeliveryStatus.delivered, DeliveryStatus.pending),
          isFalse,
        );
      });

      test('failed → confirmed (backward from terminal)', () {
        expect(
          isValidTransition(DeliveryStatus.failed, DeliveryStatus.confirmed),
          isFalse,
        );
      });

      test('pending → preparing (skipping confirmed)', () {
        expect(
          isValidTransition(DeliveryStatus.pending, DeliveryStatus.preparing),
          isFalse,
        );
      });

      test('confirmed → outForDelivery (skipping preparing)', () {
        expect(
          isValidTransition(
            DeliveryStatus.confirmed,
            DeliveryStatus.outForDelivery,
          ),
          isFalse,
        );
      });

      test('preparing → delivered (skipping outForDelivery)', () {
        expect(
          isValidTransition(
            DeliveryStatus.preparing,
            DeliveryStatus.delivered,
          ),
          isFalse,
        );
      });
    });

    group('terminal states have no valid outgoing transitions', () {
      test('delivered has no valid transitions', () {
        for (final target in DeliveryStatus.values) {
          expect(
            isValidTransition(DeliveryStatus.delivered, target),
            isFalse,
            reason: 'delivered → $target should be invalid',
          );
        }
      });

      test('failed has no valid transitions', () {
        for (final target in DeliveryStatus.values) {
          expect(
            isValidTransition(DeliveryStatus.failed, target),
            isFalse,
            reason: 'failed → $target should be invalid',
          );
        }
      });
    });
  });
}
