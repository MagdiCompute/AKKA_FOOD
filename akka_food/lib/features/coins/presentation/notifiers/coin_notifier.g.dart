// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$coinRepositoryHash() => r'7b52b3e00aa99117f731f2dc44c292f69a46b149';

/// Provides the concrete [CoinRepository] bound to [ICoinRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreCoinDataSource] — real-time balance stream and paginated
///   transaction history from Firestore.
/// - [FirebaseFunctions] — calls the `redeemCoins` Cloud Function.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
///
/// Copied from [coinRepository].
@ProviderFor(coinRepository)
final coinRepositoryProvider = AutoDisposeProvider<ICoinRepository>.internal(
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
typedef CoinRepositoryRef = AutoDisposeProviderRef<ICoinRepository>;
String _$coinBalanceStreamHash() => r'589a5104bff2bf4b764be56ddc7a4bf0190c866d';

/// A [StreamProvider<int>] that subscribes to [ICoinRepository.watchBalance]
/// for the currently authenticated user.
///
/// Emits the current coin balance and pushes a new value whenever the balance
/// changes in Firestore (Requirement 3 AC2 — within 5 seconds).
///
/// Emits `0` when no user is signed in.
///
/// Copied from [coinBalanceStream].
@ProviderFor(coinBalanceStream)
final coinBalanceStreamProvider = AutoDisposeStreamProvider<int>.internal(
  coinBalanceStream,
  name: r'coinBalanceStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$coinBalanceStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CoinBalanceStreamRef = AutoDisposeStreamProviderRef<int>;
String _$coinBalanceHash() => r'5824c4ca599d113969c506951ff04e9f288dac26';

/// Provides a computed [CoinBalance] value object from the raw balance integer.
///
/// Computes [CoinBalance.nextThreshold] and [CoinBalance.coinsToNext] using
/// [CoinBalance.fromTotal].
///
/// Satisfies:
/// - Requirement 3 AC1: Display current coin balance
/// - Requirement 3 AC3: Progress indicator showing coins to next threshold
///
/// Copied from [coinBalance].
@ProviderFor(coinBalance)
final coinBalanceProvider = AutoDisposeProvider<CoinBalance>.internal(
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
typedef CoinBalanceRef = AutoDisposeProviderRef<CoinBalance>;
String _$coinHistoryNotifierHash() =>
    r'3dc56557cd64fc90b42b260a58d73c5abdaae142';

/// Manages the paginated [CoinTransaction] list state for the Coins feature.
///
/// Responsibilities:
/// - Fetching the initial page of coin transactions from [ICoinRepository].
/// - Appending subsequent pages (cursor-based pagination via page index).
/// - Exposing [hasMore] to indicate whether more pages are available.
///
/// The notifier returns an empty list when no user is signed in.
///
/// Satisfies Requirement 4 AC1: Paginated transaction history.
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
