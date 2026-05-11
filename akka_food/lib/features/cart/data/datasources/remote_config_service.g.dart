// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_config_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$remoteConfigServiceHash() =>
    r'4bf0f8ab07c7e84d608202b6fe475754aa42fd3f';

/// Provides the singleton [RemoteConfigService] instance.
///
/// The service is initialized lazily on first access. Subsequent reads
/// return the same instance.
///
/// Copied from [remoteConfigService].
@ProviderFor(remoteConfigService)
final remoteConfigServiceProvider =
    AutoDisposeFutureProvider<RemoteConfigService>.internal(
      remoteConfigService,
      name: r'remoteConfigServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$remoteConfigServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RemoteConfigServiceRef =
    AutoDisposeFutureProviderRef<RemoteConfigService>;
String _$deliveryFeeHash() => r'4885202b6117725ba927052976574b4988f69b9c';

/// Provides the current delivery fee in XOF from Firebase Remote Config.
///
/// Returns [kDefaultDeliveryFeeXof] (500) if Remote Config is not yet
/// initialized or if the fetch failed.
///
/// Usage in the Cart entity or notifier:
/// ```dart
/// final fee = ref.watch(deliveryFeeProvider);
/// ```
///
/// Copied from [deliveryFee].
@ProviderFor(deliveryFee)
final deliveryFeeProvider = AutoDisposeProvider<double>.internal(
  deliveryFee,
  name: r'deliveryFeeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deliveryFeeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeliveryFeeRef = AutoDisposeProviderRef<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
