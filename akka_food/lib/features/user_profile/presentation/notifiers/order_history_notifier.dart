import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../../data/datasources/firestore_order_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/entities/order_summary.dart';
import '../../domain/repositories/i_order_repository.dart';

part 'order_history_notifier.g.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Default number of orders fetched per page.
const int _kDefaultPageSize = 20;

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [OrderRepository] bound to [IOrderRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreOrderDataSource] — reads from the `/orders` collection
/// - [HiveProfileCache] — local 5-minute TTL cache for the first page of
///   order history
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
Future<IOrderRepository> orderRepository(Ref ref) async {
  final cache = await HiveProfileCache.open();
  return OrderRepository(
    firestoreDataSource: FirestoreOrderDataSource(),
    cache: cache,
  );
}

// ---------------------------------------------------------------------------
// OrderHistoryNotifier
// ---------------------------------------------------------------------------

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
@riverpod
class OrderHistoryNotifier extends _$OrderHistoryNotifier {
  int _currentPage = 1;
  bool _hasMore = true;

  // ---------------------------------------------------------------------------
  // build — SWR stream for page 1
  // ---------------------------------------------------------------------------

  /// Initialises the notifier by subscribing to the SWR order history stream
  /// for the first page.
  ///
  /// Returns an empty list when no user is signed in.
  @override
  Future<List<OrderSummary>> build() async {
    _currentPage = 1;
    _hasMore = true;

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return [];

    final repository = await ref.watch(orderRepositoryProvider.future);

    // Collect the SWR stream into a single Future that resolves to the
    // latest emitted value (fresh data after stale-while-revalidate).
    List<OrderSummary> latest = [];
    await for (final orders in repository.watchOrderHistory(
      currentUser.uid,
      pageSize: _kDefaultPageSize,
    )) {
      latest = orders;
      // Update state with each emission so the UI reflects stale data
      // immediately while fresh data loads.
      state = AsyncData(orders);
    }

    // Determine whether there are more pages based on the first-page result.
    if (latest.length < _kDefaultPageSize) {
      _hasMore = false;
    }

    return latest;
  }

  // ---------------------------------------------------------------------------
  // loadNextPage
  // ---------------------------------------------------------------------------

  /// Fetches the next page of order history and appends it to the current list.
  ///
  /// Does nothing if [hasMore] is `false` (all pages have been loaded) or if
  /// the state is currently loading.
  ///
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirements 5.1, 5.2.
  Future<void> loadNextPage() async {
    if (!_hasMore) return;
    if (state.isLoading) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repository = await ref.read(orderRepositoryProvider.future);

    final previous = state;
    state = const AsyncLoading<List<OrderSummary>>().copyWithPrevious(previous);

    try {
      final nextPage = _currentPage + 1;
      final newOrders = await repository.getOrderHistory(
        currentUser.uid,
        page: nextPage,
        pageSize: _kDefaultPageSize,
      );

      // Determine whether there are more pages.
      if (newOrders.length < _kDefaultPageSize) {
        _hasMore = false;
      }

      // Append new orders to the existing list.
      final currentList = previous.valueOrNull ?? [];
      state = AsyncData([...currentList, ...newOrders]);

      // Only advance the page counter on success.
      _currentPage = nextPage;
    } catch (e, st) {
      state =
          AsyncError<List<OrderSummary>>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // refresh
  // ---------------------------------------------------------------------------

  /// Resets to page 1 and reloads the order history from scratch.
  ///
  /// Triggers a full rebuild of the notifier via [ref.invalidateSelf], which
  /// re-runs [build] and restores the SWR stream for the first page.
  ///
  /// Satisfies Requirement 5.3.
  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    ref.invalidateSelf();
    await future;
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// Whether there are more pages to load.
  ///
  /// Returns `false` once a page has returned fewer items than [_kDefaultPageSize].
  bool get hasMore => _hasMore;

  /// The current page number (1-indexed).
  int get currentPage => _currentPage;
}
