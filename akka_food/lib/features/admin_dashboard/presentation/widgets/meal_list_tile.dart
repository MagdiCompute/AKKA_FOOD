import 'package:flutter/material.dart';

import '../../domain/entities/meal.dart';

/// A list tile that displays a single [Meal] in the admin meal list.
///
/// Shows the meal's name, category, price, and availability status.
/// Provides an availability toggle switch and responds to taps for editing.
class MealListTile extends StatelessWidget {
  const MealListTile({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onToggleAvailability,
  });

  final Meal meal;

  /// Called when the tile is tapped (navigate to edit form).
  final VoidCallback onTap;

  /// Called when the availability switch is toggled.
  final ValueChanged<bool> onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Meal image or placeholder
              _MealThumbnail(imageUrls: meal.imageUrls),
              const SizedBox(width: 12),

              // Meal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${meal.price.toStringAsFixed(0)} XOF',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (meal.isFeatured) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: colorScheme.tertiary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Featured',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Availability toggle
              Column(
                children: [
                  Switch(
                    value: meal.isAvailable,
                    onChanged: onToggleAvailability,
                  ),
                  Text(
                    meal.isAvailable ? 'Available' : 'Hidden',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: meal.isAvailable
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the first meal image or a placeholder icon.
class _MealThumbnail extends StatelessWidget {
  const _MealThumbnail({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrls.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.restaurant,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrls.first,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
