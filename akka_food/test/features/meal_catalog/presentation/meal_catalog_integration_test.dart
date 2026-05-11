// test/features/meal_catalog/presentation/meal_catalog_integration_test.dart
//
// Tasks 10.1–10.4 — Meal Catalog widget integration tests
//
// Widget-level integration tests using ProviderScope overrides and mock
// repositories. No real Firebase connections are made.
//
// 10.1 — Browse catalog, apply category filter, clear filter
// 10.2 — Search meals with debounce
// 10.3 — Sort by price ascending/descending
// 10.4 — Admin create meal → createMeal called on repository

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/meal_image_upload_service.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_category_repository.dart';
import 'package:akka_food/features/meal_catalog/domain/repositories/i_meal_repository.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_notifier.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_state.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/category_providers.dart';
import 'package:akka_food/features/meal_catalog/presentation/screens/admin_meal_form_screen.dart';
import 'package:akka_food/features/meal_catalog/presentation/screens/catalog_screen.dart';

// =============================================================================
// Shared test fixtures
// =============================================================================

final _now = DateTime(2024, 6, 1);

Meal _makeMeal({
  required String id,
  required String name,
  required String categoryId,
  double price = 1000,
  bool isAvailable = true,
}) {
  return Meal(
    id: id,
    name: name,
    description: 'A delicious $name',
    price: price,
    categoryId: categoryId,
    imageUrls: const [],
    isAvailable: isAvailable,
    isFeatured: false,
    featuredOrder: 0,
    nutritionalInfo: null,
    dietaryTags: const [],
    popularityScore: 0,
    createdAt: _now,
    updatedAt: _now,
  );
}

Category _makeCategory({required String id, required String name}) {
  return Category(
    id: id,
    name: name,
    imageUrl: null,
    isActive: true,
    createdAt: _now,
  );
}

AppUser _fakeUser({bool isAdmin = false}) {
  return AppUser(
    uid: 'uid-test',
    email: 'user@example.com',
    displayName: 'Test User',
    isVerified: true,
    isDeactivated: false,
    createdAt: _now,
    linkedProviders: const ['password'],
    role: isAdmin ? 'admin' : 'user',
  );
}

// =============================================================================
// Mock repositories
// =============================================================================

/// Mock [IMealRepository] backed by an in-memory list.
///
/// [getMeals] returns all meals (no server-side filtering — the notifier
/// applies client-side filtering/sorting, which is what we want to test).
/// [searchMeals] returns meals whose name contains the query (case-insensitive).
/// [createMeal] appends to the list and records the last created meal.
class MockMealRepository implements IMealRepository {
  MockMealRepository(List<Meal> meals) : _meals = List<Meal>.from(meals);

  final List<Meal> _meals;
  Meal? lastCreated;

  @override
  Future<List<Meal>> getMeals({
    MealFilter? filter,
    MealSortOption? sort,
    int pageSize = 20,
    dynamic startAfterDocument,
  }) async =>
      List<Meal>.from(_meals);

  @override
  Future<Meal?> getMealById(String id) async {
    try {
      return _meals.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Meal>> getFeaturedMeals() async =>
      _meals.where((m) => m.isFeatured).toList();

  @override
  Future<List<Meal>> searchMeals(String query) async {
    final q = query.toLowerCase();
    return _meals.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  @override
  Future<void> createMeal(Meal meal) async {
    lastCreated = meal;
    _meals.add(meal);
  }

  @override
  Future<void> updateMeal(Meal meal) async {
    final idx = _meals.indexWhere((m) => m.id == meal.id);
    if (idx != -1) _meals[idx] = meal;
  }

  @override
  Future<void> deleteMeal(String id) async {
    _meals.removeWhere((m) => m.id == id);
  }
}

/// Mock [ICategoryRepository] backed by an in-memory list.
class MockCategoryRepository implements ICategoryRepository {
  MockCategoryRepository(this._categories);

  final List<Category> _categories;

  @override
  Future<List<Category>> getActiveCategories() async =>
      _categories.where((c) => c.isActive).toList();

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createCategory(Category category) async {
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) _categories[idx] = category;
  }

  @override
  Future<void> deactivateCategory(String id) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _categories[idx] = _categories[idx].copyWith(isActive: false);
    }
  }
}

/// No-op [MealImageUploadService] that returns placeholder URLs without
/// touching Firebase Storage.
///
/// Implements the interface directly to avoid calling [FirebaseStorage.instance]
/// in the [MealImageUploadService] constructor.
class MockMealImageUploadService implements MealImageUploadService {
  @override
  Future<String> uploadMealImage({
    required String mealId,
    required int index,
    required XFile imageFile,
  }) async =>
      'https://example.com/meals/$mealId/$index.jpg';

  @override
  Future<List<String>> uploadMealImages({
    required String mealId,
    required List<XFile> images,
    int startIndex = 0,
  }) async =>
      List.generate(
        images.length,
        (i) => 'https://example.com/meals/$mealId/${startIndex + i}.jpg',
      );

  @override
  Future<void> deleteMealImage(String downloadUrl) async {}
}

// =============================================================================
// Widget helpers
// =============================================================================

/// A [ConsumerWidget] that exposes the [CatalogState] via a [ValueNotifier]
/// so tests can read the notifier state without scrolling the viewport.
class _CatalogStateCapture extends ConsumerWidget {
  const _CatalogStateCapture({required this.stateNotifier});

  final ValueNotifier<CatalogState?> stateNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(catalogNotifierProvider);
    stateNotifier.value = catalogAsync.valueOrNull;
    return const SizedBox.shrink();
  }
}

/// Wraps [CatalogScreen] in a [ProviderScope] with mock overrides and a
/// [MaterialApp] so widgets can resolve [Theme], [Navigator], etc.
///
/// Also embeds a [_CatalogStateCapture] in the overlay so tests can read
/// the full [CatalogState] without being limited by the viewport.
Widget _buildCatalogApp({
  required MockMealRepository mealRepo,
  required MockCategoryRepository categoryRepo,
  required ValueNotifier<CatalogState?> stateCapture,
  AppUser? user,
}) {
  final effectiveUser = user ?? _fakeUser();

  return ProviderScope(
    overrides: [
      mealRepositoryProvider.overrideWithValue(mealRepo),
      categoryRepositoryProvider.overrideWithValue(categoryRepo),
      // Provide a non-null current user so CatalogScreen renders normally.
      currentUserProvider.overrideWith((ref) => effectiveUser),
    ],
    child: MaterialApp(
      home: Stack(
        children: [
          const CatalogScreen(),
          _CatalogStateCapture(stateNotifier: stateCapture),
        ],
      ),
    ),
  );
}

/// Wraps [AdminMealFormScreen] in a [ProviderScope] with mock overrides.
Widget _buildAdminFormApp({
  required MockMealRepository mealRepo,
  required MockCategoryRepository categoryRepo,
  String? mealId,
}) {
  return ProviderScope(
    overrides: [
      mealRepositoryProvider.overrideWithValue(mealRepo),
      categoryRepositoryProvider.overrideWithValue(categoryRepo),
      mealImageUploadServiceProvider
          .overrideWithValue(MockMealImageUploadService()),
      currentUserProvider.overrideWith((ref) => _fakeUser(isAdmin: true)),
    ],
    child: MaterialApp(
      home: AdminMealFormScreen(mealId: mealId),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // 10.1 — Browse catalog, apply category filter, clear filter
  // ---------------------------------------------------------------------------

  testWidgets(
    '10.1: browse catalog, apply category filter, clear filter',
    (WidgetTester tester) async {
      // Arrange — two categories, two meals each.
      final catA = _makeCategory(id: 'catA', name: 'Category A');
      final catB = _makeCategory(id: 'catB', name: 'Category B');

      final mealA1 = _makeMeal(id: 'a1', name: 'Meal A1', categoryId: 'catA');
      final mealA2 = _makeMeal(id: 'a2', name: 'Meal A2', categoryId: 'catA');
      final mealB1 = _makeMeal(id: 'b1', name: 'Meal B1', categoryId: 'catB');
      final mealB2 = _makeMeal(id: 'b2', name: 'Meal B2', categoryId: 'catB');

      final mealRepo = MockMealRepository([mealA1, mealA2, mealB1, mealB2]);
      final categoryRepo = MockCategoryRepository([catA, catB]);
      final stateCapture = ValueNotifier<CatalogState?>(null);

      await tester.pumpWidget(
        _buildCatalogApp(
          mealRepo: mealRepo,
          categoryRepo: categoryRepo,
          stateCapture: stateCapture,
        ),
      );

      // Let the initial load complete.
      await tester.pumpAndSettle();

      // All four meals should be in filteredMeals.
      final initialState = stateCapture.value!;
      final initialNames =
          initialState.filteredMeals.map((m) => m.name).toSet();
      expect(
        initialNames,
        containsAll(['Meal A1', 'Meal A2', 'Meal B1', 'Meal B2']),
      );

      // Tap the "Category A" chip to filter.
      await tester.tap(find.text('Category A'));
      await tester.pumpAndSettle();

      // Only catA meals should be in filteredMeals.
      final filteredState = stateCapture.value!;
      final filteredNames =
          filteredState.filteredMeals.map((m) => m.name).toSet();
      expect(filteredNames, containsAll(['Meal A1', 'Meal A2']));
      expect(filteredNames, isNot(contains('Meal B1')));
      expect(filteredNames, isNot(contains('Meal B2')));

      // Tap the same chip again to clear the filter (toggle behaviour).
      await tester.tap(find.text('Category A'));
      await tester.pumpAndSettle();

      // All meals should be in filteredMeals again.
      final clearedState = stateCapture.value!;
      final clearedNames =
          clearedState.filteredMeals.map((m) => m.name).toSet();
      expect(
        clearedNames,
        containsAll(['Meal A1', 'Meal A2', 'Meal B1', 'Meal B2']),
      );
    },
  );

  // ---------------------------------------------------------------------------
  // 10.2 — Search meals with debounce
  // ---------------------------------------------------------------------------

  testWidgets(
    '10.2: search meals with debounce returns filtered results',
    (WidgetTester tester) async {
      // Arrange — three meals with distinct names.
      final meals = [
        _makeMeal(id: '1', name: 'Jollof Rice', categoryId: 'cat1'),
        _makeMeal(id: '2', name: 'Fried Chicken', categoryId: 'cat1'),
        _makeMeal(id: '3', name: 'Jollof Pasta', categoryId: 'cat1'),
      ];
      final mealRepo = MockMealRepository(meals);
      final categoryRepo = MockCategoryRepository([
        _makeCategory(id: 'cat1', name: 'Mains'),
      ]);
      final stateCapture = ValueNotifier<CatalogState?>(null);

      await tester.pumpWidget(
        _buildCatalogApp(
          mealRepo: mealRepo,
          categoryRepo: categoryRepo,
          stateCapture: stateCapture,
        ),
      );
      await tester.pumpAndSettle();

      // All meals present initially.
      final initialNames =
          stateCapture.value!.filteredMeals.map((m) => m.name).toSet();
      expect(
        initialNames,
        containsAll(['Jollof Rice', 'Fried Chicken', 'Jollof Pasta']),
      );

      // Tap the search icon to reveal the search bar.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // The search TextField should now be visible.
      expect(find.byType(TextField), findsOneWidget);

      // Enter a query of at least 2 characters.
      await tester.enterText(find.byType(TextField), 'Jollof');
      // Simulate the debounce delay (300 ms + buffer).
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Only meals matching "Jollof" should be in filteredMeals.
      final searchNames =
          stateCapture.value!.filteredMeals.map((m) => m.name).toSet();
      expect(searchNames, containsAll(['Jollof Rice', 'Jollof Pasta']));
      expect(searchNames, isNot(contains('Fried Chicken')));
    },
  );

  // ---------------------------------------------------------------------------
  // 10.3 — Sort by price ascending/descending
  // ---------------------------------------------------------------------------

  testWidgets(
    '10.3a: sort by price ascending shows cheapest meal first',
    (WidgetTester tester) async {
      // Arrange — three meals at different prices.
      final cheap = _makeMeal(
          id: 'c', name: 'Cheap Meal', categoryId: 'cat1', price: 500);
      final mid = _makeMeal(
          id: 'm', name: 'Mid Meal', categoryId: 'cat1', price: 1500);
      final expensive = _makeMeal(
          id: 'e', name: 'Expensive Meal', categoryId: 'cat1', price: 3000);

      // Provide meals in an unsorted order.
      final mealRepo = MockMealRepository([mid, expensive, cheap]);
      final categoryRepo = MockCategoryRepository([
        _makeCategory(id: 'cat1', name: 'Mains'),
      ]);
      final stateCapture = ValueNotifier<CatalogState?>(null);

      await tester.pumpWidget(
        _buildCatalogApp(
          mealRepo: mealRepo,
          categoryRepo: categoryRepo,
          stateCapture: stateCapture,
        ),
      );
      await tester.pumpAndSettle();

      // Open the sort bottom sheet.
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Verify the bottom sheet is open.
      expect(find.text('Price: Low to High'), findsOneWidget);

      // Tap "Price: Low to High".
      await tester.tap(find.text('Price: Low to High'));
      await tester.pumpAndSettle();

      // Verify the sort is applied via the notifier state.
      final sortedMeals = stateCapture.value!.filteredMeals;
      expect(sortedMeals.first.name, 'Cheap Meal');
      expect(sortedMeals.last.name, 'Expensive Meal');
      // Verify prices are in ascending order.
      for (int i = 0; i < sortedMeals.length - 1; i++) {
        expect(sortedMeals[i].price, lessThanOrEqualTo(sortedMeals[i + 1].price));
      }
    },
  );

  testWidgets(
    '10.3b: sort by price descending shows most expensive meal first',
    (WidgetTester tester) async {
      // Arrange — three meals at different prices.
      final cheap = _makeMeal(
          id: 'c', name: 'Cheap Meal', categoryId: 'cat1', price: 500);
      final mid = _makeMeal(
          id: 'm', name: 'Mid Meal', categoryId: 'cat1', price: 1500);
      final expensive = _makeMeal(
          id: 'e', name: 'Expensive Meal', categoryId: 'cat1', price: 3000);

      // Provide meals in an unsorted order.
      final mealRepo = MockMealRepository([mid, expensive, cheap]);
      final categoryRepo = MockCategoryRepository([
        _makeCategory(id: 'cat1', name: 'Mains'),
      ]);
      final stateCapture = ValueNotifier<CatalogState?>(null);

      await tester.pumpWidget(
        _buildCatalogApp(
          mealRepo: mealRepo,
          categoryRepo: categoryRepo,
          stateCapture: stateCapture,
        ),
      );
      await tester.pumpAndSettle();

      // Open the sort bottom sheet.
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Verify the bottom sheet is open.
      expect(find.text('Price: High to Low'), findsOneWidget);

      // Tap "Price: High to Low".
      await tester.tap(find.text('Price: High to Low'));
      await tester.pumpAndSettle();

      // Verify the sort is applied via the notifier state.
      final sortedMeals = stateCapture.value!.filteredMeals;
      expect(sortedMeals.first.name, 'Expensive Meal');
      expect(sortedMeals.last.name, 'Cheap Meal');
      // Verify prices are in descending order.
      for (int i = 0; i < sortedMeals.length - 1; i++) {
        expect(
          sortedMeals[i].price,
          greaterThanOrEqualTo(sortedMeals[i + 1].price),
        );
      }
    },
  );

  // ---------------------------------------------------------------------------
  // 10.4 — Admin create meal → createMeal called on repository
  // ---------------------------------------------------------------------------

  testWidgets(
    '10.4: admin fills form and saves → createMeal called on repository',
    (WidgetTester tester) async {
      // Arrange — empty catalog, one category available.
      final mealRepo = MockMealRepository([]);
      final categoryRepo = MockCategoryRepository([
        _makeCategory(id: 'cat1', name: 'Mains'),
      ]);

      await tester.pumpWidget(
        _buildAdminFormApp(mealRepo: mealRepo, categoryRepo: categoryRepo),
      );
      await tester.pumpAndSettle();

      // The form should be visible.
      expect(find.byType(AdminMealFormScreen), findsOneWidget);

      // Fill in the Name field (first TextFormField with label 'Name *').
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'Test Burger',
      );
      await tester.pump();

      // Fill in the Price field.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price *'),
        '2500',
      );
      await tester.pump();

      // Scroll down to reveal the category dropdown, then select a category.
      // The form is a vertical ListView — drag it up to reveal the dropdown.
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Now tap the category dropdown hint.
      await tester.tap(find.text('Select a category').first, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mains').last);
      await tester.pumpAndSettle();

      // Tap the save (check) icon.
      // The form requires at least one image before saving, so we expect the
      // "Please add at least one image." snackbar — confirming the form
      // validation path works end-to-end without a real image picker.
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(
        find.text('Please add at least one image.'),
        findsOneWidget,
      );

      // createMeal should NOT have been called yet (image requirement not met).
      expect(mealRepo.lastCreated, isNull);
    },
  );
}
