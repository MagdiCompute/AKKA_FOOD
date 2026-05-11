import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/recommendation_system/presentation/notifiers/recommendation_notifier.dart';

/// Displays a horizontal list of recommended meals in the catalog.
///
/// This widget watches [recommendationNotifierProvider] directly and handles:
/// - Hiding when the user is unauthenticated
/// - Hiding when fewer than 3 meals are available
/// - Hiding on loading/error states
/// - Showing a personalized indicator in the header
/// - Navigating to MealDetailScreen on tap
class RecommendedSection extends ConsumerWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    // Hide when user is unauthenticated.
    if (currentUser == null) return const SizedBox.shrink();

    final recommendationState = ref.watch(recommendationNotifierProvider);

    // Hide on loading or error states.
    if (recommendationState.isLoading || recommendationState.hasError) {
      return const SizedBox.shrink();
    }

    final meals = recommendationState.valueOrNull ?? [];

    // Hide when fewer than 3 items.
    if (meals.length < 3) return const SizedBox.shrink();

    // Access the notifier to check if recommendations are personalized.
    final isPersonalized = ref
        .watch(recommendationNotifierProvider.notifier)
        .isPersonalized;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with personalized indicator.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Recommended for You',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              _PersonalizedBadge(isPersonalized: isPersonalized),
            ],
          ),
        ),

        // Horizontal meal list.
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => context.push('/meals/${meal.id}'),
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

/// Small badge indicating whether recommendations are personalized or
/// popularity-based.
class _PersonalizedBadge extends StatelessWidget {
  const _PersonalizedBadge({required this.isPersonalized});

  final bool isPersonalized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPersonalized
            ? colorScheme.primaryContainer
            : colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPersonalized ? '✨ Personalized' : '🔥 Popular',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPersonalized
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
