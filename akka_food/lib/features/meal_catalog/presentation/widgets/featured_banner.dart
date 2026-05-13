import 'package:flutter/material.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';

/// Stub widget for [FeaturedBanner].
///
/// Displays a horizontal carousel of featured meals.
/// Full implementation (PageView with auto-scroll) is in task 6.4.
class FeaturedBanner extends StatelessWidget {
  const FeaturedBanner({
    super.key,
    required this.featuredMeals,
    this.onMealTap,
  });

  final List<Meal> featuredMeals;
  final void Function(Meal meal)? onMealTap;

  @override
  Widget build(BuildContext context) {
    if (featuredMeals.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: featuredMeals.length,
        itemBuilder: (context, index) {
          final meal = featuredMeals[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onMealTap?.call(meal),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      child: meal.imageUrls.isNotEmpty
                          ? Image.network(
                              meal.imageUrls.first,
                              width: 120,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                color: colorScheme.surfaceContainerHigh,
                                child: const Icon(Icons.restaurant, size: 40),
                              ),
                            )
                          : Container(
                              width: 120,
                              color: colorScheme.surfaceContainerHigh,
                              child: const Icon(Icons.restaurant, size: 40),
                            ),
                    ),

                    // Info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PLAT DU JOUR',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              meal.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${meal.price.toStringAsFixed(0)} XOF',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
