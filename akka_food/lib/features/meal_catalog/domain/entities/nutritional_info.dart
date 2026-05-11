import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutritional_info.freezed.dart';

/// Value object representing the nutritional breakdown of a [Meal].
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// All values are in grams except [calories] which is in kcal.
/// Cloud Function validates that all fields are non-negative before persisting.
@freezed
abstract class NutritionalInfo with _$NutritionalInfo {
  const NutritionalInfo._();

  const factory NutritionalInfo({
    /// Energy in kilocalories (kcal). Must be ≥ 0.
    required double calories,

    /// Protein content in grams. Must be ≥ 0.
    required double proteins,

    /// Carbohydrate content in grams. Must be ≥ 0.
    required double carbohydrates,

    /// Fat content in grams. Must be ≥ 0.
    required double fats,
  }) = _NutritionalInfo;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory NutritionalInfo.fromMap(Map<String, dynamic> map) {
    return NutritionalInfo(
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      proteins: (map['proteins'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (map['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fats: (map['fats'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'calories': calories,
      'proteins': proteins,
      'carbohydrates': carbohydrates,
      'fats': fats,
    };
  }
}
