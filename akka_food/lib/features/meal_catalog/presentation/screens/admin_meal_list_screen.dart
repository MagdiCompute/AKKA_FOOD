import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../domain/entities/meal.dart';
import '../notifiers/catalog_notifier.dart';

/// Admin screen that lists all meals (available and unavailable) and allows
/// toggling each meal's availability via a [Switch] widget.
///
/// Satisfies Requirement 7.1 — Admin meal management.
class AdminMealListScreen extends ConsumerStatefulWidget {
  const AdminMealListScreen({super.key});

  @override
  ConsumerState<AdminMealListScreen> createState() =>
      _AdminMealListScreenState();
}

class _AdminMealListScreenState extends ConsumerState<AdminMealListScreen> {
  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(adminMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Meals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Meal',
            onPressed: () => context.push(AppRoutes.adminMealNew),
          ),
        ],
      ),
      body: mealsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.invalidate(adminMealsProvider),
        ),
        data: (meals) {
          if (meals.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminMealsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return _MealAdminTile(
                  key: ValueKey(meal.id),
                  meal: meal,
                  onTap: () => context.push('/admin/meals/${meal.id}/edit'),
                  onToggle: (value) => _toggleAvailability(meal, value),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.adminMealNew),
        tooltip: 'Add Meal',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleAvailability(Meal meal, bool newValue) async {
    try {
      await ref
          .read(mealRepositoryProvider)
          .updateMeal(meal.copyWith(isAvailable: newValue));
      // Refresh the list so the UI reflects the updated state.
      ref.invalidate(adminMealsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update availability: $e'),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Meal admin tile
// ---------------------------------------------------------------------------

/// A single row in the admin meal list showing thumbnail, name, price,
/// category, and an availability [Switch].
class _MealAdminTile extends StatelessWidget {
  const _MealAdminTile({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onToggle,
  });

  final Meal meal;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: _MealThumbnail(imageUrl: meal.imageUrls.firstOrNull),
      title: Text(
        meal.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${meal.price.toStringAsFixed(0)} XOF',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            meal.categoryId,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Switch(
        value: meal.isAvailable,
        onChanged: onToggle,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Meal thumbnail
// ---------------------------------------------------------------------------

/// 60×60 rounded thumbnail for a meal image URL.
///
/// Shows a placeholder icon when [imageUrl] is null or empty.
class _MealThumbnail extends StatelessWidget {
  const _MealThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 60,
        height: 60,
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
        imageUrl!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 60,
          height: 60,
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No meals yet.\nTap + to add the first meal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load meals.\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
