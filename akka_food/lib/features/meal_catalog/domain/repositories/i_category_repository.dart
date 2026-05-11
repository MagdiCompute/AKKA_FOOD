import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';

/// Abstract repository interface for meal category operations.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implementations live in the data layer ([CategoryRepository]).
abstract class ICategoryRepository {
  /// Returns all categories where [Category.isActive] is `true`.
  Future<List<Category>> getActiveCategories();

  /// Returns the category with the given [id], or `null` if not found.
  Future<Category?> getCategoryById(String id);

  /// Persists a new [category] document to the data store.
  Future<void> createCategory(Category category);

  /// Overwrites the existing category document with the data from [category].
  Future<void> updateCategory(Category category);

  /// Sets [Category.isActive] to `false` for the category identified by [id].
  ///
  /// Note: a Cloud Function is responsible for also setting `isAvailable=false`
  /// on all meals belonging to this category.
  Future<void> deactivateCategory(String id);
}
