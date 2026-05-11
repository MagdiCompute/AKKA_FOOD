import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../../data/datasources/firestore_coin_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../data/repositories/coin_repository.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../domain/repositories/i_coin_repository.dart';

part 'coin_history_notifier.g.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Default number of coin transactions fetched per page.
const int _kDefaultPageSize = 20;

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [CoinRepository] bound to [ICoinRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreCoinDataSource] — reads from `/users/{uid}/coinTransactions`
/// - [HiveProfileCache] — local 5-minute TTL cache for the first page of
///   coin transaction history
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
Future<ICoinRepository> coinRepository(Ref ref) async {
  final cache = await HiveProfileCache.open();
  return CoinRepository(
    firestoreDataSource: FirestoreCoinDataSource(),
    cache: cache,
  );
}

// ---------------------------------------------------------------------------
// coinBalanceProvider — real-time balance stream
// ---------------------------------------------------------------------------

/// A [StreamProvider<int>] that subscribes to [ICoinRepository.watchCoinBalance]
/// for the currently authenticated user.
///
/// Emits the current coin balance and pushes a new value whenever the balance
/// changes in Firestore (Requirement 6.6 — within 5 seconds).
///
/// Emits `0` when no user is signed in.
@riverpod
Stream<int> coinBalance(Ref ref) async* {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    yield 0;
    return;
  }

  final repository = await ref.watch(coinRepositoryProvider.future);
  yield* repository.watchCoinBalance(currentUser.uid);
}

// ---------------------------------------------------------------------------
// CoinHistoryNotifier
// ---------------------------------------------------------------------------

/// Manages the paginated [CoinTransaction] list state for the UI layer.
///
/// Uses the stale-while-revalidate (SWR) pattern via
/// [ICoinRepository.watchCoinTransactions] for the initial page load: the
/// cached first page is emitted immediately, then fresh Firestore data is
/// fetched in the background.
///
/// Subsequent pages are loaded on demand via [loadNextPage], which appends
/// results to the accumulated list.
///
/// Real-time coin balance updates are handled separately by
/// [coinBalanceProvider], which subscribes to [ICoinRepository.watchCoinBalance].
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
/// Satisfies Requirement 6.6.
@riverpod
class CoinHistoryNotifier extends _$CoinHistoryNotifier {
  int _currentPage = 1;
  bool _hasMore = true;

  // ---------------------------------------------------------------------------
  // build — SWR stream for page 1
  // ---------------------------------------------------------------------------

  /// Initialises the notifier by subscribing to the SWR coin transaction
  /// stream for the first page.
  ///
  /// Returns an empty list when no user is signed in.
  @override
  Future<List<CoinTransaction>> build() async {
    _currentPage = 1;
    _hasMore = true;

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return [];

    final repository = await ref.watch(coinRepositoryProvider.future);

    // Collect the SWR stream into a single Future that resolves to the
    // latest emitted value (fresh data after stale-while-revalidate).
    List<CoinTransaction> latest = [];
    await for (final transactions in repository.watchCoinTransactions(
      currentUser.uid,
      pageSize: _kDefaultPageSize,
    )) {
      latest = transactions;
      // Update state with each emission so the UI reflects stale data
      // immediately while fresh data loads.
      state = AsyncData(transactions);
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

  /// Fetches the next page of coin transaction history and appends it to the
  /// current list.
  ///
  /// Does nothing if [hasMore] is `false` (all pages have been loaded) or if
  /// the state is currently loading.
  ///
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirement 6.2.
  Future<void> loadNextPage() async {
    if (!_hasMore) return;
    if (state.isLoading) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repository = await ref.read(coinRepositoryProvider.future);

    final previous = state;
    state =
        const AsyncLoading<List<CoinTransaction>>().copyWithPrevious(previous);

    try {
      final nextPage = _currentPage + 1;
      final newTransactions = await repository.getCoinTransactions(
        currentUser.uid,
        page: nextPage,
        pageSize: _kDefaultPageSize,
      );

      // Determine whether there are more pages.
      if (newTransactions.length < _kDefaultPageSize) {
        _hasMore = false;
      }

      // Append new transactions to the existing list.
      final currentList = previous.valueOrNull ?? [];
      state = AsyncData([...currentList, ...newTransactions]);

      // Only advance the page counter on success.
      _currentPage = nextPage;
    } catch (e, st) {
      state = AsyncError<List<CoinTransaction>>(e, st)
          .copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // refresh
  // ---------------------------------------------------------------------------

  /// Resets to page 1 and reloads the coin transaction history from scratch.
  ///
  /// Triggers a full rebuild of the notifier via [ref.invalidateSelf], which
  /// re-runs [build] and restores the SWR stream for the first page.
  ///
  /// Satisfies Requirement 6.3.
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
