import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/meal_catalog/data/datasources/hive_catalog_cache.dart';
import 'package:akka_food/features/meal_catalog/domain/entities/meal.dart';
import 'package:akka_food/features/recommendation_system/domain/repositories/i_recommendation_repository.dart';

import '../../data/repositories/recommendation_repository_impl.dart';
import '../../data/datasources/cloud_function_recommendation_data_source.dart';
import '../../data/datasources/firestore_recommendation_cache.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

part 'recommendation_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [RecommendationRepositoryImpl] bound to
/// [IRecommendationRepository].
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
IRecommendationRepository recommendationRepository(Ref ref) {
  return RecommendationRepositoryImpl(
    cache: FirestoreRecommendationCache(
      firestore: FirebaseFirestore.instance,
    ),
    cloudFunctionDataSource: CloudFunctionRecommendationDataSource(),
  );
}

// ---------------------------------------------------------------------------
// Catalog cache provider
// ---------------------------------------------------------------------------

/// Provides the [HiveCatalogCache] instance for resolving meal IDs.
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
HiveCatalogCache catalogCache(Ref ref) {
  return HiveCatalogCache();
}

// ---------------------------------------------------------------------------
// RecommendationNotifier
// ---------------------------------------------------------------------------

/// Manages the recommendation state for the "Recommended for You" section.
///
/// Responsibilities:
/// - Fetching recommendations via [IRecommendationRepository].
/// - Resolving meal IDs to full [Meal] objects from the local Hive cache.
/// - Filtering out unavailable meals client-side.
/// - Limiting results to a maximum of 10 meals.
/// - Exposing [isPersonalized] for the UI header.
///
/// On error, emits an empty list silently (Requirement 4, Criteria 4).
@riverpod
class RecommendationNotifier extends _$RecommendationNotifier {
  /// Whether the current recommendations are personalized to the user's
  /// history, or popularity-based (cold-start).
  bool _isPersonalized = false;

  /// Returns whether the current recommendations are personalized.
  bool get isPersonalized => _isPersonalized;

  @override
  Future<List<Meal>> build() async {
    // Auto-load recommendations when the notifier is first built.
    // Silent failure: on any error, emit empty list (no error shown to user).
    try {
      return await _loadRecommendations();
    } catch (_) {
      return [];
    }
  }

  /// Fetches recommendations and resolves them to [Meal] objects.
  ///
  /// Steps:
  /// 1. Get the current user's UID from auth state.
  /// 2. Call [IRecommendationRepository.getRecommendations].
  /// 3. Resolve mealIds to full [Meal] objects from the local Hive cache.
  /// 4. Filter out unavailable meals.
  /// 5. Take up to 10 results.
  Future<List<Meal>> _loadRecommendations() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return [];

    final repository = ref.watch(recommendationRepositoryProvider);
    final result = await repository.getRecommendations(
      userId: currentUser.uid,
    );

    _isPersonalized = result.isPersonalized;

    // Resolve mealIds to full Meal objects from the local Hive catalog cache.
    final cache = ref.watch(catalogCacheProvider);
    final cachedMeals = await cache.getCachedMeals();

    if (cachedMeals == null || cachedMeals.isEmpty) return [];

    // Build a lookup map for O(1) access by ID.
    final mealMap = {for (final meal in cachedMeals) meal.id: meal};

    // Resolve, filter unavailable, and take up to 10.
    final availableMeals = result.mealIds
        .map((id) => mealMap[id])
        .whereType<Meal>()
        .where((m) => m.isAvailable)
        .take(10)
        .toList();

    return availableMeals;
  }

  /// Manually triggers a reload of recommendations.
  ///
  /// Useful when the catalog screen is refreshed or after a new order.
  Future<void> loadRecommendations() async {
    state = const AsyncLoading<List<Meal>>().copyWithPrevious(state);
    try {
      final meals = await _loadRecommendations();
      state = AsyncData(meals);
    } catch (_) {
      // Silent failure: emit empty list on error (Requirement 4, Criteria 4).
      state = const AsyncData([]);
    }
  }
}
