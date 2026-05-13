import 'package:flutter/material.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_address.dart';

/// A widget that displays the current delivery address and allows the user
/// to confirm, edit, or add a delivery address.
///
/// Satisfies Requirement 1 AC2: WHEN "Delivery" is selected, THE Cart screen
/// SHALL require the User to confirm or select a delivery address before
/// proceeding to payment.
class DeliveryAddressSelector extends StatelessWidget {
  /// Creates a [DeliveryAddressSelector].
  ///
  /// [address] is the currently selected delivery address, or null if none set.
  /// [onAddressChanged] is called when the user wants to change/add an address.
  /// [showError] controls whether a validation error is displayed.
  const DeliveryAddressSelector({
    super.key,
    required this.address,
    required this.onAddressChanged,
    this.showError = false,
  });

  /// The currently selected delivery address, or null if none is set.
  final DeliveryAddress? address;

  /// Called when the user taps the edit/add button to change the address.
  final VoidCallback onAddressChanged;

  /// Whether to show a validation error indicating an address is required.
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Delivery address selector',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAddressCard(context, colorScheme),
            if (showError && address == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'L\'adresse de livraison est requise',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, ColorScheme colorScheme) {
    if (address != null) {
      return _buildFilledAddress(context, colorScheme);
    }
    return _buildEmptyAddress(context, colorScheme);
  }

  Widget _buildFilledAddress(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.location_on_outlined,
          color: colorScheme.primary,
        ),
        title: Text(
          address!.label ?? 'Adresse de livraison',
          style: theme.textTheme.titleSmall,
        ),
        subtitle: Text(
          '${address!.street}, ${address!.city}',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Changer l\'adresse',
          onPressed: onAddressChanged,
        ),
      ),
    );
  }

  Widget _buildEmptyAddress(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.add_location_alt_outlined,
          color: showError ? colorScheme.error : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          'Ajouter une adresse de livraison',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: showError
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: showError ? colorScheme.error : colorScheme.onSurfaceVariant,
        ),
        onTap: onAddressChanged,
      ),
    );
  }
}
