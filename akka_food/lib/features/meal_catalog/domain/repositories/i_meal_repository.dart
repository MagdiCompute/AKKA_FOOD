import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';

/// Abstract repository interface for meal catalog operations.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implementations live in the data layer ([MealRepository]).
abstract class IMealRepository {
  /// Returns a paginated list of meals, optionally filtered and sorted.
  ///
  /// - [filter] narrows results by category, price range, availability, and
  ///   dietary tags. Pass `null` (or omit) to apply no filtering.
  /// - [sort] controls the ordering of results. Pass `null` to use the
  ///   default Firestore ordering.
  /// - [pageSize] controls how many documents are returned per page (default 20).
  /// - [startAfterDocument] is the Firestore cursor from the last document of
  ///   the previous page; pass `null` to fetch the first page.
  Future<List<Meal>> getMeals({
    MealFilter? filter,
    MealSortOption? sort,
    int pageSize = 20,
    dynamic startAfterDocument,
  });

  /// Returns the meal with the given [id], or `null` if not found.
  Future<Meal?> getMealById(String id);

  /// Returns all meals where [Meal.isFeatured] is `true`,
  /// ordered ascending by [Meal.featuredOrder].
  Future<List<Meal>> getFeaturedMeals();

  /// Searches meals by [query] using Algolia full-text search.
  ///
  /// Falls back to a Firestore prefix search on [Meal.name] when Algolia
  /// is unavailable.
  Future<List<Meal>> searchMeals(String query);

  /// Persists a new [meal] document to the data store.
  Future<void> createMeal(Meal meal);

  /// Overwrites the existing meal document with the data from [meal].
  Future<void> updateMeal(Meal meal);

  /// Deletes the meal identified by [id] from the data store.
  Future<void> deleteMeal(String id);
}
