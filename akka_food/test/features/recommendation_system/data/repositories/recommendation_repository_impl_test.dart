import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/recommendation_system/data/datasources/cloud_function_recommendation_data_source.dart';
import 'package:akka_food/features/recommendation_system/data/repositories/recommendation_repository_impl.dart';
import 'package:akka_food/features/recommendation_system/domain/entities/recommendation_result.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Fake cache that implements [IRecommendationCache] without requiring
/// Firebase initialization.
class _FakeRecommendationCache implements IRecommendationCache {
  /// When non-null, [getCachedRecommendations] returns this value.
  RecommendationResult? cachedResult;

  /// When non-null, [getCachedRecommendations] throws this exception.
  Exception? cacheError;

  /// Tracks calls to [getCachedRecommendations].
  final List<String> getCachedCalls = [];

  @override
  Future<RecommendationResult?> getCachedRecommendations(String uid) async {
    getCachedCalls.add(uid);
    if (cacheError != null) throw cacheError!;
    return cachedResult;
  }
}

/// Fake Cloud Function data source that implements
/// [ICloudFunctionRecommendationDataSource] without requiring Firebase.
class _FakeCloudFunctionDataSource
    implements ICloudFunctionRecommendationDataSource {
  /// The result to return from [fetchRecommendations].
  late RecommendationResult fetchResult;

  /// When non-null, [fetchRecommendations] throws this exception.
  Exception? fetchError;

  /// Tracks calls to [fetchRecommendations].
  int fetchCallCount = 0;

  @override
  Future<RecommendationResult> fetchRecommendations() async {
    fetchCallCount++;
    if (fetchError != null) throw fetchError!;
    return fetchResult;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RecommendationResult _makeCachedResult() {
  return RecommendationResult(
    mealIds: ['meal-1', 'meal-2', 'meal-3'],
    isPersonalized: true,
    computedAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );
}

RecommendationResult _makeCloudResult() {
  return RecommendationResult(
    mealIds: ['meal-a', 'meal-b', 'meal-c', 'meal-d'],
    isPersonalized: false,
    computedAt: DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeRecommendationCache fakeCache;
  late _FakeCloudFunctionDataSource fakeCloudFunction;
  late RecommendationRepositoryImpl repository;

  setUp(() {
    fakeCache = _FakeRecommendationCache();
    fakeCloudFunction = _FakeCloudFunctionDataSource();
    fakeCloudFunction.fetchResult = _makeCloudResult();

    repository = RecommendationRepositoryImpl(
      cache: fakeCache,
      cloudFunctionDataSource: fakeCloudFunction,
    );
  });

  // =========================================================================
  // Cache hit — returns cached result
  // =========================================================================

  group('cache hit', () {
    test('returns cached result when cache has fresh data', () async {
      final cached = _makeCachedResult();
      fakeCache.cachedResult = cached;

      final result = await repository.getRecommendations(userId: 'user-1');

      expect(result.mealIds, cached.mealIds);
      expect(result.isPersonalized, cached.isPersonalized);
      expect(result.computedAt, cached.computedAt);
    });

    test('does NOT call Cloud Function when cache returns fresh data',
        () async {
      fakeCache.cachedResult = _makeCachedResult();

      await repository.getRecommendations(userId: 'user-1');

      expect(fakeCloudFunction.fetchCallCount, 0);
    });

    test('passes the correct userId to the cache', () async {
      fakeCache.cachedResult = _makeCachedResult();

      await repository.getRecommendations(userId: 'abc-123');

      expect(fakeCache.getCachedCalls, ['abc-123']);
    });
  });

  // =========================================================================
  // Cache miss — falls back to Cloud Function
  // =========================================================================

  group('cache miss', () {
    test('calls Cloud Function when cache returns null (stale/missing)',
        () async {
      fakeCache.cachedResult = null;

      await repository.getRecommendations(userId: 'user-2');

      expect(fakeCloudFunction.fetchCallCount, 1);
    });

    test('returns Cloud Function result when cache is stale', () async {
      fakeCache.cachedResult = null;
      final cloudResult = _makeCloudResult();
      fakeCloudFunction.fetchResult = cloudResult;

      final result = await repository.getRecommendations(userId: 'user-2');

      expect(result.mealIds, cloudResult.mealIds);
      expect(result.isPersonalized, cloudResult.isPersonalized);
    });
  });

  // =========================================================================
  // Error handling
  // =========================================================================

  group('error handling', () {
    test('falls back to Cloud Function when cache throws an exception',
        () async {
      fakeCache.cacheError = Exception('Firestore unavailable');
      final cloudResult = _makeCloudResult();
      fakeCloudFunction.fetchResult = cloudResult;

      final result = await repository.getRecommendations(userId: 'user-3');

      expect(result.mealIds, cloudResult.mealIds);
      expect(fakeCloudFunction.fetchCallCount, 1);
    });

    test('rethrows Cloud Function error when both cache and CF fail',
        () async {
      fakeCache.cachedResult = null;
      fakeCloudFunction.fetchError =
          RecommendationNetworkException('Network error');

      await expectLater(
        repository.getRecommendations(userId: 'user-4'),
        throwsA(isA<RecommendationNetworkException>()),
      );
    });

    test(
        'rethrows RecommendationFetchException from Cloud Function on cache miss',
        () async {
      fakeCache.cachedResult = null;
      fakeCloudFunction.fetchError = RecommendationFetchException(
        'Function error',
        code: 'internal',
      );

      await expectLater(
        repository.getRecommendations(userId: 'user-5'),
        throwsA(isA<RecommendationFetchException>()),
      );
    });

    test(
        'cache error + Cloud Function success returns Cloud Function result',
        () async {
      fakeCache.cacheError = Exception('Permission denied');
      final cloudResult = _makeCloudResult();
      fakeCloudFunction.fetchResult = cloudResult;

      final result = await repository.getRecommendations(userId: 'user-6');

      expect(result.mealIds, cloudResult.mealIds);
      expect(result.isPersonalized, cloudResult.isPersonalized);
    });
  });
}
