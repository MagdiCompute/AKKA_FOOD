import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/leaderboard_visibility_notifier.dart';
import '../notifiers/notification_prefs_notifier.dart';

/// Screen that lets the authenticated user toggle each notification
/// preference category independently.
///
/// Watches [notificationPrefsNotifierProvider] and renders:
/// - A [CircularProgressIndicator] while the initial load is in progress.
/// - An error message with a retry button if the load fails.
/// - Three [SwitchListTile] widgets — one per preference category — once
///   data is available.
///
/// While a save is in progress (the notifier transitions to loading with
/// previous data), the toggles are disabled to prevent concurrent writes.
///
/// Any save failure is surfaced as a [SnackBar].
///
/// Satisfies Requirements 7.1, 7.2, 7.3, 7.4, 7.5.
class NotificationPrefsScreen extends ConsumerWidget {
  const NotificationPrefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsNotifierProvider);

    // Show a snackbar whenever the state transitions to an error that has
    // previous data (i.e. a save failed, not the initial load).
    ref.listen<AsyncValue<dynamic>>(
      notificationPrefsNotifierProvider,
      (previous, next) {
        if (next is AsyncError && next.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to save preference. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: prefsAsync.when(
        // ── Initial loading ────────────────────────────────────────────────
        loading: () => const Center(child: CircularProgressIndicator()),

        // ── Initial load error ─────────────────────────────────────────────
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationPrefsNotifierProvider),
        ),

        // ── Data available ─────────────────────────────────────────────────
        data: (prefs) {
          // prefs can be null when no user is signed in; guard defensively.
          if (prefs == null) {
            return const Center(child: Text('No user signed in.'));
          }

          // The notifier is "saving" when it is in a loading state but still
          // carries previous data (optimistic update in progress).
          final isSaving = prefsAsync.isLoading;

          return ListView(
            children: [
              // ── Order Updates ──────────────────────────────────────────
              SwitchListTile(
                title: const Text('Order Updates'),
                subtitle: const Text('Get notified about your order status'),
                value: prefs.orderUpdates,
                onChanged: isSaving
                    ? null
                    : (value) => ref
                        .read(notificationPrefsNotifierProvider.notifier)
                        .updateOrderUpdates(value),
              ),

              const Divider(height: 1),

              // ── Promotions ─────────────────────────────────────────────
              SwitchListTile(
                title: const Text('Promotions'),
                subtitle: const Text('Receive special offers and discounts'),
                value: prefs.promotions,
                onChanged: isSaving
                    ? null
                    : (value) => ref
                        .read(notificationPrefsNotifierProvider.notifier)
                        .updatePromotions(value),
              ),

              const Divider(height: 1),

              // ── Coin Rewards ───────────────────────────────────────────
              SwitchListTile(
                title: const Text('Coin Rewards'),
                subtitle: const Text(
                    'Get notified when you earn or can redeem coins'),
                value: prefs.coinEvents,
                onChanged: isSaving
                    ? null
                    : (value) => ref
                        .read(notificationPrefsNotifierProvider.notifier)
                        .updateCoinEvents(value),
              ),

              // ── Privacy section ────────────────────────────────────────
              const _SectionHeader(title: 'Privacy'),

              // ── Leaderboard Visibility ─────────────────────────────────
              _LeaderboardVisibilityTile(isSaving: isSaving),

              // ── Saving indicator ───────────────────────────────────────
              if (isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
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
              'Failed to load notification preferences',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
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



// ---------------------------------------------------------------------------
// _SectionHeader
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LeaderboardVisibilityTile
// ---------------------------------------------------------------------------

/// A [ConsumerWidget] that renders the leaderboard visibility toggle.
///
/// Reads from [leaderboardVisibilityNotifierProvider] and writes updates
/// to `/userScores/{uid}.leaderboardVisible` in Firestore.
///
/// Defaults to `true` (opted in) per Requirement 4 AC1.
class _LeaderboardVisibilityTile extends ConsumerWidget {
  const _LeaderboardVisibilityTile({required this.isSaving});

  /// Whether the parent notification prefs are currently saving.
  /// Used to disable this toggle during concurrent saves.
  final bool isSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityAsync = ref.watch(leaderboardVisibilityNotifierProvider);

    // Listen for save errors and show a snackbar.
    ref.listen<AsyncValue<bool?>>(
      leaderboardVisibilityNotifierProvider,
      (previous, next) {
        if (next is AsyncError && next.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Failed to update leaderboard visibility. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );

    final isToggleSaving = visibilityAsync.isLoading;
    final value = visibilityAsync.valueOrNull ?? true;

    return SwitchListTile(
      title: const Text('Leaderboard Visibility'),
      subtitle: const Text('Show your profile on the leaderboard'),
      value: value,
      onChanged: (isSaving || isToggleSaving)
          ? null
          : (newValue) => ref
              .read(leaderboardVisibilityNotifierProvider.notifier)
              .toggle(newValue),
    );
  }
}
