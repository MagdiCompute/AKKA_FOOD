import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';

part 'catalog_state.freezed.dart';

/// Immutable state object held by [CatalogNotifier].
///
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and
/// [copyWith].
///
/// The filter pipeline is:
///   `allMeals → applyFilter(activeFilter) → applySort(sortOption) → filteredMeals`
@freezed
abstract class CatalogState with _$CatalogState {
  const CatalogState._();

  const factory CatalogState({
    /// Full list of meals fetched from the network / cache.
    /// Subsequent pages are appended here on [CatalogNotifier.loadMore].
    required List<Meal> allMeals,

    /// Result of running [allMeals] through the active filter + sort pipeline.
    /// This is what the UI renders.
    required List<Meal> filteredMeals,

    /// Currently active filter. Defaults to [MealFilter.empty] (no-op).
    required MealFilter activeFilter,

    /// Currently active sort option. Defaults to [MealSortOption.newestFirst].
    required MealSortOption sortOption,

    /// True while the initial page is being fetched.
    required bool isLoading,

    /// True while a subsequent page is being fetched (pagination).
    required bool isLoadingMore,

    /// True when the repository indicates more pages are available.
    required bool hasMore,

    /// Non-null when the last operation produced an error.
    String? error,

    /// The current search query, or null when no search is active.
    String? searchQuery,

    /// Firestore cursor pointing to the last document of the most recently
    /// fetched page. Passed as [startAfterDocument] on the next [loadMore].
    dynamic lastDocument,
  }) = _CatalogState;

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// Number of active filter criteria — used for the filter-icon badge.
  int get activeFilterCount => activeFilter.activeCount;

  // ---------------------------------------------------------------------------
  // Named factories
  // ---------------------------------------------------------------------------

  /// Returns the default, empty state used before any data has been loaded.
  factory CatalogState.initial() => CatalogState(
        allMeals: const [],
        filteredMeals: const [],
        activeFilter: MealFilter.empty(),
        sortOption: MealSortOption.newestFirst,
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        error: null,
        searchQuery: null,
        lastDocument: null,
      );
}
