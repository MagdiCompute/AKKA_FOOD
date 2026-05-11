import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:akka_food/features/recommendation_system/domain/entities/recommendation_result.dart';

/// Data-layer model representing the `/recommendations/{uid}` Firestore document.
///
/// Handles Firestore-specific serialization concerns (e.g. [Timestamp] ↔
/// [DateTime] conversion) while the domain entity [RecommendationResult]
/// remains free of Firebase imports.
///
/// Firestore schema:
/// ```
/// /recommendations/{uid}
///   - mealIds: string[]          // up to 10 meal IDs, ordered by score
///   - isPersonalized: bool
///   - computedAt: timestamp      // used for TTL check (60 min)
/// ```
class RecommendationDocument {
  /// Ordered list of meal IDs (up to 10), sorted by relevance score descending.
  final List<String> mealIds;

  /// Whether the recommendations are personalized to the user's history.
  /// `false` indicates cold-start popularity-based recommendations.
  final bool isPersonalized;

  /// Timestamp when the recommendation was computed.
  /// Used for TTL check (60 minutes).
  final DateTime computedAt;

  const RecommendationDocument({
    required this.mealIds,
    required this.isPersonalized,
    required this.computedAt,
  });

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /// Creates a [RecommendationDocument] from a Firestore document map.
  ///
  /// Handles Firestore [Timestamp] → [DateTime] conversion for `computedAt`.
  /// Falls back to [DateTime.now] if `computedAt` is null or unparseable.
  factory RecommendationDocument.fromMap(Map<String, dynamic> map) {
    final rawMealIds = map['mealIds'] as List<dynamic>? ?? [];

    return RecommendationDocument(
      mealIds: rawMealIds.cast<String>(),
      isPersonalized: map['isPersonalized'] as bool? ?? false,
      computedAt: _parseDateTime(map['computedAt']),
    );
  }

  /// Converts this document to a map suitable for Firestore writes.
  ///
  /// Stores `computedAt` as a Firestore [Timestamp] for proper server-side
  /// ordering and TTL queries.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mealIds': mealIds,
      'isPersonalized': isPersonalized,
      'computedAt': Timestamp.fromDate(computedAt),
    };
  }

  // ---------------------------------------------------------------------------
  // Domain mapping
  // ---------------------------------------------------------------------------

  /// Converts this data-layer document to the domain entity.
  RecommendationResult toDomain() {
    return RecommendationResult(
      mealIds: mealIds,
      isPersonalized: isPersonalized,
      computedAt: computedAt,
    );
  }

  /// Creates a [RecommendationDocument] from a domain [RecommendationResult].
  factory RecommendationDocument.fromDomain(RecommendationResult result) {
    return RecommendationDocument(
      mealIds: result.mealIds,
      isPersonalized: result.isPersonalized,
      computedAt: result.computedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecommendationDocument) return false;
    if (isPersonalized != other.isPersonalized) return false;
    if (computedAt != other.computedAt) return false;
    if (mealIds.length != other.mealIds.length) return false;
    for (var i = 0; i < mealIds.length; i++) {
      if (mealIds[i] != other.mealIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(mealIds),
        isPersonalized,
        computedAt,
      );

  @override
  String toString() {
    return 'RecommendationDocument('
        'mealIds: $mealIds, '
        'isPersonalized: $isPersonalized, '
        'computedAt: $computedAt'
        ')';
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Converts a Firestore timestamp-like value to [DateTime].
///
/// Accepts:
/// - A [DateTime] directly.
/// - A Firestore [Timestamp].
/// - An ISO-8601 [String].
/// - `null` — falls back to [DateTime.now].
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  // Fallback for unexpected types.
  try {
    // ignore: avoid_dynamic_calls
    return (value.toDate()) as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}
