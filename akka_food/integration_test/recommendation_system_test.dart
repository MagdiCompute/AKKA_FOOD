// integration_test/recommendation_system_test.dart
//
// Tasks 8.1–8.5 — Recommendation System integration tests.
//
// Tests the RecommendedSection widget using ProviderScope overrides so no
// real Firebase / Hive connection is needed. Follows the same pattern as
// cart_flow_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/hive_catalog_cache.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/meal_catalog/presentation/widgets/recommended_section.dart';
import 'package:akka_food/features/recommendation_system/domain/entities/recommendation_result.dart';
import 'package:akka_food/features/recommendation_system/domain/repositories/i_recommendation_repository.dart';
import 'package:akka_food/features/recommendation_system/presentation/notifiers/recommendation_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

Meal _testMeal({
  required String id,
  String name = 'Test Meal',
  bool isAvailable = true,
}) =>
    Meal(
      id: id,
      name: name,
      description: 'Delicious meal',
      price: 2500.0,
      categoryId: 'cat-1',
      imageUrls: const ['https://example.com/img.jpg'],
      isAvailable: isAvailable,
      isFeatured: false,
      featuredOrder: 0,
      nutritionalInfo: null,
      dietaryTags: const [],
      popularityScore: 10,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

// =============================================================================
// Fake implementations
// =============================================================================

/// Fake recommendation repository that returns configurable results.
class FakeRecommendationRepository implements IRecommendationRepository {
  FakeRecommendationRepository({
    required this.result,
  });

  RecommendationResult result;

  @override
  Future<RecommendationResult> getRecommendations({
    required String userId,
  }) async {
    return result;
  }
}

/// Fake recommendation repository that throws an exception.
class ErrorRecommendationRepository implements IRecommendationRepository {
  @override
  Future<RecommendationResult> getRecommendations({
    required String userId,
  }) async {
    throw Exception('Recommendation engine unavailable');
  }
}

/// Fake recommendation repository that returns different results on
/// successive calls (used for cache invalidation test).
class MutableFakeRecommendationRepository
    implements IRecommendationRepository {
  MutableFakeRecommendationRepository({
    required this.firstResult,
    required this.secondResult,
  });

  final RecommendationResult firstResult;
  final RecommendationResult secondResult;
  int _callCount = 0;

  @override
  Future<RecommendationResult> getRecommendations({
    required String userId,
  }) async {
    _callCount++;
    return _callCount <= 1 ? firstResult : secondResult;
  }
}

/// Fake catalog cache that returns a pre-configured list of meals.
class FakeHiveCatalogCache extends HiveCatalogCache {
  FakeHiveCatalogCache({required this.meals});

  final List<Meal> meals;

  @override
  Future<List<Meal>?> getCachedMeals() async => meals;
}

// =============================================================================
// Helper — builds RecommendedSection wrapped in ProviderScope with overrides
// =============================================================================

Widget _buildRecommendationApp({
  required AppUser user,
  required IRecommendationRepository repository,
  required HiveCatalogCache catalogCache,
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(
          body: SingleChildScrollView(
            child: RecommendedSection(),
          ),
        ),
      ),
      GoRoute(
        path: '/meals/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Meal Detail: ${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => user),
      recommendationRepositoryProvider.overrideWith((_) => repository),
      catalogCacheProvider.overrideWith((_) => catalogCache),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // 8.1 — User with ≥ 3 orders sees personalized recommendations
  // ---------------------------------------------------------------------------
  testWidgets(
    '8.1 user with ≥ 3 orders sees personalized recommendations',
    (WidgetTester tester) async {
      final mealIds = ['meal-1', 'meal-2', 'meal-3', 'meal-4', 'meal-5'];
      final meals = mealIds
          .map((id) => _testMeal(id: id, name: 'Meal $id'))
          .toList();

      final repository = FakeRecommendationRepository(
        result: RecommendationResult(
          mealIds: mealIds,
          isPersonalized: true,
          computedAt: DateTime(2024, 6, 1),
        ),
      );

      final catalogCache = FakeHiveCatalogCache(meals: meals);

      await tester.pumpWidget(_buildRecommendationApp(
        user: _fakeUser(),
        repository: repository,
        catalogCache: catalogCache,
      ));
      await tester.pumpAndSettle();

      // Verify header is visible.
      expect(find.text('Recommended for You'), findsOneWidget);

      // Verify personalized badge is shown.
      expect(find.text('✨ Personalized'), findsOneWidget);

      // Verify 5 meal cards are rendered.
      expect(find.byType(InkWell), findsNWidgets(5));
    },
  );

  // ---------------------------------------------------------------------------
  // 8.2 — New user sees popularity-based recommendations
  // ---------------------------------------------------------------------------
  testWidgets(
    '8.2 new user sees popularity-based recommendations',
    (WidgetTester tester) async {
      final mealIds = ['meal-1', 'meal-2', 'meal-3', 'meal-4', 'meal-5'];
      final meals = mealIds
          .map((id) => _testMeal(id: id, name: 'Meal $id'))
          .toList();

      final repository = FakeRecommendationRepository(
        result: RecommendationResult(
          mealIds: mealIds,
          isPersonalized: false,
          computedAt: DateTime(2024, 6, 1),
        ),
      );

      final catalogCache = FakeHiveCatalogCache(meals: meals);

      await tester.pumpWidget(_buildRecommendationApp(
        user: _fakeUser(),
        repository: repository,
        catalogCache: catalogCache,
      ));
      await tester.pumpAndSettle();

      // Verify header is visible.
      expect(find.text('Recommended for You'), findsOneWidget);

      // Verify popular badge is shown (not personalized).
      expect(find.text('🔥 Popular'), findsOneWidget);

      // Verify meal cards are rendered.
      expect(find.byType(InkWell), findsWidgets);
    },
  );

  // ---------------------------------------------------------------------------
  // 8.3 — Recommendations refresh after new order (cache invalidated)
  // ---------------------------------------------------------------------------
  testWidgets(
    '8.3 recommendations refresh after new order (cache invalidated)',
    (WidgetTester tester) async {
      final initialMealIds = ['meal-1', 'meal-2', 'meal-3'];
      final refreshedMealIds = ['meal-4', 'meal-5', 'meal-6'];

      final allMeals = [
        ...initialMealIds.map((id) => _testMeal(id: id, name: 'Initial $id')),
        ...refreshedMealIds.map((id) => _testMeal(id: id, name: 'New $id')),
      ];

      final repository = MutableFakeRecommendationRepository(
        firstResult: RecommendationResult(
          mealIds: initialMealIds,
          isPersonalized: true,
          computedAt: DateTime(2024, 6, 1),
        ),
        secondResult: RecommendationResult(
          mealIds: refreshedMealIds,
          isPersonalized: true,
          computedAt: DateTime(2024, 6, 2),
        ),
      );

      final catalogCache = FakeHiveCatalogCache(meals: allMeals);

      await tester.pumpWidget(_buildRecommendationApp(
        user: _fakeUser(),
        repository: repository,
        catalogCache: catalogCache,
      ));
      await tester.pumpAndSettle();

      // Verify initial meals are shown.
      expect(find.text('Initial meal-1'), findsOneWidget);
      expect(find.text('Initial meal-2'), findsOneWidget);
      expect(find.text('Initial meal-3'), findsOneWidget);

      // Trigger a refresh (simulates cache invalidation after new order).
      final element = tester.element(find.byType(RecommendedSection));
      final container = ProviderScope.containerOf(element);
      await container
          .read(recommendationNotifierProvider.notifier)
          .loadRecommendations();
      await tester.pumpAndSettle();

      // Verify new meals appear after refresh.
      expect(find.text('New meal-4'), findsOneWidget);
      expect(find.text('New meal-5'), findsOneWidget);
      expect(find.text('New meal-6'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------------
  // 8.4 — Unavailable meal excluded from recommendations
  // ---------------------------------------------------------------------------
  testWidgets(
    '8.4 unavailable meal excluded from recommendations',
    (WidgetTester tester) async {
      final mealIds = ['meal-1', 'meal-2', 'meal-3', 'meal-4', 'meal-5'];
      final meals = [
        _testMeal(id: 'meal-1', name: 'Available 1', isAvailable: true),
        _testMeal(id: 'meal-2', name: 'Unavailable 1', isAvailable: false),
        _testMeal(id: 'meal-3', name: 'Available 2', isAvailable: true),
        _testMeal(id: 'meal-4', name: 'Unavailable 2', isAvailable: false),
        _testMeal(id: 'meal-5', name: 'Available 3', isAvailable: true),
      ];

      final repository = FakeRecommendationRepository(
        result: RecommendationResult(
          mealIds: mealIds,
          isPersonalized: true,
          computedAt: DateTime(2024, 6, 1),
        ),
      );

      final catalogCache = FakeHiveCatalogCache(meals: meals);

      await tester.pumpWidget(_buildRecommendationApp(
        user: _fakeUser(),
        repository: repository,
        catalogCache: catalogCache,
      ));
      await tester.pumpAndSettle();

      // Verify only 3 available meals are shown.
      expect(find.text('Available 1'), findsOneWidget);
      expect(find.text('Available 2'), findsOneWidget);
      expect(find.text('Available 3'), findsOneWidget);

      // Verify unavailable meals are NOT shown.
      expect(find.text('Unavailable 1'), findsNothing);
      expect(find.text('Unavailable 2'), findsNothing);

      // Verify exactly 3 meal cards are rendered.
      expect(find.byType(InkWell), findsNWidgets(3));
    },
  );

  // ---------------------------------------------------------------------------
  // 8.5 — Recommendation engine error → section hidden silently
  // ---------------------------------------------------------------------------
  testWidgets(
    '8.5 recommendation engine error → section hidden silently',
    (WidgetTester tester) async {
      final repository = ErrorRecommendationRepository();
      // Catalog cache doesn't matter since the repository will throw.
      final catalogCache = FakeHiveCatalogCache(meals: []);

      await tester.pumpWidget(_buildRecommendationApp(
        user: _fakeUser(),
        repository: repository,
        catalogCache: catalogCache,
      ));
      await tester.pumpAndSettle();

      // Verify the section is hidden (no header visible).
      expect(find.text('Recommended for You'), findsNothing);

      // Verify no error message is shown to the user.
      expect(find.text('Error'), findsNothing);
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    },
  );
}
