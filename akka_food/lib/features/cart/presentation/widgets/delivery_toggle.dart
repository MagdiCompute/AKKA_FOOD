import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';

/// A segmented control that lets the user switch between Delivery and Pickup.
///
/// Reads [cartNotifierProvider] to reflect the current [DeliveryOption] and
/// calls [CartNotifier.setDeliveryOption] when the selection changes.
///
/// Satisfies Requirements 6.1, 6.2, 6.3.
class DeliveryToggle extends ConsumerWidget {
  const DeliveryToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryOption = ref.watch(
      cartNotifierProvider.select((cart) => cart.deliveryOption),
    );

    return Padding(
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
        selected: {deliveryOption},
        onSelectionChanged: (selected) {
          ref
              .read(cartNotifierProvider.notifier)
              .setDeliveryOption(selected.first);
        },
      ),
    );
  }
}
