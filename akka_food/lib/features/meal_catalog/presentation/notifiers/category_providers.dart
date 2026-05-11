import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:akka_food/features/meal_catalog/data/datasources/firestore_category_data_source.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/hive_catalog_cache.dart';
import 'package:akka_food/features/meal_catalog/data/repositories/category_repository.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_category_repository.dart';

part 'category_providers.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [CategoryRepository] bound to [ICategoryRepository].
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
ICategoryRepository categoryRepository(Ref ref) {
  return CategoryRepository(
    categoryDataSource:
        FirestoreCategoryDataSource(FirebaseFirestore.instance),
    cache: HiveCatalogCache(),
  );
}

// ---------------------------------------------------------------------------
// Categories provider
// ---------------------------------------------------------------------------

/// Fetches all active categories from [ICategoryRepository.getActiveCategories].
///
/// Returns an [AsyncValue<List<Category>>] that the UI can watch.
@riverpod
Future<List<Category>> categories(Ref ref) {
  return ref.watch(categoryRepositoryProvider).getActiveCategories();
}
