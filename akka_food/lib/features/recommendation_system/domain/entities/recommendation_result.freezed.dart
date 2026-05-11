// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommendation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecommendationResult {

/// Ordered list of meal IDs, sorted by relevance score descending.
 List<String> get mealIds;/// Whether the recommendations are personalized to the user's history.
/// `false` indicates cold-start popularity-based recommendations.
 bool get isPersonalized;/// Timestamp when the recommendation was computed.
@_FirestoreDateTimeConverter() DateTime get computedAt;
/// Create a copy of RecommendationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendationResultCopyWith<RecommendationResult> get copyWith => _$RecommendationResultCopyWithImpl<RecommendationResult>(this as RecommendationResult, _$identity);

  /// Serializes this RecommendationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendationResult&&const DeepCollectionEquality().equals(other.mealIds, mealIds)&&(identical(other.isPersonalized, isPersonalized) || other.isPersonalized == isPersonalized)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(mealIds),isPersonalized,computedAt);

@override
String toString() {
  return 'RecommendationResult(mealIds: $mealIds, isPersonalized: $isPersonalized, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class $RecommendationResultCopyWith<$Res>  {
  factory $RecommendationResultCopyWith(RecommendationResult value, $Res Function(RecommendationResult) _then) = _$RecommendationResultCopyWithImpl;
@useResult
$Res call({
 List<String> mealIds, bool isPersonalized,@_FirestoreDateTimeConverter() DateTime computedAt
});




}
/// @nodoc
class _$RecommendationResultCopyWithImpl<$Res>
    implements $RecommendationResultCopyWith<$Res> {
  _$RecommendationResultCopyWithImpl(this._self, this._then);

  final RecommendationResult _self;
  final $Res Function(RecommendationResult) _then;

/// Create a copy of RecommendationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mealIds = null,Object? isPersonalized = null,Object? computedAt = null,}) {
  return _then(_self.copyWith(
mealIds: null == mealIds ? _self.mealIds : mealIds // ignore: cast_nullable_to_non_nullable
as List<String>,isPersonalized: null == isPersonalized ? _self.isPersonalized : isPersonalized // ignore: cast_nullable_to_non_nullable
as bool,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendationResult].
extension RecommendationResultPatterns on RecommendationResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendationResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendationResult value)  $default,){
final _that = this;
switch (_that) {
case _RecommendationResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendationResult value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendationResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> mealIds,  bool isPersonalized, @_FirestoreDateTimeConverter()  DateTime computedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendationResult() when $default != null:
return $default(_that.mealIds,_that.isPersonalized,_that.computedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> mealIds,  bool isPersonalized, @_FirestoreDateTimeConverter()  DateTime computedAt)  $default,) {final _that = this;
switch (_that) {
case _RecommendationResult():
return $default(_that.mealIds,_that.isPersonalized,_that.computedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> mealIds,  bool isPersonalized, @_FirestoreDateTimeConverter()  DateTime computedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecommendationResult() when $default != null:
return $default(_that.mealIds,_that.isPersonalized,_that.computedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecommendationResult extends RecommendationResult {
  const _RecommendationResult({required final  List<String> mealIds, required this.isPersonalized, @_FirestoreDateTimeConverter() required this.computedAt}): _mealIds = mealIds,super._();
  factory _RecommendationResult.fromJson(Map<String, dynamic> json) => _$RecommendationResultFromJson(json);

/// Ordered list of meal IDs, sorted by relevance score descending.
 final  List<String> _mealIds;
/// Ordered list of meal IDs, sorted by relevance score descending.
@override List<String> get mealIds {
  if (_mealIds is EqualUnmodifiableListView) return _mealIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mealIds);
}

/// Whether the recommendations are personalized to the user's history.
/// `false` indicates cold-start popularity-based recommendations.
@override final  bool isPersonalized;
/// Timestamp when the recommendation was computed.
@override@_FirestoreDateTimeConverter() final  DateTime computedAt;

/// Create a copy of RecommendationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendationResultCopyWith<_RecommendationResult> get copyWith => __$RecommendationResultCopyWithImpl<_RecommendationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendationResult&&const DeepCollectionEquality().equals(other._mealIds, _mealIds)&&(identical(other.isPersonalized, isPersonalized) || other.isPersonalized == isPersonalized)&&(identical(other.computedAt, computedAt) || other.computedAt == computedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_mealIds),isPersonalized,computedAt);

@override
String toString() {
  return 'RecommendationResult(mealIds: $mealIds, isPersonalized: $isPersonalized, computedAt: $computedAt)';
}


}

/// @nodoc
abstract mixin class _$RecommendationResultCopyWith<$Res> implements $RecommendationResultCopyWith<$Res> {
  factory _$RecommendationResultCopyWith(_RecommendationResult value, $Res Function(_RecommendationResult) _then) = __$RecommendationResultCopyWithImpl;
@override @useResult
$Res call({
 List<String> mealIds, bool isPersonalized,@_FirestoreDateTimeConverter() DateTime computedAt
});




}
/// @nodoc
class __$RecommendationResultCopyWithImpl<$Res>
    implements _$RecommendationResultCopyWith<$Res> {
  __$RecommendationResultCopyWithImpl(this._self, this._then);

  final _RecommendationResult _self;
  final $Res Function(_RecommendationResult) _then;

/// Create a copy of RecommendationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mealIds = null,Object? isPersonalized = null,Object? computedAt = null,}) {
  return _then(_RecommendationResult(
mealIds: null == mealIds ? _self._mealIds : mealIds // ignore: cast_nullable_to_non_nullable
as List<String>,isPersonalized: null == isPersonalized ? _self.isPersonalized : isPersonalized // ignore: cast_nullable_to_non_nullable
as bool,computedAt: null == computedAt ? _self.computedAt : computedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
