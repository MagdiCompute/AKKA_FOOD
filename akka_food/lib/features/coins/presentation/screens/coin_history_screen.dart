import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/coin_transaction.dart';
import '../notifiers/coin_notifier.dart';
import '../widgets/coin_progress_bar.dart';
import '../widgets/coin_transaction_tile.dart';

/// The main Coin History screen.
///
/// Displays:
/// - A balance card showing the user's total coin balance prominently.
/// - A [CoinProgressBar] showing progress toward the next 1000-coin threshold.
/// - A paginated list of [CoinTransaction] items with infinite scroll.
/// - Pull-to-refresh support via [RefreshIndicator].
/// - Empty state when no transactions exist (Req 4 AC3).
/// - Error state with retry option.
///
/// Satisfies:
/// - Requirement 3 AC1: Display current coin balance
/// - Requirement 3 AC3: Progress indicator
/// - Requirement 4 AC1: Paginated transaction history
/// - Requirement 4 AC3: Empty state message when no transactions
class CoinHistoryScreen extends ConsumerStatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  ConsumerState<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends ConsumerState<CoinHistoryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers loading the next page when the user scrolls near the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Load next page when within 200px of the bottom
    if (currentScroll >= maxScroll - 200) {
      ref.read(coinHistoryNotifierProvider.notifier).loadNextPage();
    }
  }

  /// Refreshes the transaction history from scratch.
  Future<void> _onRefresh() async {
    await ref.read(coinHistoryNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final coinBalance = ref.watch(coinBalanceProvider);
    final historyAsync = ref.watch(coinHistoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin History'),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Balance Card ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _BalanceCard(total: coinBalance.total),
            ),

            // ── Progress Bar ─────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: CoinProgressBar(),
              ),
            ),

            // ── Transaction List ─────────────────────────────────────────
            ...historyAsync.when(
              data: (transactions) => _buildTransactionSliver(transactions),
              loading: () => [
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, _) => [
                SliverFillRemaining(
                  child: _ErrorState(
                    message: error.toString(),
                    onRetry: _onRefresh,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the transaction list sliver(s).
  ///
  /// Returns an empty state when no transactions exist (Req 4 AC3),
  /// or a list of transaction tiles with an optional loading indicator
  /// at the bottom for pagination.
  List<Widget> _buildTransactionSliver(List<CoinTransaction> transactions) {
    if (transactions.isEmpty) {
      return [
        const SliverFillRemaining(
          child: _EmptyState(),
        ),
      ];
    }

    final hasMore =
        ref.read(coinHistoryNotifierProvider.notifier).hasMore;

    return [
      // Section header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Transactions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),

      // Transaction items
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final transaction = transactions[index];
            return CoinTransactionTile(transaction: transaction);
          },
          childCount: transactions.length,
        ),
      ),

      // Loading indicator for next page
      if (hasMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Balance Card
// ---------------------------------------------------------------------------

/// A prominent card displaying the user's total coin balance.
///
/// Satisfies Requirement 3 AC1: Display current coin balance.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedBalance = NumberFormat('#,###').format(total);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(
                Icons.monetization_on,
                size: 48,
                color: Colors.amber[700],
              ),
              const SizedBox(height: 12),
              Text(
                formattedBalance,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Coins',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State (Req 4 AC3)
// ---------------------------------------------------------------------------

/// Displayed when the user has no coin transactions.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your coin earnings and redemptions will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error State
// ---------------------------------------------------------------------------

/// Displayed when loading transactions fails. Provides a retry button.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder Transaction Tile — REMOVED in Task 5.4
// Replaced by CoinTransactionTile widget.
// ---------------------------------------------------------------------------
