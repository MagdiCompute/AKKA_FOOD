import 'package:flutter/material.dart';

/// A card widget that displays the restaurant's pickup address when the user
/// selects "Pickup" as their delivery option.
///
/// Satisfies Requirement 1 AC3: WHEN "Pickup" is selected, THE Cart screen
/// SHALL not require a delivery address and SHALL display the restaurant's
/// pickup address.
class PickupAddressCard extends StatelessWidget {
  /// Creates a [PickupAddressCard].
  ///
  /// [restaurantName] is the name of the restaurant for pickup.
  /// [restaurantAddress] is the full address of the restaurant.
  const PickupAddressCard({
    super.key,
    required this.restaurantName,
    required this.restaurantAddress,
  });

  /// The name of the restaurant where the order will be picked up.
  final String restaurantName;

  /// The full address of the restaurant for pickup.
  final String restaurantAddress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Pickup address for $restaurantName',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        restaurantName,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurantAddress,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Get directions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
