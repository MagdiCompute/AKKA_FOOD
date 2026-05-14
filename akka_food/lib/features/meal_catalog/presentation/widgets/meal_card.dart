import 'package:flutter/material.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';

/// Stub widget for [MealCard].
///
/// Displays a meal's name, price, and availability badge.
/// Full implementation is in task 6.2.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
  });

  final Meal meal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              child: meal.imageUrls.isNotEmpty
                  ? Image.network(
                      meal.imageUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    )
                  : _ImagePlaceholder(
                      color: colorScheme.surfaceContainerHighest,
                    ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${meal.price.toStringAsFixed(0)} XOF',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!meal.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Indisponible',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
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
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: const Center(
        child: Icon(Icons.restaurant, size: 40),
      ),
    );
  }
}
