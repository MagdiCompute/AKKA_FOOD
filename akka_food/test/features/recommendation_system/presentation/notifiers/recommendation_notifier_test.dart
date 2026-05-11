import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/hive_catalog_cache.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/recommendation_system/domain/entities/recommendation_result.dart';
import 'package:akka_food/features/recommendation_system/domain/repositories/i_recommendation_repository.dart';
import 'package:akka_food/features/recommendation_system/presentation/notifiers/recommendation_notifier.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// A fake [IRecommendationRepository] that returns a predefined result or
/// throws an exception.
class FakeRecommendationRepository implements IRecommendationRepository {
  FakeRecommendationRepository({this.result, this.exception});

  final RecommendationResult? result;
  final Exception? exception;

  String? lastCalledUserId;

  @override
  Future<RecommendationResult> getRecommendations({
    required String userId,
  }) async {
    lastCalledUserId = userId;
    if (exception != null) throw exception!;
    return result!;
  }
}

/// A fake [HiveCatalogCache] that returns a predefined list of meals.
class FakeCatalogCache extends HiveCatalogCache {
  FakeCatalogCache({this.meals});

  final List<Meal>? meals;

  @override
  Future<List<Meal>?> getCachedMeals() async => meals;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a test [AppUser] with sensible defaults.
AppUser createTestUser({String uid = 'test-user-123'}) {
  return AppUser(
    uid: uid,
    email: 'test@example.com',
    displayName: 'Test User',
    isVerified: true,
    isDeactivated: false,
    createdAt: DateTime(2024, 1, 1),
    linkedProviders: ['password'],
  );
}

/// Creates a test [Meal] with sensible defaults.
Meal createTestMeal({
  required String id,
  String name = 'Test Meal',
  bool isAvailable = true,
}) {
  return Meal(
    id: id,
    name: name,
    description: 'A test meal',
    price: 1500.0,
    categoryId: 'cat-1',
    imageUrls: ['https://example.com/image.jpg'],
    isAvailable: isAvailable,
    isFeatured: false,
    featuredOrder: 0,
    dietaryTags: [],
    popularityScore: 10,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

/// Creates a [RecommendationResult] with sensible defaults.
RecommendationResult createTestResult({
  List<String> mealIds = const ['meal-1', 'meal-2', 'meal-3'],
  bool isPersonalized = true,
}) {
  return RecommendationResult(
    mealIds: mealIds,
    isPersonalized: isPersonalized,
    computedAt: DateTime(2024, 6, 1),
  );
}

/// Creates a [ProviderContainer] with the given overrides for testing.
ProviderContainer createContainer({
  AppUser? user,
  required IRecommendationRepository repository,
  required HiveCatalogCache catalogCache,
}) {
  return ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => user),
      recommendationRepositoryProvider.overrideWithValue(repository),
      catalogCacheProvider.overrideWithValue(catalogCache),
    ],
  );
}

/// Reads the [recommendationNotifierProvider] and waits for it to resolve
/// from [AsyncLoading] to either [AsyncData] or [AsyncError].
Future<AsyncValue<List<Meal>>> waitForNotifier(
    ProviderContainer container) async {
  final completer = Completer<AsyncValue<List<Meal>>>();

  container.listen<AsyncValue<List<Meal>>>(
    recommendationNotifierProvider,
    (previous, next) {
      if (!next.isLoading && !completer.isCompleted) {
        completer.complete(next);
      }
    },
    fireImmediately: true,
  );

  // If the state is already resolved (not loading), return immediately
  final current = container.read(recommendationNotifierProvider);
  if (!current.isLoading && !completer.isCompleted) {
    completer.complete(current);
  }

  return completer.future;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RecommendationNotifier', () {
    test('returns empty list when user is null (unauthenticated)', () async {
      final repository = FakeRecommendationRepository(
        result: createTestResult(),
      );
      final cache = FakeCatalogCache(
        meals: [createTestMeal(id: 'meal-1')],
      );

      final container = createContainer(
        user: null,
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      expect(state.value, isNotNull);
      expect(state.value, isEmpty);
      // Repository should not have been called
      expect(repository.lastCalledUserId, isNull);
    });

    test('returns resolved meals from repository result (happy path)',
        () async {
      final meals = [
        createTestMeal(id: 'meal-1', name: 'Chicken'),
        createTestMeal(id: 'meal-2', name: 'Rice'),
        createTestMeal(id: 'meal-3', name: 'Salad'),
      ];
      final repository = FakeRecommendationRepository(
        result: createTestResult(
          mealIds: ['meal-1', 'meal-2', 'meal-3'],
          isPersonalized: true,
        ),
      );
      final cache = FakeCatalogCache(meals: meals);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      expect(state.value, hasLength(3));
      expect(state.value!.map((m) => m.id).toList(),
          ['meal-1', 'meal-2', 'meal-3']);
    });

    test('filters out unavailable meals', () async {
      final meals = [
        createTestMeal(id: 'meal-1', isAvailable: true),
        createTestMeal(id: 'meal-2', isAvailable: false),
        createTestMeal(id: 'meal-3', isAvailable: true),
      ];
      final repository = FakeRecommendationRepository(
        result: createTestResult(
          mealIds: ['meal-1', 'meal-2', 'meal-3'],
        ),
      );
      final cache = FakeCatalogCache(meals: meals);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      expect(state.value, hasLength(2));
      expect(state.value!.map((m) => m.id).toList(), ['meal-1', 'meal-3']);
    });

    test('limits results to 10 meals maximum', () async {
      // Create 15 meals
      final meals = List.generate(
        15,
        (i) => createTestMeal(id: 'meal-$i', name: 'Meal $i'),
      );
      final mealIds = List.generate(15, (i) => 'meal-$i');

      final repository = FakeRecommendationRepository(
        result: createTestResult(mealIds: mealIds),
      );
      final cache = FakeCatalogCache(meals: meals);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      expect(state.value, hasLength(10));
      // Should be the first 10 in order
      expect(state.value!.first.id, 'meal-0');
      expect(state.value!.last.id, 'meal-9');
    });

    test('returns empty list when catalog cache is null', () async {
      final repository = FakeRecommendationRepository(
        result: createTestResult(mealIds: ['meal-1', 'meal-2']),
      );
      final cache = FakeCatalogCache(meals: null);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      expect(state.value, isNotNull);
      expect(state.value, isEmpty);
    });

    test('returns empty list when catalog cache is empty', () async {
      final repository = FakeRecommendationRepository(
        result: createTestResult(mealIds: ['meal-1', 'meal-2']),
      );
      final cache = FakeCatalogCache(meals: []);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      expect(state.value, isNotNull);
      expect(state.value, isEmpty);
    });

    test('returns empty list on repository error (silent failure)', () async {
      final repository = FakeRecommendationRepository(
        exception: Exception('Network error'),
      );
      final cache = FakeCatalogCache(
        meals: [createTestMeal(id: 'meal-1')],
      );

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      // Should emit empty list, NOT an error state
      expect(state.value, isNotNull);
      expect(state.value, isEmpty);
      expect(state.hasError, isFalse);
    });

    test('sets isPersonalized to true when result is personalized', () async {
      final meals = [
        createTestMeal(id: 'meal-1'),
        createTestMeal(id: 'meal-2'),
      ];
      final repository = FakeRecommendationRepository(
        result: createTestResult(
          mealIds: ['meal-1', 'meal-2'],
          isPersonalized: true,
        ),
      );
      final cache = FakeCatalogCache(meals: meals);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      await waitForNotifier(container);

      final notifier =
          container.read(recommendationNotifierProvider.notifier);
      expect(notifier.isPersonalized, isTrue);
    });

    test('sets isPersonalized to false for cold-start results', () async {
      final meals = [
        createTestMeal(id: 'popular-1'),
        createTestMeal(id: 'popular-2'),
      ];
      final repository = FakeRecommendationRepository(
        result: createTestResult(
          mealIds: ['popular-1', 'popular-2'],
          isPersonalized: false,
        ),
      );
      final cache = FakeCatalogCache(meals: meals);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      await waitForNotifier(container);

      final notifier =
          container.read(recommendationNotifierProvider.notifier);
      expect(notifier.isPersonalized, isFalse);
    });

    test(
        'only includes meals that exist in the catalog cache (unknown IDs are skipped)',
        () async {
      // Cache only has meal-1 and meal-3, but result references meal-1, meal-2, meal-3
      final meals = [
        createTestMeal(id: 'meal-1'),
        createTestMeal(id: 'meal-3'),
      ];
      final repository = FakeRecommendationRepository(
        result: createTestResult(
          mealIds: ['meal-1', 'meal-2', 'meal-3'],
        ),
      );
      final cache = FakeCatalogCache(meals: meals);

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      final state = await waitForNotifier(container);

      expect(state.value, hasLength(2));
      expect(state.value!.map((m) => m.id).toList(), ['meal-1', 'meal-3']);
    });

    test('loadRecommendations() reloads and handles errors silently',
        () async {
      // Use a repository that throws to test silent error handling
      final repository = FakeRecommendationRepository(
        exception: Exception('Server down'),
      );
      final cache = FakeCatalogCache(
        meals: [createTestMeal(id: 'meal-1')],
      );

      final container = createContainer(
        user: createTestUser(),
        repository: repository,
        catalogCache: cache,
      );
      addTearDown(container.dispose);

      // Wait for initial build (which will also fail silently)
      await waitForNotifier(container);

      // Call loadRecommendations explicitly
      final notifier =
          container.read(recommendationNotifierProvider.notifier);
      await notifier.loadRecommendations();

      final state = container.read(recommendationNotifierProvider);
      // Should emit empty list on error, not an error state
      expect(state.value, isNotNull);
      expect(state.value, isEmpty);
      expect(state.hasError, isFalse);
    });
  });
}
