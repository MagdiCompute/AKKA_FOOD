// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderDetailHash() => r'4f7c54d0119c02f59d2b559080018d21ec30cd1f';

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

/// Fetches the full [OrderSummary] for [orderId] from the repository.
///
/// Uses `.family` so each orderId gets its own cached provider instance.
/// Always fetches from Firestore — individual orders are not cached
/// (see [OrderRepository.getOrderDetail]).
///
/// Satisfies Requirement 5.3.
///
/// Copied from [orderDetail].
@ProviderFor(orderDetail)
const orderDetailProvider = OrderDetailFamily();

/// Fetches the full [OrderSummary] for [orderId] from the repository.
///
/// Uses `.family` so each orderId gets its own cached provider instance.
/// Always fetches from Firestore — individual orders are not cached
/// (see [OrderRepository.getOrderDetail]).
///
/// Satisfies Requirement 5.3.
///
/// Copied from [orderDetail].
class OrderDetailFamily extends Family<AsyncValue<OrderSummary>> {
  /// Fetches the full [OrderSummary] for [orderId] from the repository.
  ///
  /// Uses `.family` so each orderId gets its own cached provider instance.
  /// Always fetches from Firestore — individual orders are not cached
  /// (see [OrderRepository.getOrderDetail]).
  ///
  /// Satisfies Requirement 5.3.
  ///
  /// Copied from [orderDetail].
  const OrderDetailFamily();

  /// Fetches the full [OrderSummary] for [orderId] from the repository.
  ///
  /// Uses `.family` so each orderId gets its own cached provider instance.
  /// Always fetches from Firestore — individual orders are not cached
  /// (see [OrderRepository.getOrderDetail]).
  ///
  /// Satisfies Requirement 5.3.
  ///
  /// Copied from [orderDetail].
  OrderDetailProvider call(String orderId) {
    return OrderDetailProvider(orderId);
  }

  @override
  OrderDetailProvider getProviderOverride(
    covariant OrderDetailProvider provider,
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
  String? get name => r'orderDetailProvider';
}

/// Fetches the full [OrderSummary] for [orderId] from the repository.
///
/// Uses `.family` so each orderId gets its own cached provider instance.
/// Always fetches from Firestore — individual orders are not cached
/// (see [OrderRepository.getOrderDetail]).
///
/// Satisfies Requirement 5.3.
///
/// Copied from [orderDetail].
class OrderDetailProvider extends AutoDisposeFutureProvider<OrderSummary> {
  /// Fetches the full [OrderSummary] for [orderId] from the repository.
  ///
  /// Uses `.family` so each orderId gets its own cached provider instance.
  /// Always fetches from Firestore — individual orders are not cached
  /// (see [OrderRepository.getOrderDetail]).
  ///
  /// Satisfies Requirement 5.3.
  ///
  /// Copied from [orderDetail].
  OrderDetailProvider(String orderId)
    : this._internal(
        (ref) => orderDetail(ref as OrderDetailRef, orderId),
        from: orderDetailProvider,
        name: r'orderDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$orderDetailHash,
        dependencies: OrderDetailFamily._dependencies,
        allTransitiveDependencies: OrderDetailFamily._allTransitiveDependencies,
        orderId: orderId,
      );

  OrderDetailProvider._internal(
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
    FutureOr<OrderSummary> Function(OrderDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OrderDetailProvider._internal(
        (ref) => create(ref as OrderDetailRef),
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
  AutoDisposeFutureProviderElement<OrderSummary> createElement() {
    return _OrderDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderDetailProvider && other.orderId == orderId;
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
mixin OrderDetailRef on AutoDisposeFutureProviderRef<OrderSummary> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _OrderDetailProviderElement
    extends AutoDisposeFutureProviderElement<OrderSummary>
    with OrderDetailRef {
  _OrderDetailProviderElement(super.provider);

  @override
  String get orderId => (origin as OrderDetailProvider).orderId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
