import 'package:akka_food/features/meal_catalog/domain/entities/nutritional_info.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal.freezed.dart';

/// Domain entity representing a meal in the AKKA Food catalog.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Firestore serialization is handled manually via [fromMap] / [toMap]
/// so the domain layer stays free of Firebase dependencies.
@freezed
abstract class Meal with _$Meal {
  const Meal._();

  const factory Meal({
    required String id,
    required String name,
    required String description,

    /// Price in XOF (West African CFA franc). Must be > 0.
    required double price,

    required String categoryId,
    required List<String> imageUrls,
    required bool isAvailable,
    required bool isFeatured,

    /// Admin-defined display order within the featured section.
    required int featuredOrder,

    /// Optional nutritional breakdown. Null when not provided by admin.
    NutritionalInfo? nutritionalInfo,

    /// Dietary labels, e.g. ['vegetarian', 'vegan', 'gluten-free', 'spicy', 'halal'].
    required List<String> dietaryTags,

    /// Incremented on each order; used for popularity-based sorting.
    required int popularityScore,

    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Meal;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory Meal.fromMap(Map<String, dynamic> map) {
    final rawImageUrls = map['imageUrls'];
    final List<String> imageUrls;
    if (rawImageUrls is List) {
      imageUrls = rawImageUrls.whereType<String>().toList();
    } else {
      imageUrls = const [];
    }

    final rawDietaryTags = map['dietaryTags'];
    final List<String> dietaryTags;
    if (rawDietaryTags is List) {
      dietaryTags = rawDietaryTags.whereType<String>().toList();
    } else {
      dietaryTags = const [];
    }

    final rawNutritionalInfo = map['nutritionalInfo'];
    final NutritionalInfo? nutritionalInfo;
    if (rawNutritionalInfo is Map<String, dynamic>) {
      nutritionalInfo = NutritionalInfo.fromMap(rawNutritionalInfo);
    } else {
      nutritionalInfo = null;
    }

    return Meal(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['categoryId'] as String? ?? '',
      imageUrls: imageUrls,
      isAvailable: map['isAvailable'] as bool? ?? false,
      isFeatured: map['isFeatured'] as bool? ?? false,
      featuredOrder: (map['featuredOrder'] as num?)?.toInt() ?? 0,
      nutritionalInfo: nutritionalInfo,
      dietaryTags: dietaryTags,
      popularityScore: (map['popularityScore'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'featuredOrder': featuredOrder,
      'nutritionalInfo': nutritionalInfo?.toMap(),
      'dietaryTags': dietaryTags,
      'popularityScore': popularityScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
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
