import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/coin_transaction.dart';
import '../notifiers/coin_history_notifier.dart';

/// Screen that displays the authenticated user's real-time coin balance,
/// a progress bar toward the next redemption threshold, and a paginated
/// list of coin transactions.
///
/// Features:
/// - Header card with real-time balance (from [coinBalanceProvider]) and a
///   progress bar showing progress toward the next 1,000-coin redemption
///   threshold (Requirement 6.1, 6.6).
/// - Infinite scroll: detects when the user reaches the bottom of the list
///   and calls [CoinHistoryNotifier.loadNextPage] (Requirement 6.2).
/// - Each transaction tile shows: amount (green for credit, red for debit),
///   reason, related orderId (if present), and formatted timestamp
///   (Requirement 6.3).
/// - Loading state: [CircularProgressIndicator].
/// - Empty state: "No coin transactions yet" (Requirement 6.5).
/// - Connectivity banner when the notifier has an error but stale data is
///   available.
///
/// Satisfies Requirements 6.1–6.3, 6.5–6.6.
class CoinHistoryScreen extends ConsumerStatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  ConsumerState<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends ConsumerState<CoinHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers [loadNextPage] when the user scrolls within 200 px of the
  /// bottom of the list.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 200) {
      final notifier = ref.read(coinHistoryNotifierProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(coinHistoryNotifierProvider);
    final balanceAsync = ref.watch(coinBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Balance'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Balance header card ──────────────────────────────────────────
          _BalanceCard(balanceAsync: balanceAsync),

          // ── Transaction list ─────────────────────────────────────────────
          Expanded(
            child: transactionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.read(coinHistoryNotifierProvider.notifier).refresh(),
              ),
              data: (transactions) => _TransactionList(
                transactions: transactions,
                scrollController: _scrollController,
                isLoadingMore: transactionsAsync.isLoading,
                hasError: transactionsAsync.hasError,
                hasMore:
                    ref.read(coinHistoryNotifierProvider.notifier).hasMore,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BalanceCard
// ---------------------------------------------------------------------------

/// Header card showing the real-time coin balance and a progress bar toward
/// the next 1,000-coin redemption threshold.
///
/// 1,000 coins = 1,000 XOF discount; redemption in multiples of 1,000 coins.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceAsync});

  final AsyncValue<int> balanceAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: balanceAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (balance) {
            // Progress toward the next 1,000-coin threshold.
            const threshold = 1000;
            final remainder = balance % threshold;
            final progress = remainder / threshold;
            final coinsUntilNext = threshold - remainder;
            final readyToRedeem = balance >= threshold;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Balance row ────────────────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          NumberFormat('#,##0', 'fr_FR').format(balance),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'coins',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Progress bar ───────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: readyToRedeem ? 1.0 : progress,
                    minHeight: 10,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      readyToRedeem
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Redemption label ───────────────────────────────────────
                Text(
                  readyToRedeem
                      ? '🎉 Ready to redeem! (${balance ~/ threshold} × 1,000 XOF available)'
                      : '$coinsUntilNext coins until next redemption',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: readyToRedeem
                        ? Colors.green.shade700
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: readyToRedeem
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TransactionList
// ---------------------------------------------------------------------------

class _TransactionList extends ConsumerWidget {
  const _TransactionList({
    required this.transactions,
    required this.scrollController,
    required this.isLoadingMore,
    required this.hasError,
    required this.hasMore,
  });

  final List<CoinTransaction> transactions;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final bool hasError;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        // Connectivity banner — shown when we have stale data but the last
        // fetch failed.
        if (hasError) const _ConnectivityBanner(),

        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: transactions.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Footer: loading indicator or end-of-list sentinel.
              if (index == transactions.length) {
                return isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox.shrink();
              }

              return _TransactionTile(transaction: transactions[index]);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _TransactionTile
// ---------------------------------------------------------------------------

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final CoinTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = transaction.amount > 0;
    final amountColor = isCredit ? Colors.green.shade700 : Colors.red.shade700;
    final amountPrefix = isCredit ? '+' : '';
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm').format(transaction.timestamp);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: CircleAvatar(
        backgroundColor:
            (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.12),
        child: Icon(
          isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: amountColor,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              transaction.reason,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$amountPrefix${transaction.amount} coins',
            style: theme.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.orderId != null)
              Text(
                'Order: ${transaction.orderId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              dateStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ConnectivityBanner
// ---------------------------------------------------------------------------

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're offline. Showing cached coin history.",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyState
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No coin transactions yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Earn coins by placing orders. 5% of each order value is credited as coins.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load coin history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
