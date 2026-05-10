import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_order_view.dart';
import '../../domain/entities/admin_user_view.dart';
import '../notifiers/admin_user_notifier.dart';

/// Displays the full profile, order history, and coin balance for a single
/// user as seen by an admin.
///
/// Satisfies Requirement 6.2 (user profile, order history, coin balance).
class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminUserDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.whenOrNull(
              data: (s) => Text(s.user.displayName),
            ) ??
            const Text('User Detail'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminUserDetailProvider(userId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load user.\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
        data: (state) => _UserDetailBody(
          user: state.user,
          orders: state.orders,
          userId: userId,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _UserDetailBody extends ConsumerWidget {
  const _UserDetailBody({
    required this.user,
    required this.orders,
    required this.userId,
  });

  final AdminUserView user;
  final List<AdminOrderView> orders;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminUserDetailProvider(userId));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ── Profile header ──────────────────────────────────────────────
          _ProfileHeader(user: user, colorScheme: colorScheme, textTheme: textTheme),

          const Divider(height: 1),

          // ── Stats row ───────────────────────────────────────────────────
          _StatsRow(user: user, colorScheme: colorScheme, textTheme: textTheme),

          const Divider(height: 1),

          // ── Deactivate / Reactivate button (placeholder for task 7.4) ──
          _ManageUserButton(user: user, userId: userId),

          const Divider(height: 1),

          // ── Order history ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Order History', style: textTheme.titleMedium),
          ),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'No orders yet.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ...orders.map((order) => _OrderTile(order: order)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.colorScheme,
    required this.textTheme,
  });

  final AdminUserView user;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: user.isDeactivated
                ? colorScheme.errorContainer
                : colorScheme.primaryContainer,
            child: Text(
              initials,
              style: textTheme.headlineMedium?.copyWith(
                color: user.isDeactivated
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Role badge
                    if (user.role == 'admin')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_formatDate(user.createdAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                // Account status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: user.isDeactivated
                        ? colorScheme.errorContainer
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isDeactivated ? 'Deactivated' : 'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: user.isDeactivated
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.user,
    required this.colorScheme,
    required this.textTheme,
  });

  final AdminUserView user;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.monetization_on_outlined,
              label: 'Coin Balance',
              value: '${user.coinBalance} coins',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ),
          Container(width: 1, height: 48, color: colorScheme.outlineVariant),
          Expanded(
            child: _StatItem(
              icon: Icons.receipt_long_outlined,
              label: 'Total Orders',
              value: '${user.orderCount}',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Manage user button — wired with confirmation dialog (task 7.4)
// ---------------------------------------------------------------------------

class _ManageUserButton extends ConsumerWidget {
  const _ManageUserButton({required this.user, required this.userId});

  final AdminUserView user;
  final String userId;

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final isDeactivating = !user.isDeactivated;
    final action = isDeactivating ? 'Deactivate' : 'Reactivate';
    final message = isDeactivating
        ? 'Deactivating this account will prevent the user from signing in. '
            'You can reactivate it at any time.'
        : 'Reactivating this account will allow the user to sign in again.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Account'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: isDeactivating
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final notifier = ref.read(adminUserNotifierProvider.notifier);
      if (isDeactivating) {
        await notifier.deactivateUser(userId);
      } else {
        await notifier.reactivateUser(userId);
      }
      // Refresh the detail screen to reflect the new status.
      ref.invalidate(adminUserDetailProvider(userId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $action user: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: OutlinedButton.icon(
        icon: Icon(
          user.isDeactivated
              ? Icons.person_add_outlined
              : Icons.person_off_outlined,
        ),
        label: Text(
            user.isDeactivated ? 'Reactivate Account' : 'Deactivate Account'),
        style: OutlinedButton.styleFrom(
          foregroundColor: user.isDeactivated
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          side: BorderSide(
            color: user.isDeactivated
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
        onPressed: () => _confirm(context, ref),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order tile
// ---------------------------------------------------------------------------

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final AdminOrderView order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      key: ValueKey(order.orderId),
      leading: _StatusChip(status: order.status, colorScheme: colorScheme),
      title: Text(
        '#${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}…',
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _formatDate(order.createdAt),
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        '${order.total.toStringAsFixed(0)} XOF',
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.colorScheme});

  final DeliveryStatus status;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      DeliveryStatus.delivered => (colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
      DeliveryStatus.cancelled => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      DeliveryStatus.outForDelivery => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
      _ => (colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
