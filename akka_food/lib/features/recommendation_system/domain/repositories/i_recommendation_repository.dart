import '../entities/recommendation_result.dart';

/// Abstract interface for the recommendation repository.
///
/// Abstracts the data layer (Cloud Function call + Firestore cache) from
/// the domain/presentation layers. Implementations handle network calls,
/// caching, and error mapping.
///
/// Pure Dart — no Flutter or Firebase imports.
abstract class IRecommendationRepository {
  /// Fetches meal recommendations for the given [userId].
  ///
  /// Returns a [RecommendationResult] containing ordered meal IDs,
  /// whether the result is personalized, and when it was computed.
  ///
  /// Implementations should handle cache checks (60-min TTL) and
  /// delegate to the Cloud Function when the cache is stale or missing.
  Future<RecommendationResult> getRecommendations({required String userId});
}
