import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_meal_repository.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_notifier.dart';

// ---------------------------------------------------------------------------
// Mock repository
// ---------------------------------------------------------------------------

class MockMealRepository implements IMealRepository {
  final List<Meal> meals;
  MockMealRepository(this.meals);

  @override
  Future<List<Meal>> getMeals({
    MealFilter? filter,
    MealSortOption? sort,
    int pageSize = 20,
    dynamic startAfterDocument,
  }) async =>
      meals;

  @override
  Future<Meal?> getMealById(String id) => throw UnimplementedError();

  @override
  Future<List<Meal>> getFeaturedMeals() => throw UnimplementedError();

  @override
  Future<List<Meal>> searchMeals(String query) => throw UnimplementedError();

  @override
  Future<void> createMeal(Meal meal) => throw UnimplementedError();

  @override
  Future<void> updateMeal(Meal meal) => throw UnimplementedError();

  @override
  Future<void> deleteMeal(String id) => throw UnimplementedError();
}

// ---------------------------------------------------------------------------
// Test meal factory
// ---------------------------------------------------------------------------

Meal makeMeal({
  String id = '1',
  String name = 'Test Meal',
  double price = 2000,
  String categoryId = 'cat1',
  bool isAvailable = true,
  List<String> dietaryTags = const [],
  int popularityScore = 0,
  DateTime? createdAt,
}) =>
    Meal(
      id: id,
      name: name,
      description: '',
      price: price,
      categoryId: categoryId,
      imageUrls: const [],
      isAvailable: isAvailable,
      isFeatured: false,
      featuredOrder: 0,
      nutritionalInfo: null,
      dietaryTags: dietaryTags,
      popularityScore: popularityScore,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

// ---------------------------------------------------------------------------
// Helper: build a ProviderContainer with a mock repository
// ---------------------------------------------------------------------------

ProviderContainer makeContainer(List<Meal> meals) {
  return ProviderContainer(
    overrides: [
      mealRepositoryProvider.overrideWithValue(MockMealRepository(meals)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Helper: load initial meals and return the notifier
// ---------------------------------------------------------------------------

Future<CatalogNotifier> loadedNotifier(ProviderContainer container) async {
  final notifier = container.read(catalogNotifierProvider.notifier);
  await notifier.loadInitial();
  return notifier;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CatalogNotifier — filter and sort logic', () {
    // -----------------------------------------------------------------------
    // 1. Filter by category
    // -----------------------------------------------------------------------
    test('filter by category returns only meals in that category', () async {
      final meals = [
        makeMeal(id: '1', categoryId: 'catA'),
        makeMeal(id: '2', categoryId: 'catB'),
        makeMeal(id: '3', categoryId: 'catA'),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applyFilter(
        const MealFilter(
          categoryIds: ['catA'],
          availableOnly: false,
          dietaryTags: [],
        ),
      );

      final state = container.read(catalogNotifierProvider).value!;
      expect(state.filteredMeals.length, 2);
      expect(state.filteredMeals.every((m) => m.categoryId == 'catA'), isTrue);
    });

    // -----------------------------------------------------------------------
    // 2. Filter by availability
    // -----------------------------------------------------------------------
    test('availableOnly hides unavailable meals', () async {
      final meals = [
        makeMeal(id: '1', isAvailable: true),
        makeMeal(id: '2', isAvailable: false),
        makeMeal(id: '3', isAvailable: true),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applyFilter(
        const MealFilter(
          categoryIds: [],
          availableOnly: true,
          dietaryTags: [],
        ),
      );

      final state = container.read(catalogNotifierProvider).value!;
      expect(state.filteredMeals.length, 2);
      expect(state.filteredMeals.every((m) => m.isAvailable), isTrue);
    });

    // -----------------------------------------------------------------------
    // 3. Filter by price range
    // -----------------------------------------------------------------------
    test('price range filter returns only meals within bounds', () async {
      final meals = [
        makeMeal(id: '1', price: 500),
        makeMeal(id: '2', price: 2000),
        makeMeal(id: '3', price: 4500),
        makeMeal(id: '4', price: 6000),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applyFilter(
        const MealFilter(
          categoryIds: [],
          minPrice: 1000,
          maxPrice: 5000,
          availableOnly: false,
          dietaryTags: [],
        ),
      );

      final state = container.read(catalogNotifierProvider).value!;
      expect(state.filteredMeals.length, 2);
      expect(
        state.filteredMeals.every((m) => m.price >= 1000 && m.price <= 5000),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // 4a. Filter by single dietary tag
    // -----------------------------------------------------------------------
    test('filter by single dietary tag returns only matching meals', () async {
      final meals = [
        makeMeal(id: '1', dietaryTags: ['vegetarian']),
        makeMeal(id: '2', dietaryTags: ['halal']),
        makeMeal(id: '3', dietaryTags: ['vegetarian', 'halal']),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applyFilter(
        const MealFilter(
          categoryIds: [],
          availableOnly: false,
          dietaryTags: ['vegetarian'],
        ),
      );

      final state = container.read(catalogNotifierProvider).value!;
      expect(state.filteredMeals.length, 2);
      expect(
        state.filteredMeals
            .every((m) => m.dietaryTags.contains('vegetarian')),
        isTrue,
      );
    });

    // -----------------------------------------------------------------------
    // 4b. Filter by multiple dietary tags (AND semantics)
    // -----------------------------------------------------------------------
    test(
        'filter by multiple dietary tags requires ALL tags (AND semantics)',
        () async {
      final meals = [
        makeMeal(id: '1', dietaryTags: ['vegetarian']),
        makeMeal(id: '2', dietaryTags: ['halal']),
        makeMeal(id: '3', dietaryTags: ['vegetarian', 'halal']),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applyFilter(
        const MealFilter(
          categoryIds: [],
          availableOnly: false,
          dietaryTags: ['vegetarian', 'halal'],
        ),
      );

      final state = container.read(catalogNotifierProvider).value!;
      expect(state.filteredMeals.length, 1);
      expect(state.filteredMeals.first.id, '3');
    });

    // -----------------------------------------------------------------------
    // 5. Clear filter
    // -----------------------------------------------------------------------
    test('clearFilter restores all meals', () async {
      final meals = [
        makeMeal(id: '1', categoryId: 'catA'),
        makeMeal(id: '2', categoryId: 'catB'),
        makeMeal(id: '3', categoryId: 'catA'),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);

      // Apply a filter first.
      notifier.applyFilter(
        const MealFilter(
          categoryIds: ['catA'],
          availableOnly: false,
          dietaryTags: [],
        ),
      );
      expect(
        container.read(catalogNotifierProvider).value!.filteredMeals.length,
        2,
      );

      // Clear the filter.
      notifier.clearFilter();

      final state = container.read(catalogNotifierProvider).value!;
      expect(state.filteredMeals.length, 3);
    });

    // -----------------------------------------------------------------------
    // 6. Sort by price ascending
    // -----------------------------------------------------------------------
    test('sort by priceAsc orders meals cheapest first', () async {
      final meals = [
        makeMeal(id: '1', price: 3000),
        makeMeal(id: '2', price: 1000),
        makeMeal(id: '3', price: 2000),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applySort(MealSortOption.priceAsc);

      final filtered =
          container.read(catalogNotifierProvider).value!.filteredMeals;
      expect(filtered[0].price, 1000);
      expect(filtered[1].price, 2000);
      expect(filtered[2].price, 3000);
    });

    // -----------------------------------------------------------------------
    // 7. Sort by price descending
    // -----------------------------------------------------------------------
    test('sort by priceDesc orders meals most expensive first', () async {
      final meals = [
        makeMeal(id: '1', price: 3000),
        makeMeal(id: '2', price: 1000),
        makeMeal(id: '3', price: 2000),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applySort(MealSortOption.priceDesc);

      final filtered =
          container.read(catalogNotifierProvider).value!.filteredMeals;
      expect(filtered[0].price, 3000);
      expect(filtered[1].price, 2000);
      expect(filtered[2].price, 1000);
    });

    // -----------------------------------------------------------------------
    // 8. Sort by popularity
    // -----------------------------------------------------------------------
    test('sort by popularityDesc orders meals by popularityScore descending',
        () async {
      final meals = [
        makeMeal(id: '1', popularityScore: 10),
        makeMeal(id: '2', popularityScore: 50),
        makeMeal(id: '3', popularityScore: 30),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applySort(MealSortOption.popularityDesc);

      final filtered =
          container.read(catalogNotifierProvider).value!.filteredMeals;
      expect(filtered[0].popularityScore, 50);
      expect(filtered[1].popularityScore, 30);
      expect(filtered[2].popularityScore, 10);
    });

    // -----------------------------------------------------------------------
    // 9. Sort by newest
    // -----------------------------------------------------------------------
    test('sort by newestFirst orders meals by createdAt descending', () async {
      final meals = [
        makeMeal(id: '1', createdAt: DateTime(2024, 1, 1)),
        makeMeal(id: '2', createdAt: DateTime(2024, 3, 1)),
        makeMeal(id: '3', createdAt: DateTime(2024, 2, 1)),
      ];

      final container = makeContainer(meals);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);
      notifier.applySort(MealSortOption.newestFirst);

      final filtered =
          container.read(catalogNotifierProvider).value!.filteredMeals;
      expect(filtered[0].id, '2'); // March
      expect(filtered[1].id, '3'); // February
      expect(filtered[2].id, '1'); // January
    });

    // -----------------------------------------------------------------------
    // 10. Active filter count
    // -----------------------------------------------------------------------
    test('activeFilterCount returns correct count for various combinations',
        () async {
      final container = makeContainer([]);
      addTearDown(container.dispose);

      final notifier = await loadedNotifier(container);

      // No filter active.
      expect(
        container.read(catalogNotifierProvider).value!.activeFilterCount,
        0,
      );

      // One criterion: availableOnly.
      notifier.applyFilter(
        const MealFilter(
          categoryIds: [],
          availableOnly: true,
          dietaryTags: [],
        ),
      );
      expect(
        container.read(catalogNotifierProvider).value!.activeFilterCount,
        1,
      );

      // Three criteria: category + minPrice + availableOnly.
      notifier.applyFilter(
        const MealFilter(
          categoryIds: ['catA'],
          minPrice: 1000,
          availableOnly: true,
          dietaryTags: [],
        ),
      );
      expect(
        container.read(catalogNotifierProvider).value!.activeFilterCount,
        3,
      );

      // Five criteria: all fields active.
      notifier.applyFilter(
        const MealFilter(
          categoryIds: ['catA'],
          minPrice: 500,
          maxPrice: 5000,
          availableOnly: true,
          dietaryTags: ['vegetarian'],
        ),
      );
      expect(
        container.read(catalogNotifierProvider).value!.activeFilterCount,
        5,
      );

      // Back to zero after clear.
      notifier.clearFilter();
      expect(
        container.read(catalogNotifierProvider).value!.activeFilterCount,
        0,
      );
    });
  });
}
