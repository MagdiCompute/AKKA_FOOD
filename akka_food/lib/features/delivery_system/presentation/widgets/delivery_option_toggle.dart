import 'package:flutter/material.dart';

import 'package:akka_food/features/delivery_system/domain/entities/delivery_option.dart';

/// A segmented toggle that lets the user choose between Delivery and Pickup.
///
/// This is a stateless, reusable widget that accepts the current
/// [DeliveryOption] value and an [onChanged] callback. It uses Material 3
/// [SegmentedButton] for the toggle UI.
///
/// Satisfies Requirement 1 AC1: The Cart screen SHALL allow the User to select
/// either "Delivery" or "Pickup" before checkout.
class DeliveryOptionToggle extends StatelessWidget {
  /// Creates a [DeliveryOptionToggle].
  ///
  /// [value] is the currently selected delivery option.
  /// [onChanged] is called when the user selects a different option.
  const DeliveryOptionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The currently selected delivery option.
  final DeliveryOption value;

  /// Called when the user selects a different delivery option.
  final ValueChanged<DeliveryOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Delivery option selector',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SegmentedButton<DeliveryOption>(
          segments: const [
            ButtonSegment<DeliveryOption>(
              value: DeliveryOption.delivery,
              label: Text('Livraison'),
              icon: Icon(Icons.local_shipping_outlined),
            ),
            ButtonSegment<DeliveryOption>(
              value: DeliveryOption.pickup,
              label: Text('À emporter'),
              icon: Icon(Icons.storefront_outlined),
            ),
          ],
          selected: {value},
          onSelectionChanged: (selected) {
            onChanged(selected.first);
          },
        ),
      ),
    );
  }
}
