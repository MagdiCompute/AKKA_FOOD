import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';

/// Local cache for the Meal Catalog feature backed by Hive.
///
/// Three boxes are used:
/// - `catalog_cache`  — first page of meals
/// - `category_cache` — all active categories
/// - `featured_cache` — featured meals
///
/// Each box stores two keys:
/// - `data`      — JSON-encoded list of items
/// - `timestamp` — milliseconds since epoch when the data was written
///
/// Cache entries are considered valid for [_ttl] (5 minutes). After that
/// the getter returns `null` so the caller knows to refresh from the network.
class HiveCatalogCache {
  static const String _catalogBoxName = 'catalog_cache';
  static const String _categoryBoxName = 'category_cache';
  static const String _featuredBoxName = 'featured_cache';
  static const Duration _ttl = Duration(minutes: 5);

  // Keys within each box
  static const String _dataKey = 'data';
  static const String _timestampKey = 'timestamp';

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Opens all three Hive boxes. Call once at app startup before using any
  /// cache methods (e.g. inside `main()` after `Hive.initFlutter()`).
  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<dynamic>(_catalogBoxName),
      Hive.openBox<dynamic>(_categoryBoxName),
      Hive.openBox<dynamic>(_featuredBoxName),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Catalog (meals — first page)
  // ---------------------------------------------------------------------------

  /// Returns the cached list of meals, or `null` if the cache is empty or
  /// has expired.
  Future<List<Meal>?> getCachedMeals() async {
    final box = Hive.box<dynamic>(_catalogBoxName);
    if (!_isValid(box)) return null;

    final raw = box.get(_dataKey) as String?;
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Meal.fromMap)
        .toList();
  }

  /// Writes [meals] to the catalog cache and records the current timestamp.
  Future<void> cacheMeals(List<Meal> meals) async {
    final box = Hive.box<dynamic>(_catalogBoxName);
    final encoded = jsonEncode(meals.map((m) => m.toMap()).toList());
    await Future.wait([
      box.put(_dataKey, encoded),
      box.put(_timestampKey, DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  /// Removes all entries from the catalog cache box.
  Future<void> clearMealsCache() async {
    await Hive.box<dynamic>(_catalogBoxName).clear();
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  /// Returns the cached list of categories, or `null` if the cache is empty
  /// or has expired.
  Future<List<Category>?> getCachedCategories() async {
    final box = Hive.box<dynamic>(_categoryBoxName);
    if (!_isValid(box)) return null;

    final raw = box.get(_dataKey) as String?;
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Category.fromMap)
        .toList();
  }

  /// Writes [categories] to the category cache and records the current
  /// timestamp.
  Future<void> cacheCategories(List<Category> categories) async {
    final box = Hive.box<dynamic>(_categoryBoxName);
    final encoded = jsonEncode(categories.map((c) => c.toMap()).toList());
    await Future.wait([
      box.put(_dataKey, encoded),
      box.put(_timestampKey, DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  /// Removes all entries from the category cache box.
  Future<void> clearCategoriesCache() async {
    await Hive.box<dynamic>(_categoryBoxName).clear();
  }

  // ---------------------------------------------------------------------------
  // Featured meals
  // ---------------------------------------------------------------------------

  /// Returns the cached list of featured meals, or `null` if the cache is
  /// empty or has expired.
  Future<List<Meal>?> getCachedFeaturedMeals() async {
    final box = Hive.box<dynamic>(_featuredBoxName);
    if (!_isValid(box)) return null;

    final raw = box.get(_dataKey) as String?;
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(Meal.fromMap)
        .toList();
  }

  /// Writes [meals] to the featured cache and records the current timestamp.
  Future<void> cacheFeaturedMeals(List<Meal> meals) async {
    final box = Hive.box<dynamic>(_featuredBoxName);
    final encoded = jsonEncode(meals.map((m) => m.toMap()).toList());
    await Future.wait([
      box.put(_dataKey, encoded),
      box.put(_timestampKey, DateTime.now().millisecondsSinceEpoch),
    ]);
  }

  /// Removes all entries from the featured cache box.
  Future<void> clearFeaturedCache() async {
    await Hive.box<dynamic>(_featuredBoxName).clear();
  }

  // ---------------------------------------------------------------------------
  // TTL helper
  // ---------------------------------------------------------------------------

  /// Returns `true` when [box] contains a timestamp that is still within the
  /// [_ttl] window.
  bool _isValid(Box<dynamic> box) {
    final timestamp = box.get(_timestampKey) as int?;
    if (timestamp == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age < _ttl.inMilliseconds;
  }
}
