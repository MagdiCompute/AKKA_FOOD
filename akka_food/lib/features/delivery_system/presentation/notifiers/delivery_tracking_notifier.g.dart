// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_tracking_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deliveryRepositoryHash() =>
    r'0d40851a3b0a8b575505a60a0fa67f3622825acc';

/// Provides the [IDeliveryRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
///
/// Copied from [deliveryRepository].
@ProviderFor(deliveryRepository)
final deliveryRepositoryProvider =
    AutoDisposeProvider<IDeliveryRepository>.internal(
      deliveryRepository,
      name: r'deliveryRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$deliveryRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeliveryRepositoryRef = AutoDisposeProviderRef<IDeliveryRepository>;
String _$trackingUpdatesHash() => r'79e6e0e7c73bffbaf9b088ced1ea3cc936faf65d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provides a real-time stream of [TrackingUpdate]s for the given [orderId].
///
/// Returns an empty list while loading or if no updates exist yet.
/// Uses [IDeliveryRepository.watchTrackingUpdates] under the hood.
///
/// Satisfies Requirement 2 AC3 (timeline data).
///
/// Copied from [trackingUpdates].
@ProviderFor(trackingUpdates)
const trackingUpdatesProvider = TrackingUpdatesFamily();

/// Provides a real-time stream of [TrackingUpdate]s for the given [orderId].
///
/// Returns an empty list while loading or if no updates exist yet.
/// Uses [IDeliveryRepository.watchTrackingUpdates] under the hood.
///
/// Satisfies Requirement 2 AC3 (timeline data).
///
/// Copied from [trackingUpdates].
class TrackingUpdatesFamily extends Family<AsyncValue<List<TrackingUpdate>>> {
  /// Provides a real-time stream of [TrackingUpdate]s for the given [orderId].
  ///
  /// Returns an empty list while loading or if no updates exist yet.
  /// Uses [IDeliveryRepository.watchTrackingUpdates] under the hood.
  ///
  /// Satisfies Requirement 2 AC3 (timeline data).
  ///
  /// Copied from [trackingUpdates].
  const TrackingUpdatesFamily();

  /// Provides a real-time stream of [TrackingUpdate]s for the given [orderId].
  ///
  /// Returns an empty list while loading or if no updates exist yet.
  /// Uses [IDeliveryRepository.watchTrackingUpdates] under the hood.
  ///
  /// Satisfies Requirement 2 AC3 (timeline data).
  ///
  /// Copied from [trackingUpdates].
  TrackingUpdatesProvider call(String orderId) {
    return TrackingUpdatesProvider(orderId);
  }

  @override
  TrackingUpdatesProvider getProviderOverride(
    covariant TrackingUpdatesProvider provider,
  ) {
    return call(provider.orderId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'trackingUpdatesProvider';
}

/// Provides a real-time stream of [TrackingUpdate]s for the given [orderId].
///
/// Returns an empty list while loading or if no updates exist yet.
/// Uses [IDeliveryRepository.watchTrackingUpdates] under the hood.
///
/// Satisfies Requirement 2 AC3 (timeline data).
///
/// Copied from [trackingUpdates].
class TrackingUpdatesProvider
    extends AutoDisposeStreamProvider<List<TrackingUpdate>> {
  /// Provides a real-time stream of [TrackingUpdate]s for the given [orderId].
  ///
  /// Returns an empty list while loading or if no updates exist yet.
  /// Uses [IDeliveryRepository.watchTrackingUpdates] under the hood.
  ///
  /// Satisfies Requirement 2 AC3 (timeline data).
  ///
  /// Copied from [trackingUpdates].
  TrackingUpdatesProvider(String orderId)
    : this._internal(
        (ref) => trackingUpdates(ref as TrackingUpdatesRef, orderId),
        from: trackingUpdatesProvider,
        name: r'trackingUpdatesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$trackingUpdatesHash,
        dependencies: TrackingUpdatesFamily._dependencies,
        allTransitiveDependencies:
            TrackingUpdatesFamily._allTransitiveDependencies,
        orderId: orderId,
      );

  TrackingUpdatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.orderId,
  }) : super.internal();

  final String orderId;

  @override
  Override overrideWith(
    Stream<List<TrackingUpdate>> Function(TrackingUpdatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TrackingUpdatesProvider._internal(
        (ref) => create(ref as TrackingUpdatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        orderId: orderId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<TrackingUpdate>> createElement() {
    return _TrackingUpdatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TrackingUpdatesProvider && other.orderId == orderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, orderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TrackingUpdatesRef on AutoDisposeStreamProviderRef<List<TrackingUpdate>> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _TrackingUpdatesProviderElement
    extends AutoDisposeStreamProviderElement<List<TrackingUpdate>>
    with TrackingUpdatesRef {
  _TrackingUpdatesProviderElement(super.provider);

  @override
  String get orderId => (origin as TrackingUpdatesProvider).orderId;
}

String _$deliveryTrackingNotifierHash() =>
    r'e7d7be47cd0b93a21c7830775424e9b294598018';

/// Manages real-time delivery tracking state for a single order.
///
/// Subscribes to the [IDeliveryRepository.watchOrder] stream and updates
/// the notifier state ([AsyncData], [AsyncLoading], [AsyncError]) based on
/// stream events.
///
/// Usage:
/// ```dart
/// final notifier = ref.read(deliveryTrackingNotifierProvider.notifier);
/// notifier.watchOrder('order_123');
/// ```
///
/// Satisfies Requirement 2 AC1, AC2.
///
/// Copied from [DeliveryTrackingNotifier].
@ProviderFor(DeliveryTrackingNotifier)
final deliveryTrackingNotifierProvider =
    AutoDisposeAsyncNotifierProvider<DeliveryTrackingNotifier, Order?>.internal(
      DeliveryTrackingNotifier.new,
      name: r'deliveryTrackingNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$deliveryTrackingNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DeliveryTrackingNotifier = AutoDisposeAsyncNotifier<Order?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
