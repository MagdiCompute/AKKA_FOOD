import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/notifiers/auth_notifier.dart';
import '../../data/datasources/firestore_coin_data_source.dart';
import '../../data/repositories/coin_repository.dart';
import '../../domain/entities/coin_balance.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../domain/repositories/i_coin_repository.dart';

part 'coin_notifier.g.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Default number of coin transactions fetched per page.
const int kCoinPageSize = 20;

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [CoinRepository] bound to [ICoinRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreCoinDataSource] — real-time balance stream and paginated
///   transaction history from Firestore.
/// - [FirebaseFunctions] — calls the `redeemCoins` Cloud Function.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
ICoinRepository coinRepository(Ref ref) {
  return CoinRepository(
    firestoreDataSource: FirestoreCoinDataSource(
      firestore: FirebaseFirestore.instance,
    ),
    functions: FirebaseFunctions.instance,
  );
}

// ---------------------------------------------------------------------------
// coinBalanceStreamProvider — real-time balance stream
// ---------------------------------------------------------------------------

/// A [StreamProvider<int>] that subscribes to [ICoinRepository.watchBalance]
/// for the currently authenticated user.
///
/// Emits the current coin balance and pushes a new value whenever the balance
/// changes in Firestore (Requirement 3 AC2 — within 5 seconds).
///
/// Emits `0` when no user is signed in.
@riverpod
Stream<int> coinBalanceStream(Ref ref) async* {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    yield 0;
    return;
  }

  final repository = ref.watch(coinRepositoryProvider);
  yield* repository.watchBalance(currentUser.uid);
}

// ---------------------------------------------------------------------------
// coinBalanceProvider — computed CoinBalance from the raw stream
// ---------------------------------------------------------------------------

/// Provides a computed [CoinBalance] value object from the raw balance integer.
///
/// Computes [CoinBalance.nextThreshold] and [CoinBalance.coinsToNext] using
/// [CoinBalance.fromTotal].
///
/// Satisfies:
/// - Requirement 3 AC1: Display current coin balance
/// - Requirement 3 AC3: Progress indicator showing coins to next threshold
@riverpod
CoinBalance coinBalance(Ref ref) {
  final rawBalance = ref.watch(coinBalanceStreamProvider);
  final total = rawBalance.valueOrNull ?? 0;
  return CoinBalance.fromTotal(total);
}

// ---------------------------------------------------------------------------
// CoinHistoryNotifier — paginated transaction history
// ---------------------------------------------------------------------------

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
@riverpod
class CoinHistoryNotifier extends _$CoinHistoryNotifier {
  int _currentPage = 0;
  bool _hasMore = true;

  // ---------------------------------------------------------------------------
  // build — initial page load
  // ---------------------------------------------------------------------------

  /// Initialises the notifier by fetching the first page of coin transactions.
  ///
  /// Returns an empty list when no user is signed in.
  @override
  Future<List<CoinTransaction>> build() async {
    _currentPage = 0;
    _hasMore = true;

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return [];

    final repository = ref.watch(coinRepositoryProvider);

    final transactions = await repository.getTransactionHistory(
      uid: currentUser.uid,
      page: 0,
      pageSize: kCoinPageSize,
    );

    if (transactions.length < kCoinPageSize) {
      _hasMore = false;
    }

    return transactions;
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
  Future<void> loadNextPage() async {
    if (!_hasMore) return;
    if (state.isLoading) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final repository = ref.read(coinRepositoryProvider);

    final previous = state;
    state =
        const AsyncLoading<List<CoinTransaction>>().copyWithPrevious(previous);

    try {
      final nextPage = _currentPage + 1;
      final newTransactions = await repository.getTransactionHistory(
        uid: currentUser.uid,
        page: nextPage,
        pageSize: kCoinPageSize,
      );

      if (newTransactions.length < kCoinPageSize) {
        _hasMore = false;
      }

      final currentList = previous.valueOrNull ?? [];
      state = AsyncData([...currentList, ...newTransactions]);

      _currentPage = nextPage;
    } catch (e, st) {
      state = AsyncError<List<CoinTransaction>>(e, st)
          .copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // refresh
  // ---------------------------------------------------------------------------

  /// Resets to page 0 and reloads the coin transaction history from scratch.
  ///
  /// Triggers a full rebuild of the notifier via [ref.invalidateSelf].
  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    ref.invalidateSelf();
    await future;
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// Whether there are more pages to load.
  ///
  /// Returns `false` once a page has returned fewer items than [kCoinPageSize].
  bool get hasMore => _hasMore;

  /// The current page number (0-indexed).
  int get currentPage => _currentPage;
}
