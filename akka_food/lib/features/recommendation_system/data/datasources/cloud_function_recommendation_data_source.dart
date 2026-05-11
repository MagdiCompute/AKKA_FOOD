import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/recommendation_result.dart';
import '../repositories/recommendation_repository_impl.dart';

/// Data source that calls the `computeRecommendations` Firebase Cloud Function.
///
/// The Cloud Function handles cache checks (60-min TTL), computes personalized
/// or cold-start recommendations, and returns the result. This class is the
/// bridge between the Flutter data layer and that function.
///
/// Accepts an optional [FirebaseFunctions] instance for testability;
/// defaults to [FirebaseFunctions.instance] in production.
class CloudFunctionRecommendationDataSource
    implements ICloudFunctionRecommendationDataSource {
  CloudFunctionRecommendationDataSource({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Calls the `computeRecommendations` Cloud Function to fetch
  /// meal recommendations for the authenticated user.
  ///
  /// The Cloud Function returns `{ mealIds: string[], isPersonalized: bool }`.
  /// This method parses the response into a [RecommendationResult] entity.
  ///
  /// Throws:
  /// - [RecommendationFetchException] if the Cloud Function returns an error.
  /// - [RecommendationNetworkException] if a network error occurs.
  @override
  Future<RecommendationResult> fetchRecommendations() async {
    try {
      final callable = _functions.httpsCallable('computeRecommendations');

      final response = await callable.call<Map<String, dynamic>>();

      final data = response.data;

      final rawMealIds = data['mealIds'] as List<dynamic>? ?? [];
      final mealIds = rawMealIds.cast<String>();
      final isPersonalized = data['isPersonalized'] as bool? ?? false;

      return RecommendationResult(
        mealIds: mealIds,
        isPersonalized: isPersonalized,
        computedAt: DateTime.now(),
      );
    } on FirebaseFunctionsException catch (e) {
      throw RecommendationFetchException(
        e.message ?? 'Failed to fetch recommendations.',
        code: e.code,
        details: e.details,
      );
    } on Exception catch (e) {
      throw RecommendationNetworkException(
        'Network error while fetching recommendations: $e',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Thrown when the `computeRecommendations` Cloud Function returns an error.
class RecommendationFetchException implements Exception {
  RecommendationFetchException(this.message, {this.code, this.details});

  final String message;
  final String? code;
  final dynamic details;

  @override
  String toString() =>
      'RecommendationFetchException: $message (code: $code, details: $details)';
}

/// Thrown when a network error prevents communication with the Cloud Function.
class RecommendationNetworkException implements Exception {
  RecommendationNetworkException(this.message);

  final String message;

  @override
  String toString() => 'RecommendationNetworkException: $message';
}
