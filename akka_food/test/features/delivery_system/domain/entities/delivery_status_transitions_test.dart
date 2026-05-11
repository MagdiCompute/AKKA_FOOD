import 'package:akka_food/features/delivery_system/domain/entities/delivery_status.dart';
import 'package:akka_food/features/delivery_system/domain/entities/delivery_status_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validStatusTransitions', () {
    test('contains an entry for every DeliveryStatus value', () {
      for (final status in DeliveryStatus.values) {
        expect(
          validStatusTransitions.containsKey(status),
          isTrue,
          reason: '$status should have an entry in the transition map',
        );
      }
    });

    test('pending can only transition to confirmed', () {
      expect(
        validStatusTransitions[DeliveryStatus.pending],
        equals([DeliveryStatus.confirmed]),
      );
    });

    test('confirmed can only transition to preparing', () {
      expect(
        validStatusTransitions[DeliveryStatus.confirmed],
        equals([DeliveryStatus.preparing]),
      );
    });

    test('preparing can only transition to outForDelivery', () {
      expect(
        validStatusTransitions[DeliveryStatus.preparing],
        equals([DeliveryStatus.outForDelivery]),
      );
    });

    test('outForDelivery can transition to delivered or failed', () {
      expect(
        validStatusTransitions[DeliveryStatus.outForDelivery],
        containsAll([DeliveryStatus.delivered, DeliveryStatus.failed]),
      );
    });

    test('delivered is terminal (no transitions)', () {
      expect(validStatusTransitions[DeliveryStatus.delivered], isEmpty);
    });

    test('failed is terminal (no transitions)', () {
      expect(validStatusTransitions[DeliveryStatus.failed], isEmpty);
    });
  });

  group('isValidTransition', () {
    test('allows pending → confirmed', () {
      expect(isValidTransition(DeliveryStatus.pending, DeliveryStatus.confirmed), isTrue);
    });

    test('allows confirmed → preparing', () {
      expect(isValidTransition(DeliveryStatus.confirmed, DeliveryStatus.preparing), isTrue);
    });

    test('allows preparing → outForDelivery', () {
      expect(isValidTransition(DeliveryStatus.preparing, DeliveryStatus.outForDelivery), isTrue);
    });

    test('allows outForDelivery → delivered', () {
      expect(isValidTransition(DeliveryStatus.outForDelivery, DeliveryStatus.delivered), isTrue);
    });

    test('allows outForDelivery → failed', () {
      expect(isValidTransition(DeliveryStatus.outForDelivery, DeliveryStatus.failed), isTrue);
    });

    test('rejects pending → preparing (skipping confirmed)', () {
      expect(isValidTransition(DeliveryStatus.pending, DeliveryStatus.preparing), isFalse);
    });

    test('rejects delivered → pending (backward from terminal)', () {
      expect(isValidTransition(DeliveryStatus.delivered, DeliveryStatus.pending), isFalse);
    });

    test('rejects failed → pending (backward from terminal)', () {
      expect(isValidTransition(DeliveryStatus.failed, DeliveryStatus.pending), isFalse);
    });

    test('rejects same-status transition (pending → pending)', () {
      expect(isValidTransition(DeliveryStatus.pending, DeliveryStatus.pending), isFalse);
    });

    test('rejects backward transition (confirmed → pending)', () {
      expect(isValidTransition(DeliveryStatus.confirmed, DeliveryStatus.pending), isFalse);
    });

    test('rejects outForDelivery → preparing (backward)', () {
      expect(isValidTransition(DeliveryStatus.outForDelivery, DeliveryStatus.preparing), isFalse);
    });
  });
}
