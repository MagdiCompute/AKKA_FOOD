import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akka_food/features/cart/domain/entities/cart_item.dart';
import 'package:akka_food/features/cart/presentation/notifiers/cart_notifier.dart';

/// A tile widget representing a single [CartItem] in the cart list.
///
/// Features:
/// - Swipe-to-delete (end-to-start) via [Dismissible] (Req 4.3).
/// - Meal image with fallback icon on error.
/// - Meal name, unit price, and line total.
/// - Quantity stepper (+/−) that calls [CartNotifier.updateQuantity].
///   Decrementing to 0 removes the item (Req 3.2, 3.3).
///   Incrementing is capped at 20 by the notifier (Req 3.4).
/// - Red overlay/border when [CartItem.isAvailable] is `false` (Req 5.1).
class CartItemTile extends ConsumerWidget {
  const CartItemTile({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(cartNotifierProvider.notifier);

    return Dismissible(
      key: Key(item.mealId),
      direction: DismissDirection.endToStart,
      // Red background with delete icon shown while swiping.
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onError,
          size: 28,
        ),
      ),
      onDismissed: (_) => notifier.removeItem(item.mealId),
      child: _CartItemCard(item: item, notifier: notifier),
    );
  }
}

// ---------------------------------------------------------------------------
// _CartItemCard — the visible card content
// ---------------------------------------------------------------------------

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.notifier});

  final CartItem item;
  final CartNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUnavailable = !item.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Red border when item is unavailable (Req 5.1).
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnavailable
            ? BorderSide(color: colorScheme.error, width: 1.5)
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Meal image ──────────────────────────────────────────
                _MealImage(imageUrl: item.mealImageUrl),
                const SizedBox(width: 12),

                // ── Name, price, stepper ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meal name
                      Text(
                        item.mealName,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Unit price
                      Text(
                        '${item.unitPrice.toStringAsFixed(0)} XOF',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Line total + quantity stepper
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Line total
                          Text(
                            '${item.lineTotal.toStringAsFixed(0)} XOF',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),

                          // Quantity stepper
                          _QuantityStepper(item: item, notifier: notifier),
                        ],
                      ),

                      // Unavailability label and Remove prompt (Req 8.4)
                      if (isUnavailable) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Item unavailable',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => notifier.removeItem(item.mealId),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Remove'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              textStyle: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Semi-transparent red overlay when unavailable (Req 5.1).
          if (isUnavailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MealImage — 64×64 rounded image with fallback
// ---------------------------------------------------------------------------

class _MealImage extends StatelessWidget {
  const _MealImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(colorScheme),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _imageFallback(colorScheme);
                },
              )
            : _imageFallback(colorScheme),
      ),
    );
  }

  Widget _imageFallback(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.fastfood_outlined,
        color: colorScheme.outline,
        size: 28,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _QuantityStepper — −/quantity/+ row
// ---------------------------------------------------------------------------

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.item, required this.notifier});

  final CartItem item;
  final CartNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button — removes item when quantity reaches 0 (Req 3.2)
          _StepperButton(
            icon: Icons.remove,
            onTap: () => notifier.updateQuantity(
              item.mealId,
              item.quantity - 1,
            ),
            colorScheme: colorScheme,
          ),

          // Quantity display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${item.quantity}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Increment button — capped at 20 by notifier (Req 3.4)
          _StepperButton(
            icon: Icons.add,
            onTap: () => notifier.updateQuantity(
              item.mealId,
              item.quantity + 1,
            ),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StepperButton — a single +/− icon button inside the stepper
// ---------------------------------------------------------------------------

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.colorScheme,
  });

  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
