import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/user_profile/domain/entities/delivery_address.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/address_notifier.dart';

/// A tappable card that shows the currently selected delivery address, or a
/// prompt to select one when none is set.
///
/// On tap, opens [_AddressPickerScreen] via [Navigator.push] so the user can
/// pick an address from their saved list. The selected [DeliveryAddress] is
/// returned and forwarded to [CartNotifier.setDeliveryAddress].
///
/// Satisfies Requirement 6.2 — selecting Delivery prompts the user to select
/// or confirm a delivery address.
class AddressSelector extends ConsumerWidget {
  const AddressSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final selectedAddress = cart.selectedAddress;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onTap(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  selectedAddress != null
                      ? Icons.location_on
                      : Icons.location_on_outlined,
                  color: selectedAddress != null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: selectedAddress != null
                      ? _SelectedAddressContent(address: selectedAddress)
                      : _NoAddressContent(),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the address picker and, if the user selects an address, calls
  /// [CartNotifier.setDeliveryAddress] with the result.
  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final selected = await Navigator.of(context).push<DeliveryAddress>(
      MaterialPageRoute<DeliveryAddress>(
        builder: (_) => const _AddressPickerScreen(),
      ),
    );

    if (selected != null) {
      ref.read(cartNotifierProvider.notifier).setDeliveryAddress(selected);
    }
  }
}

// ---------------------------------------------------------------------------
// _SelectedAddressContent
// ---------------------------------------------------------------------------

/// Displays the label and street address of the currently selected address.
class _SelectedAddressContent extends StatelessWidget {
  const _SelectedAddressContent({required this.address});

  final DeliveryAddress address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          address.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${address.streetAddress}, ${address.city}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _NoAddressContent
// ---------------------------------------------------------------------------

/// Prompt shown when no delivery address has been selected yet.
class _NoAddressContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Sélectionner l\'adresse de livraison',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AddressPickerScreen
// ---------------------------------------------------------------------------

/// A full-screen address picker that lists the user's saved addresses.
///
/// Tapping an address pops the route and returns the selected
/// [DeliveryAddress] to the caller.
///
/// Includes a "Manage Addresses" action in the AppBar so the user can
/// navigate to the full [AddressListScreen] to add or edit addresses.
class _AddressPickerScreen extends ConsumerWidget {
  const _AddressPickerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressAsync = ref.watch(addressNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner une adresse'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const _InlineAddressForm(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: addressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PickerErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(addressNotifierProvider),
        ),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const _PickerEmptyState();
          }

          // Sort: default first, then by creation date.
          final sorted = [...addresses]
            ..sort((a, b) {
              if (a.isDefault && !b.isDefault) return -1;
              if (!a.isDefault && b.isDefault) return 1;
              return a.createdAt.compareTo(b.createdAt);
            });

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final address = sorted[index];
              return _AddressPickerTile(
                address: address,
                onTap: () => Navigator.of(context).pop(address),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AddressPickerTile
// ---------------------------------------------------------------------------

class _AddressPickerTile extends StatelessWidget {
  const _AddressPickerTile({
    required this.address,
    required this.onTap,
  });

  final DeliveryAddress address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        Icons.location_on_outlined,
        color: theme.colorScheme.primary,
      ),
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
      onTap: onTap,
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
        'Par défaut',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PickerEmptyState
// ---------------------------------------------------------------------------

class _PickerEmptyState extends ConsumerWidget {
  const _PickerEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              'Aucune adresse enregistrée',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez une adresse de livraison pour continuer.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _InlineAddressForm(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une adresse'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PickerErrorView
// ---------------------------------------------------------------------------

class _PickerErrorView extends StatelessWidget {
  const _PickerErrorView({required this.message, required this.onRetry});

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
              'Échec du chargement des adresses',
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
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// _InlineAddressForm — quick add address from cart
// ---------------------------------------------------------------------------

/// A simple form to add a new delivery address directly from the cart flow.
/// The address is saved to Firestore (same as profile addresses).
class _InlineAddressForm extends ConsumerStatefulWidget {
  const _InlineAddressForm();

  @override
  ConsumerState<_InlineAddressForm> createState() => _InlineAddressFormState();
}

class _InlineAddressFormState extends ConsumerState<_InlineAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSaving = true);

    final newAddress = DeliveryAddress(
      id: '',
      uid: currentUser.uid,
      label: _labelController.text.trim(),
      streetAddress: _streetController.text.trim(),
      city: _cityController.text.trim(),
      isDefault: false,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(addressNotifierProvider.notifier).addAddress(newAddress);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle adresse'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _labelController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Libellé',
                    hintText: 'Ex: Maison, Bureau',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _streetController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'Ex: Rue 312, Porte 45',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    hintText: 'Ex: Bamako',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 32),
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _save,
                        child: const Text('Enregistrer l\'adresse'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
