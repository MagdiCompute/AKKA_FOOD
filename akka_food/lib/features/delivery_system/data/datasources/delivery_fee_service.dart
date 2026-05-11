import 'package:akka_food/features/cart/data/datasources/remote_config_service.dart';
import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delivery_fee_service.g.dart';

// ---------------------------------------------------------------------------
// DeliveryFeeService
// ---------------------------------------------------------------------------

/// Service responsible for determining the delivery fee based on the
/// user's selected delivery option and Firebase Remote Config.
///
/// Business rules:
/// - When delivery option is [DeliveryOption.pickup], the fee is always 0.
/// - When delivery option is [DeliveryOption.delivery], the fee is fetched
///   from Firebase Remote Config (`delivery_fee_xof` parameter).
/// - Falls back to [kDefaultDeliveryFeeXof] (500 XOF) when Remote Config
///   is unavailable.
///
/// Satisfies Requirement 5 (Delivery Fee):
/// - 5.1: Display delivery fee clearly before payment
/// - 5.2: Fee fetched from Firebase Remote Config
/// - 5.3: Pickup displays 0 XOF
class DeliveryFeeService {
  const DeliveryFeeService(this._remoteConfigService);

  final RemoteConfigService _remoteConfigService;

  /// Returns the delivery fee in XOF for the given [deliveryOption].
  ///
  /// - [DeliveryOption.pickup] → 0.0 XOF (Req 5.3)
  /// - [DeliveryOption.delivery] → value from Remote Config (Req 5.2)
  double getDeliveryFee(DeliveryOption deliveryOption) {
    if (deliveryOption == DeliveryOption.pickup) {
      return 0.0;
    }
    return _remoteConfigService.deliveryFeeXof;
  }

  /// Returns the raw delivery fee from Remote Config, regardless of
  /// delivery option. Useful for displaying "Delivery fee: X XOF" in UI
  /// even when pickup is selected (to show what the user would pay).
  double get rawDeliveryFee => _remoteConfigService.deliveryFeeXof;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provides the [DeliveryFeeService] instance.
///
/// Depends on [remoteConfigServiceProvider] — waits for Remote Config
/// initialization before creating the service.
@riverpod
Future<DeliveryFeeService> deliveryFeeService(Ref ref) async {
  final remoteConfigService = await ref.watch(remoteConfigServiceProvider.future);
  return DeliveryFeeService(remoteConfigService);
}

/// Provides the current delivery fee in XOF based on the user's selected
/// delivery option in the cart.
///
/// - Returns 0.0 when pickup is selected (Req 5.3)
/// - Returns the Remote Config value when delivery is selected (Req 5.2)
/// - Falls back to [kDefaultDeliveryFeeXof] during loading or on error
///
/// Usage:
/// ```dart
/// final fee = ref.watch(currentDeliveryFeeProvider);
/// ```
@riverpod
double currentDeliveryFee(Ref ref) {
  final cart = ref.watch(cartNotifierProvider);
  final asyncService = ref.watch(deliveryFeeServiceProvider);

  return asyncService.when(
    data: (service) => service.getDeliveryFee(cart.deliveryOption),
    loading: () => cart.deliveryOption == DeliveryOption.pickup
        ? 0.0
        : kDefaultDeliveryFeeXof,
    error: (_, __) => cart.deliveryOption == DeliveryOption.pickup
        ? 0.0
        : kDefaultDeliveryFeeXof,
  );
}
