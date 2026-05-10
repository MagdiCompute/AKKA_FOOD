// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_order_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminOrderDetailNotifierHash() =>
    r'0f0021e8b81a432bd74be6f94543ddabf1774e25';

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

abstract class _$AdminOrderDetailNotifier
    extends BuildlessAutoDisposeNotifier<AdminOrderDetailState> {
  late final String orderId;

  AdminOrderDetailState build(String orderId);
}

/// Manages state for [AdminOrderDetailScreen].
///
/// Parameterized by [orderId] (family notifier).
///
/// On build, tries to find the order in the already-loaded
/// [adminOrderNotifierProvider] list to avoid an extra Firestore round-trip.
/// Falls back to fetching directly from the repository when not found.
///
/// Satisfies Requirements 4.2, 4.3, and 4.5.
///
/// Copied from [AdminOrderDetailNotifier].
@ProviderFor(AdminOrderDetailNotifier)
const adminOrderDetailNotifierProvider = AdminOrderDetailNotifierFamily();

/// Manages state for [AdminOrderDetailScreen].
///
/// Parameterized by [orderId] (family notifier).
///
/// On build, tries to find the order in the already-loaded
/// [adminOrderNotifierProvider] list to avoid an extra Firestore round-trip.
/// Falls back to fetching directly from the repository when not found.
///
/// Satisfies Requirements 4.2, 4.3, and 4.5.
///
/// Copied from [AdminOrderDetailNotifier].
class AdminOrderDetailNotifierFamily extends Family<AdminOrderDetailState> {
  /// Manages state for [AdminOrderDetailScreen].
  ///
  /// Parameterized by [orderId] (family notifier).
  ///
  /// On build, tries to find the order in the already-loaded
  /// [adminOrderNotifierProvider] list to avoid an extra Firestore round-trip.
  /// Falls back to fetching directly from the repository when not found.
  ///
  /// Satisfies Requirements 4.2, 4.3, and 4.5.
  ///
  /// Copied from [AdminOrderDetailNotifier].
  const AdminOrderDetailNotifierFamily();

  /// Manages state for [AdminOrderDetailScreen].
  ///
  /// Parameterized by [orderId] (family notifier).
  ///
  /// On build, tries to find the order in the already-loaded
  /// [adminOrderNotifierProvider] list to avoid an extra Firestore round-trip.
  /// Falls back to fetching directly from the repository when not found.
  ///
  /// Satisfies Requirements 4.2, 4.3, and 4.5.
  ///
  /// Copied from [AdminOrderDetailNotifier].
  AdminOrderDetailNotifierProvider call(String orderId) {
    return AdminOrderDetailNotifierProvider(orderId);
  }

  @override
  AdminOrderDetailNotifierProvider getProviderOverride(
    covariant AdminOrderDetailNotifierProvider provider,
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
  String? get name => r'adminOrderDetailNotifierProvider';
}

/// Manages state for [AdminOrderDetailScreen].
///
/// Parameterized by [orderId] (family notifier).
///
/// On build, tries to find the order in the already-loaded
/// [adminOrderNotifierProvider] list to avoid an extra Firestore round-trip.
/// Falls back to fetching directly from the repository when not found.
///
/// Satisfies Requirements 4.2, 4.3, and 4.5.
///
/// Copied from [AdminOrderDetailNotifier].
class AdminOrderDetailNotifierProvider
    extends
        AutoDisposeNotifierProviderImpl<
          AdminOrderDetailNotifier,
          AdminOrderDetailState
        > {
  /// Manages state for [AdminOrderDetailScreen].
  ///
  /// Parameterized by [orderId] (family notifier).
  ///
  /// On build, tries to find the order in the already-loaded
  /// [adminOrderNotifierProvider] list to avoid an extra Firestore round-trip.
  /// Falls back to fetching directly from the repository when not found.
  ///
  /// Satisfies Requirements 4.2, 4.3, and 4.5.
  ///
  /// Copied from [AdminOrderDetailNotifier].
  AdminOrderDetailNotifierProvider(String orderId)
    : this._internal(
        () => AdminOrderDetailNotifier()..orderId = orderId,
        from: adminOrderDetailNotifierProvider,
        name: r'adminOrderDetailNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$adminOrderDetailNotifierHash,
        dependencies: AdminOrderDetailNotifierFamily._dependencies,
        allTransitiveDependencies:
            AdminOrderDetailNotifierFamily._allTransitiveDependencies,
        orderId: orderId,
      );

  AdminOrderDetailNotifierProvider._internal(
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
  AdminOrderDetailState runNotifierBuild(
    covariant AdminOrderDetailNotifier notifier,
  ) {
    return notifier.build(orderId);
  }

  @override
  Override overrideWith(AdminOrderDetailNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AdminOrderDetailNotifierProvider._internal(
        () => create()..orderId = orderId,
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
  AutoDisposeNotifierProviderElement<
    AdminOrderDetailNotifier,
    AdminOrderDetailState
  >
  createElement() {
    return _AdminOrderDetailNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminOrderDetailNotifierProvider &&
        other.orderId == orderId;
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
mixin AdminOrderDetailNotifierRef
    on AutoDisposeNotifierProviderRef<AdminOrderDetailState> {
  /// The parameter `orderId` of this provider.
  String get orderId;
}

class _AdminOrderDetailNotifierProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          AdminOrderDetailNotifier,
          AdminOrderDetailState
        >
    with AdminOrderDetailNotifierRef {
  _AdminOrderDetailNotifierProviderElement(super.provider);

  @override
  String get orderId => (origin as AdminOrderDetailNotifierProvider).orderId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
