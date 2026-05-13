import 'package:akka_food/features/cart/domain/entities/delivery_option.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';
import 'package:akka_food/features/delivery_system/data/datasources/delivery_fee_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays the delivery fee clearly in the cart before the user proceeds
/// to payment.
///
/// Shows:
/// - "Delivery Fee: X XOF" when delivery is selected
/// - "Delivery Fee: Free" (with a strikethrough of the normal fee) when
///   pickup is selected
/// - A loading indicator while Remote Config is being fetched
///
/// Satisfies Requirement 5:
/// - 5.1: Display delivery fee clearly before payment
/// - 5.2: Fee fetched from Firebase Remote Config
/// - 5.3: Pickup displays 0 XOF (shown as "Free")
class DeliveryFeeDisplay extends ConsumerWidget {
  const DeliveryFeeDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final asyncService = ref.watch(deliveryFeeServiceProvider);

    return asyncService.when(
      data: (service) => _buildFeeDisplay(
        context,
        deliveryOption: cart.deliveryOption,
        fee: service.getDeliveryFee(cart.deliveryOption),
      ),
      loading: () => _buildLoadingState(context),
      error: (_, __) => _buildFeeDisplay(
        context,
        deliveryOption: cart.deliveryOption,
        fee: cart.deliveryOption == DeliveryOption.pickup ? 0.0 : 500.0,
      ),
    );
  }

  Widget _buildFeeDisplay(
    BuildContext context, {
    required DeliveryOption deliveryOption,
    required double fee,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isPickup = deliveryOption == DeliveryOption.pickup;
    final feeText = isPickup ? 'Gratuit' : '${fee.toStringAsFixed(0)} XOF';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isPickup ? Icons.store : Icons.delivery_dining,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Frais de livraison',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            feeText,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPickup ? colorScheme.tertiary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.delivery_dining,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Frais de livraison',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}
