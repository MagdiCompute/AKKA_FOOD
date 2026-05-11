import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:akka_food/features/meal_catalog/data/datasources/algolia_search_data_source.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/firestore_featured_data_source.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/firestore_meal_data_source.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/hive_catalog_cache.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_meal_repository.dart';

/// Concrete implementation of [IMealRepository].
///
/// Composes [FirestoreMealDataSource] (paginated queries, CRUD),
/// [FirestoreFeaturedDataSource] (featured-meal queries), and optionally
/// [AlgoliaSearchDataSource] (full-text search with Firestore fallback) to
/// satisfy the full domain interface.
///
/// When [cache] is provided, the first page of meals and featured meals are
/// served with a stale-while-revalidate strategy:
/// - If a valid (or stale) cache entry exists, it is returned immediately and
///   a background refresh is triggered to keep the cache warm.
/// - If no cache entry exists, data is fetched from the network and the result
///   is written to the cache.
///
/// Firebase imports are allowed in this data-layer class.
class MealRepository implements IMealRepository {
  MealRepository({
    required FirestoreMealDataSource mealDataSource,
    required FirestoreFeaturedDataSource featuredDataSource,
    AlgoliaSearchDataSource? algoliaDataSource,
    HiveCatalogCache? cache,
  })  : _mealDataSource = mealDataSource,
        _featuredDataSource = featuredDataSource,
        _algoliaDataSource = algoliaDataSource,
        _cache = cache;

  final FirestoreMealDataSource _mealDataSource;
  final FirestoreFeaturedDataSource _featuredDataSource;

  /// Optional Algolia data source. When `null` or unavailable, search falls
  /// back to the Firestore prefix implementation.
  final AlgoliaSearchDataSource? _algoliaDataSource;

  /// Optional local cache. When provided, first-page results are served with
  /// stale-while-revalidate semantics.
  final HiveCatalogCache? _cache;

  // ---------------------------------------------------------------------------
  // IMealRepository
  // ---------------------------------------------------------------------------

  @override
  Future<List<Meal>> getMeals({
    MealFilter? filter,
    MealSortOption? sort,
    int pageSize = 20,
    dynamic startAfterDocument,
  }) async {
    // Stale-while-revalidate applies to the first page only.
    if (startAfterDocument == null) {
      final cached = await _cache?.getCachedMeals();
      if (cached != null) {
        // Serve stale data immediately; refresh cache in the background.
        unawaited(
          _refreshMealsCache(filter: filter, sort: sort, pageSize: pageSize),
        );
        return cached;
      }
    }

    // No cache hit or subsequent pages — fetch from network.
    final meals = await _mealDataSource.getMeals(
      filter: filter,
      sort: sort,
      pageSize: pageSize,
      startAfterDocument: startAfterDocument as DocumentSnapshot?,
    );

    // Persist first-page results to cache.
    if (startAfterDocument == null) {
      unawaited(_cache?.cacheMeals(meals));
    }

    return meals;
  }

  @override
  Future<Meal?> getMealById(String id) {
    return _mealDataSource.getMealById(id);
  }

  @override
  Future<List<Meal>> getFeaturedMeals() async {
    final cached = await _cache?.getCachedFeaturedMeals();
    if (cached != null) {
      // Serve stale data immediately; refresh cache in the background.
      unawaited(_refreshFeaturedCache());
      return cached;
    }

    // No cache hit — fetch from network and persist.
    final meals = await _featuredDataSource.getFeaturedMeals();
    unawaited(_cache?.cacheFeaturedMeals(meals));
    return meals;
  }

  /// Searches meals by [query], using Algolia when available and falling back
  /// to a Firestore name-prefix filter when Algolia is unavailable.
  ///
  /// Strategy:
  /// 1. If [_algoliaDataSource] is configured and [AlgoliaSearchDataSource.isAvailable]
  ///    returns `true`, delegate to Algolia for full-text search.
  /// 2. If Algolia throws [AlgoliaUnavailableException] (e.g. network error,
  ///    bad credentials), silently fall through to the Firestore fallback.
  /// 3. Firestore fallback applies:
  ///    `where('name', isGreaterThanOrEqualTo: query, isLessThan: query + '\uf8ff')`
  @override
  Future<List<Meal>> searchMeals(String query) async {
    // Capture in a local variable so Dart flow analysis can promote the type
    // and avoid unnecessary null-assertion warnings on the field.
    final algolia = _algoliaDataSource;
    if (algolia != null && algolia.isAvailable) {
      try {
        return await algolia.searchMeals(query);
      } on AlgoliaUnavailableException {
        // Fall through to Firestore fallback.
      }
    }
    return _mealDataSource.searchMeals(query);
  }

  @override
  Future<void> createMeal(Meal meal) {
    return _mealDataSource.createMeal(meal);
  }

  @override
  Future<void> updateMeal(Meal meal) {
    return _mealDataSource.updateMeal(meal);
  }

  @override
  Future<void> deleteMeal(String id) {
    return _mealDataSource.deleteMeal(id);
  }

  // ---------------------------------------------------------------------------
  // Private cache-refresh helpers
  // ---------------------------------------------------------------------------

  /// Fetches a fresh first page of meals from the network and updates the
  /// cache. Errors are swallowed so background refreshes never surface to the
  /// caller.
  Future<void> _refreshMealsCache({
    MealFilter? filter,
    MealSortOption? sort,
    int pageSize = 20,
  }) async {
    try {
      final meals = await _mealDataSource.getMeals(
        filter: filter,
        sort: sort,
        pageSize: pageSize,
      );
      await _cache?.cacheMeals(meals);
    } catch (_) {
      // Silently swallow errors — stale cache remains valid.
    }
  }

  /// Fetches fresh featured meals from the network and updates the cache.
  /// Errors are swallowed so background refreshes never surface to the caller.
  Future<void> _refreshFeaturedCache() async {
    try {
      final meals = await _featuredDataSource.getFeaturedMeals();
      await _cache?.cacheFeaturedMeals(meals);
    } catch (_) {
      // Silently swallow errors — stale cache remains valid.
    }
  }
}
