import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_filter.freezed.dart';

/// Sort options for the meal catalog.
///
/// Applied client-side after [MealFilter] is applied to the full meal list.
enum MealSortOption {
  /// Ascending price order (cheapest first).
  priceAsc,

  /// Descending price order (most expensive first).
  priceDesc,

  /// Descending popularity order (most ordered first).
  popularityDesc,

  /// Newest meals first (by [Meal.createdAt]).
  newestFirst,
}

/// Value object representing the active filter state for the meal catalog.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Use [MealFilter.empty] to obtain a no-op filter that passes all meals through.
@freezed
abstract class MealFilter with _$MealFilter {
  const MealFilter._();

  const factory MealFilter({
    /// Category IDs to include. Empty list means all categories are shown.
    required List<String> categoryIds,

    /// Minimum price in XOF (inclusive). Null means no lower bound.
    double? minPrice,

    /// Maximum price in XOF (inclusive). Null means no upper bound.
    double? maxPrice,

    /// When `true`, only meals with [Meal.isAvailable] == true are shown.
    required bool availableOnly,

    /// Dietary tags to filter by (e.g. 'vegetarian', 'halal').
    /// A meal must match ALL tags in this list to be included.
    /// Empty list means no dietary filtering.
    required List<String> dietaryTags,
  }) = _MealFilter;

  /// A default, no-op filter that passes all meals through.
  ///
  /// - [categoryIds] and [dietaryTags] are empty (no restriction).
  /// - [minPrice] and [maxPrice] are null (no price bounds).
  /// - [availableOnly] is false (show all meals regardless of availability).
  factory MealFilter.empty() => const MealFilter(
        categoryIds: [],
        minPrice: null,
        maxPrice: null,
        availableOnly: false,
        dietaryTags: [],
      );

  /// Returns true when no filter criteria are active.
  bool get isEmpty =>
      categoryIds.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      !availableOnly &&
      dietaryTags.isEmpty;

  /// Returns the number of active filter criteria (used for badge display).
  int get activeCount =>
      (categoryIds.isNotEmpty ? 1 : 0) +
      (minPrice != null ? 1 : 0) +
      (maxPrice != null ? 1 : 0) +
      (availableOnly ? 1 : 0) +
      (dietaryTags.isNotEmpty ? 1 : 0);
}
