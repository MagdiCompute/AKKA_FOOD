// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_order_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminOrderRepositoryHash() =>
    r'18897feac6d6e672a75ed06d568a3f74a05ee430';

/// Provides the [IAdminOrderRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
///
/// Copied from [adminOrderRepository].
@ProviderFor(adminOrderRepository)
final adminOrderRepositoryProvider =
    AutoDisposeProvider<IAdminOrderRepository>.internal(
      adminOrderRepository,
      name: r'adminOrderRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminOrderRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminOrderRepositoryRef = AutoDisposeProviderRef<IAdminOrderRepository>;
String _$adminOrderNotifierHash() =>
    r'39dff76b9da07620e6b20e013db90159ec929dec';

/// Manages the state for [AdminOrderListScreen].
///
/// Listens to the real-time Firestore stream of active orders and exposes
/// filter controls for status, date range, and delivery option.
///
/// Satisfies Requirements 4.1 and 4.4.
///
/// Copied from [AdminOrderNotifier].
@ProviderFor(AdminOrderNotifier)
final adminOrderNotifierProvider =
    AutoDisposeNotifierProvider<
      AdminOrderNotifier,
      AsyncValue<AdminOrderState>
    >.internal(
      AdminOrderNotifier.new,
      name: r'adminOrderNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminOrderNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AdminOrderNotifier = AutoDisposeNotifier<AsyncValue<AdminOrderState>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
