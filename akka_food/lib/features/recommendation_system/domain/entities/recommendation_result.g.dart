// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecommendationResult _$RecommendationResultFromJson(
  Map<String, dynamic> json,
) => _RecommendationResult(
  mealIds: (json['mealIds'] as List<dynamic>).map((e) => e as String).toList(),
  isPersonalized: json['isPersonalized'] as bool,
  computedAt: const _FirestoreDateTimeConverter().fromJson(json['computedAt']),
);

Map<String, dynamic> _$RecommendationResultToJson(
  _RecommendationResult instance,
) => <String, dynamic>{
  'mealIds': instance.mealIds,
  'isPersonalized': instance.isPersonalized,
  'computedAt': const _FirestoreDateTimeConverter().toJson(instance.computedAt),
};
