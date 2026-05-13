import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../notifiers/admin_meal_notifier.dart';
import '../widgets/meal_list_tile.dart';

/// Displays all meals (available and unavailable) with search, category
/// filter, and per-meal availability toggle.
///
/// Satisfies Requirement 2.1 and 2.4.
class AdminMealListScreen extends ConsumerStatefulWidget {
  const AdminMealListScreen({super.key});

  @override
  ConsumerState<AdminMealListScreen> createState() =>
      _AdminMealListScreenState();
}

class _AdminMealListScreenState extends ConsumerState<AdminMealListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mealState = ref.watch(adminMealNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Gérer les catégories',
            onPressed: () => context.push(AppRoutes.adminCategories),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Rechercher des plats…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(adminMealNotifierProvider.notifier)
                          .setSearchQuery('');
                    },
                  ),
              ],
              onChanged: (query) {
                ref
                    .read(adminMealNotifierProvider.notifier)
                    .setSearchQuery(query);
              },
            ),
          ),

          // ── Category filter chips ────────────────────────────────────────
          mealState.when(
            data: (state) => _CategoryFilterBar(
              categories: state.categories,
              selectedCategory: state.selectedCategory,
              onSelected: (cat) => ref
                  .read(adminMealNotifierProvider.notifier)
                  .setCategory(cat),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Meal list ────────────────────────────────────────────────────
          Expanded(
            child: mealState.when(
              data: (state) {
                final meals = state.filteredMeals;

                if (meals.isEmpty) {
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
                          state.allMeals.isEmpty
                              ? 'Aucun plat.\nAppuyez sur + pour ajouter le premier.'
                              : 'Aucun plat ne correspond à votre recherche.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // The stream auto-refreshes; this is a no-op but gives
                    // the user visual feedback.
                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      return MealListTile(
                        key: ValueKey(meal.id),
                        meal: meal,
                        onTap: () => context.push(
                          '/admin/meals/${meal.id}/edit',
                        ),
                        onToggleAvailability: (value) async {
                          try {
                            await ref
                                .read(adminMealNotifierProvider.notifier)
                                .toggleAvailability(
                                  meal.id,
                                  isAvailable: value,
                                );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Échec de la mise à jour. Veuillez réessayer.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Échec du chargement des plats.\n$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── FAB: Add new meal ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminMealNew),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un plat'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category filter bar
// ---------------------------------------------------------------------------

/// Horizontal scrollable row of filter chips for meal categories.
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tous'),
              selected: selectedCategory == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          // One chip per category
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: selectedCategory == cat,
                onSelected: (selected) => onSelected(selected ? cat : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
