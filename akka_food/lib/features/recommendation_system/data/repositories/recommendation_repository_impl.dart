import '../../domain/entities/recommendation_result.dart';
import '../../domain/repositories/i_recommendation_repository.dart';

/// Interface for the recommendation cache, enabling testability.
///
/// [FirestoreRecommendationCache] implements this implicitly via duck-typing
/// (same method signature).
abstract class IRecommendationCache {
  /// Returns cached recommendations if fresh, or `null` if stale/missing.
  Future<RecommendationResult?> getCachedRecommendations(String uid);
}

/// Interface for the cloud function data source, enabling testability.
///
/// [CloudFunctionRecommendationDataSource] implements this implicitly via
/// duck-typing (same method signature).
abstract class ICloudFunctionRecommendationDataSource {
  /// Fetches fresh recommendations from the Cloud Function.
  Future<RecommendationResult> fetchRecommendations();
}

/// Implementation of [IRecommendationRepository] that composes both data sources.
///
/// Strategy:
/// 1. Check [FirestoreRecommendationCache] for a fresh cached result (< 60 min).
/// 2. If cache returns a valid result, return it immediately.
/// 3. If cache returns `null` (stale or missing), call
///    [CloudFunctionRecommendationDataSource] for fresh recommendations.
/// 4. Handle errors from both sources gracefully — rethrows Cloud Function
///    errors so the presentation layer can decide how to handle them.
class RecommendationRepositoryImpl implements IRecommendationRepository {
  RecommendationRepositoryImpl({
    required IRecommendationCache cache,
    required ICloudFunctionRecommendationDataSource cloudFunctionDataSource,
  })  : _cache = cache,
        _cloudFunctionDataSource = cloudFunctionDataSource;

  final IRecommendationCache _cache;
  final ICloudFunctionRecommendationDataSource _cloudFunctionDataSource;

  @override
  Future<RecommendationResult> getRecommendations({
    required String userId,
  }) async {
    // 1. Try the Firestore cache first.
    try {
      final cached = await _cache.getCachedRecommendations(userId);
      if (cached != null) {
        return cached;
      }
    } on Exception {
      // Cache read failed — fall through to Cloud Function.
    }

    // 2. Cache miss or stale — fetch from Cloud Function.
    final result = await _cloudFunctionDataSource.fetchRecommendations();
    return result;
  }
}
