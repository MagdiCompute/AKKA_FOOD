import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:akka_food/core/widgets/animated_list_item.dart';
import 'package:akka_food/core/widgets/shimmer_loading.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_notifier.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/category_providers.dart';
import 'package:akka_food/features/meal_catalog/presentation/widgets/category_chip.dart';
import 'package:akka_food/features/meal_catalog/presentation/widgets/featured_banner.dart';
import 'package:akka_food/features/meal_catalog/presentation/widgets/filter_bottom_sheet.dart';
import 'package:akka_food/features/meal_catalog/presentation/widgets/meal_card.dart';
import 'package:akka_food/features/meal_catalog/presentation/widgets/recommended_section.dart';
import 'package:akka_food/features/meal_catalog/presentation/widgets/sort_bottom_sheet.dart';

/// Route path constant for meal detail.
///
/// Used with `context.push('/meals/${meal.id}')`.
const _mealDetailPath = '/meals';

/// The primary browsing surface of AKKA Food.
///
/// Displays:
/// - An AppBar with search, filter (with active-count badge), and sort icons.
/// - A horizontal category chips row.
/// - A featured meals carousel (hidden when empty).
/// - A recommended meals section (hidden when < 3 items).
/// - A 2-column meal grid with infinite scroll.
/// - Loading, error, and empty states.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Whether the inline search bar is visible.
  bool _showSearch = false;

  /// Controller for the inline search text field.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Trigger initial data load after the first frame so the provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogNotifierProvider.notifier).loadInitial();
    });

    // Attach infinite-scroll listener.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Scroll handler — triggers loadMore when within 200px of the bottom.
  // ---------------------------------------------------------------------------

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(catalogNotifierProvider.notifier).loadMore();
    }
  }

  // ---------------------------------------------------------------------------
  // Category chip tap — applies a single-category filter.
  // ---------------------------------------------------------------------------

  void _onCategoryTap(Category category, MealFilter activeFilter) {
    final notifier = ref.read(catalogNotifierProvider.notifier);

    // Toggle: if this category is already the sole filter, clear it.
    if (activeFilter.categoryIds.length == 1 &&
        activeFilter.categoryIds.first == category.id) {
      notifier.clearFilter();
    } else {
      notifier.applyFilter(
        MealFilter(
          categoryIds: [category.id],
          minPrice: activeFilter.minPrice,
          maxPrice: activeFilter.maxPrice,
          availableOnly: activeFilter.availableOnly,
          dietaryTags: activeFilter.dietaryTags,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Navigate to meal detail.
  // ---------------------------------------------------------------------------

  void _navigateToMealDetail(BuildContext context, Meal meal) {
    context.push('$_mealDetailPath/${meal.id}');
  }

  // ---------------------------------------------------------------------------
  // Sort option label — used as AppBar tooltip.
  // ---------------------------------------------------------------------------

  String _sortOptionLabel(MealSortOption option) {
    switch (option) {
      case MealSortOption.priceAsc:
        return 'Sort: Price Low to High';
      case MealSortOption.priceDesc:
        return 'Sort: Price High to Low';
      case MealSortOption.popularityDesc:
        return 'Sort: Most Popular';
      case MealSortOption.newestFirst:
        return 'Sort: Newest First';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: _buildAppBar(context, catalogAsync),
      floatingActionButton: isAdmin ? _buildAdminFab(context) : null,
      body: catalogAsync.when(
        loading: () => const CatalogLoadingSkeleton(),
        error: (error, _) => _buildErrorState(error.toString()),
        data: (state) {
          // Full-screen loading on initial load with no data yet.
          if (state.isLoading && state.allMeals.isEmpty) {
            return const CatalogLoadingSkeleton();
          }

          // Full-screen error state.
          if (state.error != null && state.allMeals.isEmpty) {
            return _buildErrorState(state.error!);
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Inline search bar ──────────────────────────────────────
              if (_showSearch)
                SliverToBoxAdapter(child: _buildSearchBar()),

              // ── Error banner (non-fatal, data already loaded) ──────────
              if (state.error != null)
                SliverToBoxAdapter(
                  child: _buildErrorBanner(state.error!),
                ),

              // ── Category chips ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildCategoryChips(
                  categoriesAsync,
                  state.activeFilter,
                ),
              ),

              // ── Featured carousel ──────────────────────────────────────
              if (state.allMeals.any((m) => m.isFeatured))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FeaturedBanner(
                      featuredMeals: state.allMeals
                          .where((m) => m.isFeatured)
                          .toList()
                        ..sort(
                          (a, b) =>
                              a.featuredOrder.compareTo(b.featuredOrder),
                        ),
                      onMealTap: (meal) =>
                          _navigateToMealDetail(context, meal),
                    ),
                  ),
                ),

              // ── Recommended section ────────────────────────────────────
              const SliverToBoxAdapter(
                child: RecommendedSection(),
              ),

              // ── Section header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    state.activeFilter.isEmpty
                        ? 'Tous les plats'
                        : 'Plats filtrés',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),

              // ── Empty state ────────────────────────────────────────────
              if (state.filteredMeals.isEmpty && !state.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(state.activeFilter),
                )
              else ...[
                // ── Meal grid (2 columns) ──────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final meal = state.filteredMeals[index];
                        return AnimatedListItem(
                          index: index,
                          child: MealCard(
                            meal: meal,
                            onTap: () => _navigateToMealDetail(context, meal),
                          ),
                        );
                      },
                      childCount: state.filteredMeals.length,
                    ),
                  ),
                ),

                // ── Pagination loading indicator ───────────────────────
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AsyncValue<dynamic> catalogAsync,
  ) {
    final activeFilterCount = catalogAsync.valueOrNull?.activeFilterCount ?? 0;

    return AppBar(
      title: const Text('Menu'),
      actions: [
        // Search toggle
        IconButton(
          icon: Icon(_showSearch ? Icons.search_off : Icons.search),
          tooltip: 'Rechercher',
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                ref.read(catalogNotifierProvider.notifier).clearSearch();
              }
            });
          },
        ),

        // Filter icon with active-count badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filter',
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => FilterBottomSheet(
                    activeFilter:
                        catalogAsync.valueOrNull?.activeFilter ??
                        MealFilter.empty(),
                  ),
                );
              },
            ),
            if (activeFilterCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: _FilterBadge(count: activeFilterCount),
              ),
          ],
        ),

        // Sort icon — tooltip reflects the active sort option
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: _sortOptionLabel(
            catalogAsync.valueOrNull?.sortOption ?? MealSortOption.newestFirst,
          ),
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => SortBottomSheet(
                activeSortOption:
                    catalogAsync.valueOrNull?.sortOption ??
                    MealSortOption.newestFirst,
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Inline search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Rechercher un plat…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(catalogNotifierProvider.notifier).clearSearch();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (query) {
          setState(() {}); // Rebuild to show/hide clear button.
          ref.read(catalogNotifierProvider.notifier).search(query);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category chips row
  // ---------------------------------------------------------------------------

  Widget _buildCategoryChips(
    AsyncValue<List<Category>> categoriesAsync,
    MealFilter activeFilter,
  ) {
    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 56,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: categories.map((category) {
                final isSelected =
                    activeFilter.categoryIds.contains(category.id);
                return CategoryChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => _onCategoryTap(category, activeFilter),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }



  // ---------------------------------------------------------------------------
  // Error states
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(catalogNotifierProvider.notifier).loadInitial(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return MaterialBanner(
      content: Text(error),
      leading: const Icon(Icons.warning_amber_rounded),
      actions: [
        TextButton(
          onPressed: () =>
              ref.read(catalogNotifierProvider.notifier).loadInitial(),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(MealFilter activeFilter) {
    final hasFilter = !activeFilter.isEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Aucun plat ne correspond à vos filtres'
                  : 'Aucun plat disponible',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(catalogNotifierProvider.notifier).clearFilter(),
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Effacer les filtres'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Admin FAB
  // ---------------------------------------------------------------------------

  Widget _buildAdminFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        // Admin actions will be wired to AdminMealFormScreen in task 7.
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Meal'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/meals/new');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Manage Categories'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/categories');
                  },
                ),
              ],
            ),
          ),
        );
      },
      tooltip: 'Admin actions',
      child: const Icon(Icons.admin_panel_settings),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter badge widget
// ---------------------------------------------------------------------------

class _FilterBadge extends StatelessWidget {
  const _FilterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: colorScheme.error,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 9 ? '9+' : '$count',
          style: TextStyle(
            color: colorScheme.onError,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
