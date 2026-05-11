import 'package:flutter/material.dart';

import 'package:akka_food/features/cart/domain/entities/cart.dart';

/// Displays the order cost breakdown for the current [Cart].
///
/// Shows:
/// - Subtotal
/// - Delivery fee (or "Free" when 0)
/// - Coin discount (only when [Cart.discount] > 0), in primary color
/// - Total (bold, primary color)
///
/// Satisfies Req 2.2.
class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key, required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Order Summary',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Subtotal row
              _SummaryRow(
                label: 'Subtotal',
                value: '${cart.subtotal.toStringAsFixed(0)} XOF',
              ),
              const SizedBox(height: 6),

              // Delivery fee row
              _SummaryRow(
                label: 'Delivery fee',
                value: cart.deliveryFee > 0
                    ? '${cart.deliveryFee.toStringAsFixed(0)} XOF'
                    : 'Free',
              ),

              // Coin discount row — only shown when a discount is applied
              if (cart.discount > 0) ...[
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Coin discount',
                  value: '−${cart.discount.toStringAsFixed(0)} XOF',
                  valueColor: colorScheme.primary,
                ),
              ],

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Total row — bold, primary color
              _SummaryRow(
                label: 'Total',
                value: '${cart.total.toStringAsFixed(0)} XOF',
                labelStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                valueStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SummaryRow — a single label/value row inside the summary card
// ---------------------------------------------------------------------------

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? defaultStyle),
        Text(
          value,
          style: valueStyle ?? defaultStyle?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
