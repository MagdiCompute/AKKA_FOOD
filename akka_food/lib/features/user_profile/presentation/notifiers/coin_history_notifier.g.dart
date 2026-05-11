// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$coinRepositoryHash() => r'ec1440707b115b6a3a9d89276882c8545cc52105';

/// Provides the concrete [CoinRepository] bound to [ICoinRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreCoinDataSource] — reads from `/users/{uid}/coinTransactions`
/// - [HiveProfileCache] — local 5-minute TTL cache for the first page of
///   coin transaction history
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [coinRepository].
@ProviderFor(coinRepository)
final coinRepositoryProvider =
    AutoDisposeFutureProvider<ICoinRepository>.internal(
      coinRepository,
      name: r'coinRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$coinRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CoinRepositoryRef = AutoDisposeFutureProviderRef<ICoinRepository>;
String _$coinBalanceHash() => r'c7e0da3f09e487b43bdd99e7b46595e2fd4e5e5e';

/// A [StreamProvider<int>] that subscribes to [ICoinRepository.watchCoinBalance]
/// for the currently authenticated user.
///
/// Emits the current coin balance and pushes a new value whenever the balance
/// changes in Firestore (Requirement 6.6 — within 5 seconds).
///
/// Emits `0` when no user is signed in.
///
/// Copied from [coinBalance].
@ProviderFor(coinBalance)
final coinBalanceProvider = AutoDisposeStreamProvider<int>.internal(
  coinBalance,
  name: r'coinBalanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$coinBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CoinBalanceRef = AutoDisposeStreamProviderRef<int>;
String _$coinHistoryNotifierHash() =>
    r'ab848b2eb19e7b5f7ac53f614fe3ed68472f68ef';

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
///
/// Copied from [CoinHistoryNotifier].
@ProviderFor(CoinHistoryNotifier)
final coinHistoryNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      CoinHistoryNotifier,
      List<CoinTransaction>
    >.internal(
      CoinHistoryNotifier.new,
      name: r'coinHistoryNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$coinHistoryNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CoinHistoryNotifier = AutoDisposeAsyncNotifier<List<CoinTransaction>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
