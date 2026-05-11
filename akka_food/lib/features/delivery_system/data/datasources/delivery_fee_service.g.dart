// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_fee_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deliveryFeeServiceHash() =>
    r'e5f908322803221b8842215aa4198dac38642996';

/// Provides the [DeliveryFeeService] instance.
///
/// Depends on [remoteConfigServiceProvider] — waits for Remote Config
/// initialization before creating the service.
///
/// Copied from [deliveryFeeService].
@ProviderFor(deliveryFeeService)
final deliveryFeeServiceProvider =
    AutoDisposeFutureProvider<DeliveryFeeService>.internal(
      deliveryFeeService,
      name: r'deliveryFeeServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$deliveryFeeServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeliveryFeeServiceRef =
    AutoDisposeFutureProviderRef<DeliveryFeeService>;
String _$currentDeliveryFeeHash() =>
    r'cb2fb18df543bbc0aed03c2874d0eed623a9f536';

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
///
/// Copied from [currentDeliveryFee].
@ProviderFor(currentDeliveryFee)
final currentDeliveryFeeProvider = AutoDisposeProvider<double>.internal(
  currentDeliveryFee,
  name: r'currentDeliveryFeeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentDeliveryFeeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentDeliveryFeeRef = AutoDisposeProviderRef<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
