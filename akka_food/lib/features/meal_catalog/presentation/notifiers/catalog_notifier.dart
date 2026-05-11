import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:akka_food/features/meal_catalog/data/datasources/firestore_featured_data_source.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/firestore_meal_data_source.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/hive_catalog_cache.dart';
import 'package:akka_food/features/meal_catalog/data/repositories/meal_repository.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_meal_repository.dart';
import 'catalog_state.dart';

part 'catalog_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Meal detail provider
// ---------------------------------------------------------------------------

/// Fetches a single meal by [mealId] from [IMealRepository.getMealById].
///
/// Returns `null` when no meal with the given id exists.
@riverpod
Future<Meal?> mealDetail(Ref ref, String mealId) {
  return ref.watch(mealRepositoryProvider).getMealById(mealId);
}

// ---------------------------------------------------------------------------
// Admin meals provider
// ---------------------------------------------------------------------------

/// Fetches all meals (including unavailable) for the admin management screen.
///
/// Uses a large [pageSize] to load all meals in a single request.
@riverpod
Future<List<Meal>> adminMeals(Ref ref) {
  return ref.watch(mealRepositoryProvider).getMeals(pageSize: 100);
}

/// Provides the concrete [MealRepository] bound to [IMealRepository].
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
IMealRepository mealRepository(Ref ref) {
  return MealRepository(
    mealDataSource: FirestoreMealDataSource(FirebaseFirestore.instance),
    featuredDataSource:
        FirestoreFeaturedDataSource(FirebaseFirestore.instance),
    algoliaDataSource: null, // Algolia configured separately when available
    cache: HiveCatalogCache(),
  );
}

// ---------------------------------------------------------------------------
// CatalogNotifier
// ---------------------------------------------------------------------------

/// Manages the full state of the meal catalog browsing surface.
///
/// Responsibilities:
/// - Fetching the initial page of meals from [IMealRepository].
/// - Appending subsequent pages (cursor-based pagination).
/// - Applying client-side filter + sort pipeline.
/// - Delegating full-text search to [IMealRepository.searchMeals].
///
/// State shape: [CatalogState].
@riverpod
class CatalogNotifier extends _$CatalogNotifier {
  static const int _pageSize = 20;

  @override
  Future<CatalogState> build() async {
    // Return the initial (empty) state immediately so the UI can render.
    // The caller is expected to invoke [loadInitial] to populate data.
    return CatalogState.initial();
  }

  // Convenience accessor for the injected repository.
  IMealRepository get _repository => ref.read(mealRepositoryProvider);

  // ---------------------------------------------------------------------------
  // loadInitial
  // ---------------------------------------------------------------------------

  /// Fetches the first page of meals and populates [CatalogState.allMeals].
  ///
  /// Sets [CatalogState.isLoading] to `true` while the request is in flight.
  /// On success, runs the filter + sort pipeline and stores the Firestore
  /// cursor for subsequent [loadMore] calls.
  Future<void> loadInitial() async {
    // Guard: don't re-fetch while already loading.
    final current = state.valueOrNull;
    if (current != null && current.isLoading) return;

    // Optimistically update loading flag.
    state = AsyncData(
      (current ?? CatalogState.initial()).copyWith(
        isLoading: true,
        error: null,
      ),
    );

    try {
      final meals = await _repository.getMeals(pageSize: _pageSize);

      // Determine the Firestore cursor from the raw data source so we can
      // paginate. We reach into the FirestoreMealDataSource directly because
      // IMealRepository.getMeals returns only the meal list, not the snapshot.
      // The cursor is stored as the last meal's id; loadMore will use it.
      final lastDoc = meals.isNotEmpty
          ? await _getLastDocumentSnapshot(meals.last.id)
          : null;

      final prev = state.valueOrNull ?? CatalogState.initial();
      final filtered = _applyFilterAndSort(
        meals,
        prev.activeFilter,
        prev.sortOption,
      );

      state = AsyncData(
        prev.copyWith(
          allMeals: meals,
          filteredMeals: filtered,
          isLoading: false,
          hasMore: meals.length >= _pageSize,
          lastDocument: lastDoc,
          error: null,
        ),
      );
    } catch (e) {
      final prev = state.valueOrNull ?? CatalogState.initial();
      state = AsyncData(
        prev.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // loadMore
  // ---------------------------------------------------------------------------

  /// Fetches the next page of meals and appends them to [CatalogState.allMeals].
  ///
  /// No-op when [CatalogState.hasMore] is `false` or a page fetch is already
  /// in progress ([CatalogState.isLoadingMore]).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, error: null));

    try {
      final newMeals = await _repository.getMeals(
        pageSize: _pageSize,
        startAfterDocument: current.lastDocument,
      );

      final lastDoc = newMeals.isNotEmpty
          ? await _getLastDocumentSnapshot(newMeals.last.id)
          : current.lastDocument;

      final combined = [...current.allMeals, ...newMeals];
      final filtered = _applyFilterAndSort(
        combined,
        current.activeFilter,
        current.sortOption,
      );

      state = AsyncData(
        current.copyWith(
          allMeals: combined,
          filteredMeals: filtered,
          isLoadingMore: false,
          hasMore: newMeals.length >= _pageSize,
          lastDocument: lastDoc,
          error: null,
        ),
      );
    } catch (e) {
      final prev = state.valueOrNull ?? current;
      state = AsyncData(
        prev.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // applyFilter
  // ---------------------------------------------------------------------------

  /// Updates [CatalogState.activeFilter] and re-runs the filter + sort
  /// pipeline on [CatalogState.allMeals].
  void applyFilter(MealFilter filter) {
    final current = state.valueOrNull;
    if (current == null) return;

    final filtered = _applyFilterAndSort(
      current.allMeals,
      filter,
      current.sortOption,
    );

    state = AsyncData(
      current.copyWith(
        activeFilter: filter,
        filteredMeals: filtered,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // clearFilter
  // ---------------------------------------------------------------------------

  /// Resets [CatalogState.activeFilter] to [MealFilter.empty] and re-runs
  /// the pipeline.
  void clearFilter() => applyFilter(MealFilter.empty());

  // ---------------------------------------------------------------------------
  // applySort
  // ---------------------------------------------------------------------------

  /// Updates [CatalogState.sortOption] and re-runs the filter + sort pipeline.
  void applySort(MealSortOption sort) {
    final current = state.valueOrNull;
    if (current == null) return;

    final filtered = _applyFilterAndSort(
      current.allMeals,
      current.activeFilter,
      sort,
    );

    state = AsyncData(
      current.copyWith(
        sortOption: sort,
        filteredMeals: filtered,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // search
  // ---------------------------------------------------------------------------

  /// Searches meals by [query] via [IMealRepository.searchMeals].
  ///
  /// - If [query] has fewer than 2 characters, delegates to [clearSearch].
  /// - If [query] is empty, delegates to [clearSearch].
  /// - Otherwise, calls the repository and sets [CatalogState.filteredMeals]
  ///   to the search results without modifying [CatalogState.allMeals].
  Future<void> search(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    if (query.length < 2) return;

    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(isLoading: true, searchQuery: query, error: null),
    );

    try {
      final results = await _repository.searchMeals(query);

      final prev = state.valueOrNull ?? current;
      state = AsyncData(
        prev.copyWith(
          filteredMeals: results,
          isLoading: false,
          searchQuery: query,
        ),
      );
    } catch (e) {
      final prev = state.valueOrNull ?? current;
      state = AsyncData(
        prev.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // clearSearch
  // ---------------------------------------------------------------------------

  /// Clears the active search query and re-runs the filter + sort pipeline
  /// on [CatalogState.allMeals].
  void clearSearch() {
    final current = state.valueOrNull;
    if (current == null) return;

    final filtered = _applyFilterAndSort(
      current.allMeals,
      current.activeFilter,
      current.sortOption,
    );

    state = AsyncData(
      current.copyWith(
        searchQuery: null,
        filteredMeals: filtered,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private: filter + sort pipeline
  // ---------------------------------------------------------------------------

  /// Applies [filter] then [sort] to [meals] and returns the resulting list.
  ///
  /// This is a pure client-side operation — no network calls are made.
  ///
  /// Pipeline: `meals → applyFilter → applySort → result`
  List<Meal> _applyFilterAndSort(
    List<Meal> meals,
    MealFilter filter,
    MealSortOption sort,
  ) {
    var result = meals;

    // ---- Filter ------------------------------------------------------------

    if (!filter.isEmpty) {
      result = result.where((meal) {
        // Category filter.
        if (filter.categoryIds.isNotEmpty &&
            !filter.categoryIds.contains(meal.categoryId)) {
          return false;
        }

        // Availability filter.
        if (filter.availableOnly && !meal.isAvailable) {
          return false;
        }

        // Price range filter.
        if (filter.minPrice != null && meal.price < filter.minPrice!) {
          return false;
        }
        if (filter.maxPrice != null && meal.price > filter.maxPrice!) {
          return false;
        }

        // Dietary tags filter — meal must contain ALL requested tags (AND).
        if (filter.dietaryTags.isNotEmpty) {
          for (final tag in filter.dietaryTags) {
            if (!meal.dietaryTags.contains(tag)) return false;
          }
        }

        return true;
      }).toList();
    }

    // ---- Sort --------------------------------------------------------------

    final sorted = List<Meal>.from(result);
    switch (sort) {
      case MealSortOption.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case MealSortOption.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case MealSortOption.popularityDesc:
        sorted.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      case MealSortOption.newestFirst:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return sorted;
  }

  // ---------------------------------------------------------------------------
  // Private: Firestore cursor helper
  // ---------------------------------------------------------------------------

  /// Fetches the [DocumentSnapshot] for [mealId] so it can be used as a
  /// Firestore pagination cursor.
  ///
  /// Returns `null` if the document does not exist or the fetch fails.
  Future<DocumentSnapshot?> _getLastDocumentSnapshot(String mealId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('meals')
          .doc(mealId)
          .get();
      return doc.exists ? doc : null;
    } catch (_) {
      return null;
    }
  }
}
