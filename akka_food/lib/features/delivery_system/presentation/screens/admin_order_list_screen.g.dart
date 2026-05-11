// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_order_list_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeOrdersHash() => r'04a5ad7ce641ab1d7b14521717832229ebaa8e9e';

/// Provides a real-time stream of active (non-terminal) delivery orders.
///
/// Uses [IDeliveryRepository.getActiveOrders()] which returns orders whose
/// status is not `delivered` or `failed`, sorted by `createdAt` ascending.
///
/// Satisfies Requirement 4 AC2.
///
/// Copied from [activeOrders].
@ProviderFor(activeOrders)
final activeOrdersProvider = AutoDisposeStreamProvider<List<Order>>.internal(
  activeOrders,
  name: r'activeOrdersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeOrdersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveOrdersRef = AutoDisposeStreamProviderRef<List<Order>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
