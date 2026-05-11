import 'package:flutter/material.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';

/// Stub widget for [RecommendedSection].
///
/// Displays a horizontal list of recommended meals.
/// Hidden when fewer than 3 items are available.
/// Full implementation is in task 6.5.
class RecommendedSection extends StatelessWidget {
  const RecommendedSection({
    super.key,
    required this.recommendedMeals,
    this.onMealTap,
  });

  final List<Meal> recommendedMeals;
  final void Function(Meal meal)? onMealTap;

  @override
  Widget build(BuildContext context) {
    // Hidden when fewer than 3 items.
    if (recommendedMeals.length < 3) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Recommended for You',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recommendedMeals.length,
            itemBuilder: (context, index) {
              final meal = recommendedMeals[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => onMealTap?.call(meal),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: meal.imageUrls.isNotEmpty
                              ? Image.network(
                                  meal.imageUrls.first,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    color: colorScheme.surfaceContainerHigh,
                                    child: const Icon(Icons.restaurant),
                                  ),
                                )
                              : Container(
                                  height: 80,
                                  color: colorScheme.surfaceContainerHigh,
                                  child: const Icon(Icons.restaurant),
                                ),
                        ),

                        // Name & price
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                style: theme.textTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${meal.price.toStringAsFixed(0)} XOF',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
