import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/entities/delivery_address.dart';
import '../notifiers/address_notifier.dart';

/// Screen that lists all saved delivery addresses.
///
/// Features:
/// - AppBar with title "My Addresses" and a "+" FAB to add a new address.
/// - Loading state: [CircularProgressIndicator].
/// - Empty state: message "No addresses yet" with an "Add Address" button.
/// - List of addresses using [Dismissible] for swipe-to-delete.
/// - Each tile shows label, street + city, a "Default" badge when
///   [DeliveryAddress.isDefault] is true, and a "Set as Default" button
///   when it is not.
/// - Deleting the default address shows a dialog prompting the user to
///   select a new default (Requirement 4.5).
/// - FAB navigates to [AppRoutes.addressNew].
///
/// Satisfies Requirements 4.4, 4.5, 4.6, 4.7, 4.8.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressAsync = ref.watch(addressNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddAddress(context, addressAsync),
        tooltip: 'Add address',
        child: const Icon(Icons.add),
      ),
      body: addressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(addressNotifierProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return _EmptyState(
              onAdd: () => _onAddAddress(context, addressAsync),
            );
          }
          // Requirement 4.8 — default first, then creation order.
          final sorted = _sortedAddresses(addresses);
          return _AddressList(sorted: sorted);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Navigates to the add-address form, or shows an error if the 10-address
  /// limit has already been reached (Requirement 4.7).
  void _onAddAddress(
    BuildContext context,
    AsyncValue<List<DeliveryAddress>> addressAsync,
  ) {
    final current = addressAsync.valueOrNull ?? [];
    if (current.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 addresses reached. Delete one to add more.'),
        ),
      );
      return;
    }
    context.push(AppRoutes.addressNew);
  }

  /// Returns [addresses] sorted with the default first, then by [createdAt]
  /// ascending (Requirement 4.8).
  List<DeliveryAddress> _sortedAddresses(List<DeliveryAddress> addresses) {
    final copy = [...addresses];
    copy.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return copy;
  }
}

// ---------------------------------------------------------------------------
// _AddressList
// ---------------------------------------------------------------------------

class _AddressList extends ConsumerWidget {
  const _AddressList({required this.sorted});

  final List<DeliveryAddress> sorted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final address = sorted[index];
        return _AddressTile(
          address: address,
          onDelete: () => _handleDelete(context, ref, address),
          onSetDefault: () => _handleSetDefault(ref, address.id),
          onEdit: () => context.push(
            AppRoutes.addressEdit.replaceFirst(':addressId', address.id),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    DeliveryAddress address,
  ) async {
    // Requirement 4.5 — deleting the default address requires a follow-up
    // prompt to select a new default.
    if (address.isDefault) {
      await _deleteDefaultAddress(context, ref, address);
    } else {
      // Requirement 4.4 — non-default delete.
      await _confirmAndDelete(context, ref, address.id);
    }
  }

  /// Confirms deletion of a non-default address and calls the notifier.
  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    String addressId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(addressNotifierProvider.notifier)
          .deleteAddress(addressId);
    }
  }

  /// Deletes the default address and then prompts the user to pick a new
  /// default from the remaining addresses (Requirement 4.5).
  Future<void> _deleteDefaultAddress(
    BuildContext context,
    WidgetRef ref,
    DeliveryAddress address,
  ) async {
    // Confirm deletion first.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Default Address'),
        content: const Text(
          'This is your default address. Deleting it will clear your default '
          'selection. You will be prompted to choose a new default.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Delete the address.
    await ref
        .read(addressNotifierProvider.notifier)
        .deleteAddress(address.id);

    if (!context.mounted) return;

    // Prompt user to select a new default from remaining addresses.
    final remaining =
        ref.read(addressNotifierProvider).valueOrNull ?? [];

    if (remaining.isEmpty) return; // No addresses left — nothing to prompt.

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SelectNewDefaultDialog(
        addresses: remaining,
        onSelected: (newDefaultId) async {
          Navigator.of(ctx).pop();
          await ref
              .read(addressNotifierProvider.notifier)
              .setDefault(newDefaultId);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Set default
  // ---------------------------------------------------------------------------

  Future<void> _handleSetDefault(WidgetRef ref, String addressId) async {
    await ref.read(addressNotifierProvider.notifier).setDefault(addressId);
  }
}

// ---------------------------------------------------------------------------
// _AddressTile
// ---------------------------------------------------------------------------

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onDelete,
    required this.onSetDefault,
    required this.onEdit,
  });

  final DeliveryAddress address;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(address.id),
      direction: DismissDirection.endToStart,
      background: _SwipeDeleteBackground(),
      confirmDismiss: (_) async {
        // Delegate to the parent handler which shows the appropriate dialog.
        onDelete();
        // Return false so Dismissible does not remove the tile itself —
        // the notifier update will rebuild the list.
        return false;
      },
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                address.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (address.isDefault) _DefaultBadge(),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${address.streetAddress}, ${address.city}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!address.isDefault)
              TextButton(
                onPressed: onSetDefault,
                child: const Text('Set as Default'),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit address',
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SwipeDeleteBackground
// ---------------------------------------------------------------------------

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: Theme.of(context).colorScheme.error,
      child: const Icon(
        Icons.delete_outline,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DefaultBadge
// ---------------------------------------------------------------------------

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Default',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SelectNewDefaultDialog
// ---------------------------------------------------------------------------

/// Dialog shown after deleting the default address, prompting the user to
/// select a new default from the remaining addresses (Requirement 4.5).
class _SelectNewDefaultDialog extends StatelessWidget {
  const _SelectNewDefaultDialog({
    required this.addresses,
    required this.onSelected,
  });

  final List<DeliveryAddress> addresses;
  final void Function(String addressId) onSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select New Default'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: addresses.length,
          itemBuilder: (ctx, index) {
            final address = addresses[index];
            return ListTile(
              title: Text(address.label),
              subtitle: Text('${address.streetAddress}, ${address.city}'),
              onTap: () => onSelected(address.id),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyState
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

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
              Icons.location_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No addresses yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a delivery address to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
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
              'Failed to load addresses',
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
