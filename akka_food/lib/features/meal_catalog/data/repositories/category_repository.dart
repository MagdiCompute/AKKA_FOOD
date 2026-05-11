import 'dart:async';

import 'package:akka_food/features/meal_catalog/data/datasources/firestore_category_data_source.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/hive_catalog_cache.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_category_repository.dart';

/// Concrete implementation of [ICategoryRepository].
///
/// Delegates all operations to [FirestoreCategoryDataSource].
///
/// When [cache] is provided, [getActiveCategories] is served with a
/// stale-while-revalidate strategy:
/// - If a valid (or stale) cache entry exists, it is returned immediately and
///   a background refresh is triggered to keep the cache warm.
/// - If no cache entry exists, data is fetched from the network and the result
///   is written to the cache.
///
/// Firebase imports are allowed in this data-layer class (transitively via
/// the data source).
class CategoryRepository implements ICategoryRepository {
  CategoryRepository({
    required FirestoreCategoryDataSource categoryDataSource,
    HiveCatalogCache? cache,
  })  : _categoryDataSource = categoryDataSource,
        _cache = cache;

  final FirestoreCategoryDataSource _categoryDataSource;

  /// Optional local cache. When provided, [getActiveCategories] results are
  /// served with stale-while-revalidate semantics.
  final HiveCatalogCache? _cache;

  // ---------------------------------------------------------------------------
  // ICategoryRepository
  // ---------------------------------------------------------------------------

  @override
  Future<List<Category>> getActiveCategories() async {
    final cached = await _cache?.getCachedCategories();
    if (cached != null) {
      // Serve stale data immediately; refresh cache in the background.
      unawaited(_refreshCategoriesCache());
      return cached;
    }

    // No cache hit — fetch from network and persist.
    final categories = await _categoryDataSource.getActiveCategories();
    unawaited(_cache?.cacheCategories(categories));
    return categories;
  }

  @override
  Future<Category?> getCategoryById(String id) {
    return _categoryDataSource.getCategoryById(id);
  }

  @override
  Future<void> createCategory(Category category) {
    return _categoryDataSource.createCategory(category);
  }

  @override
  Future<void> updateCategory(Category category) {
    return _categoryDataSource.updateCategory(category);
  }

  @override
  Future<void> deactivateCategory(String id) {
    return _categoryDataSource.deactivateCategory(id);
  }

  // ---------------------------------------------------------------------------
  // Private cache-refresh helper
  // ---------------------------------------------------------------------------

  /// Fetches fresh categories from the network and updates the cache.
  /// Errors are swallowed so background refreshes never surface to the caller.
  Future<void> _refreshCategoriesCache() async {
    try {
      final categories = await _categoryDataSource.getActiveCategories();
      await _cache?.cacheCategories(categories);
    } catch (_) {
      // Silently swallow errors — stale cache remains valid.
    }
  }
}
