import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation_result.freezed.dart';
part 'recommendation_result.g.dart';

// ---------------------------------------------------------------------------
// JsonConverters
// ---------------------------------------------------------------------------

/// Converts [DateTime] to/from dynamic values for Firestore compatibility.
///
/// Accepts:
/// - A [DateTime] directly
/// - An ISO-8601 [String]
/// - Any object with a `.toDate()` method (e.g. Firestore `Timestamp`) —
///   handled via duck-typing so the domain layer stays free of Firebase imports
/// - `null` — falls back to [DateTime.now]
class _FirestoreDateTimeConverter
    implements JsonConverter<DateTime, dynamic> {
  const _FirestoreDateTimeConverter();

  @override
  DateTime fromJson(dynamic json) => _parseDateTime(json);

  @override
  dynamic toJson(DateTime dateTime) => dateTime.toIso8601String();
}

// ---------------------------------------------------------------------------
// RecommendationResult entity
// ---------------------------------------------------------------------------

/// Domain entity representing the result of a recommendation computation.
///
/// Contains an ordered list of meal IDs (by relevance score descending),
/// whether the result is personalized or popularity-based (cold-start),
/// and when the recommendation was computed.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Firestore serialization is provided via [fromMap]/[toMap] convenience
/// methods that delegate to the generated JSON factories, plus a custom
/// converter for [DateTime] (Firestore Timestamp).
@freezed
abstract class RecommendationResult with _$RecommendationResult {
  const RecommendationResult._();

  const factory RecommendationResult({
    /// Ordered list of meal IDs, sorted by relevance score descending.
    required List<String> mealIds,

    /// Whether the recommendations are personalized to the user's history.
    /// `false` indicates cold-start popularity-based recommendations.
    required bool isPersonalized,

    /// Timestamp when the recommendation was computed.
    @_FirestoreDateTimeConverter() required DateTime computedAt,
  }) = _RecommendationResult;

  factory RecommendationResult.fromJson(Map<String, dynamic> json) =>
      _$RecommendationResultFromJson(json);

  // ---------------------------------------------------------------------------
  // Firestore serialization helpers
  // ---------------------------------------------------------------------------

  /// Creates a [RecommendationResult] from a Firestore document map.
  ///
  /// Handles Firestore `Timestamp` objects via duck-typing (no Firebase import).
  factory RecommendationResult.fromMap(Map<String, dynamic> map) =>
      RecommendationResult.fromJson(map);

  /// Converts this [RecommendationResult] to a map suitable for Firestore writes.
  Map<String, dynamic> toMap() => toJson();
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Converts a Firestore timestamp-like value to [DateTime].
///
/// Accepts:
/// - A [DateTime] directly.
/// - Any object with a `.toDate()` method (e.g. `Timestamp` from
///   `cloud_firestore`) — handled via duck-typing so the domain layer
///   stays free of Firebase imports.
/// - An ISO-8601 [String].
/// - `null` — falls back to [DateTime.now].
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  // Duck-type Firestore Timestamp without importing cloud_firestore.
  try {
    // ignore: avoid_dynamic_calls
    return (value.toDate()) as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}
