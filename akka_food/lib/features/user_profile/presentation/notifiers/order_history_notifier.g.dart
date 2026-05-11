// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderRepositoryHash() => r'caf9d5acda0ebe4bc66bade23f95f2975e5bfdf3';

/// Provides the concrete [OrderRepository] bound to [IOrderRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreOrderDataSource] — reads from the `/orders` collection
/// - [HiveProfileCache] — local 5-minute TTL cache for the first page of
///   order history
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [orderRepository].
@ProviderFor(orderRepository)
final orderRepositoryProvider =
    AutoDisposeFutureProvider<IOrderRepository>.internal(
      orderRepository,
      name: r'orderRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$orderRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OrderRepositoryRef = AutoDisposeFutureProviderRef<IOrderRepository>;
String _$orderHistoryNotifierHash() =>
    r'1ce3c5176f5bfed4be69f9aa3b64c02d96dca8ea';

/// Manages the paginated [OrderSummary] list state for the UI layer.
///
/// Uses the stale-while-revalidate (SWR) pattern via
/// [IOrderRepository.watchOrderHistory] for the initial page load: the cached
/// first page is emitted immediately, then fresh Firestore data is fetched in
/// the background.
///
/// Subsequent pages are loaded on demand via [loadNextPage], which appends
/// results to the accumulated list.
///
/// Exposes:
/// - [loadNextPage] — fetches the next page and appends it to the current list
/// - [refresh] — resets to page 1 and reloads from scratch
///
/// Internal state:
/// - [_currentPage] — tracks the last successfully loaded page number
/// - [_hasMore] — set to `false` when a page returns fewer items than
///   [_kDefaultPageSize], indicating the end of the history
///
/// The notifier returns an empty list when no user is signed in.
///
/// Satisfies Requirements 5.1–5.5.
///
/// Copied from [OrderHistoryNotifier].
@ProviderFor(OrderHistoryNotifier)
final orderHistoryNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      OrderHistoryNotifier,
      List<OrderSummary>
    >.internal(
      OrderHistoryNotifier.new,
      name: r'orderHistoryNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$orderHistoryNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OrderHistoryNotifier = AutoDisposeAsyncNotifier<List<OrderSummary>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
