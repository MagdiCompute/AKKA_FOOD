import 'package:akka_food/features/cart/data/datasources/remote_config_service.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/delivery_system/data/datasources/delivery_fee_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DeliveryFeeService', () {
    group('getDeliveryFee', () {
      test('returns 0 when delivery option is pickup (Req 5.3)', () {
        final service = DeliveryFeeService(
          FakeRemoteConfigService(feeXof: 500.0),
        );

        final fee = service.getDeliveryFee(DeliveryOption.pickup);
        expect(fee, 0.0);
      });

      test('returns Remote Config value when delivery option is delivery (Req 5.2)', () {
        final service = DeliveryFeeService(
          FakeRemoteConfigService(feeXof: 500.0),
        );

        final fee = service.getDeliveryFee(DeliveryOption.delivery);
        expect(fee, 500.0);
      });

      test('returns custom Remote Config value when configured', () {
        final service = DeliveryFeeService(
          FakeRemoteConfigService(feeXof: 750.0),
        );

        final fee = service.getDeliveryFee(DeliveryOption.delivery);
        expect(fee, 750.0);
      });

      test('returns 0 for pickup regardless of Remote Config value', () {
        final service = DeliveryFeeService(
          FakeRemoteConfigService(feeXof: 1000.0),
        );

        final fee = service.getDeliveryFee(DeliveryOption.pickup);
        expect(fee, 0.0);
      });
    });

    group('rawDeliveryFee', () {
      test('returns the Remote Config value directly', () {
        final service = DeliveryFeeService(
          FakeRemoteConfigService(feeXof: 500.0),
        );

        expect(service.rawDeliveryFee, 500.0);
      });

      test('returns custom value when configured', () {
        final service = DeliveryFeeService(
          FakeRemoteConfigService(feeXof: 300.0),
        );

        expect(service.rawDeliveryFee, 300.0);
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A fake [RemoteConfigService] that bypasses Firebase initialization
/// and returns a configurable delivery fee.
class FakeRemoteConfigService extends Fake implements RemoteConfigService {
  FakeRemoteConfigService({this.feeXof = kDefaultDeliveryFeeXof});

  final double feeXof;

  @override
  double get deliveryFeeXof => feeXof > 0 ? feeXof : kDefaultDeliveryFeeXof;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> fetchAndActivate() async => true;
}
