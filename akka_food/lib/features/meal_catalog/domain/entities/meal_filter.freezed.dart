// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MealFilter {

/// Category IDs to include. Empty list means all categories are shown.
 List<String> get categoryIds;/// Minimum price in XOF (inclusive). Null means no lower bound.
 double? get minPrice;/// Maximum price in XOF (inclusive). Null means no upper bound.
 double? get maxPrice;/// When `true`, only meals with [Meal.isAvailable] == true are shown.
 bool get availableOnly;/// Dietary tags to filter by (e.g. 'vegetarian', 'halal').
/// A meal must match ALL tags in this list to be included.
/// Empty list means no dietary filtering.
 List<String> get dietaryTags;
/// Create a copy of MealFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealFilterCopyWith<MealFilter> get copyWith => _$MealFilterCopyWithImpl<MealFilter>(this as MealFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealFilter&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.availableOnly, availableOnly) || other.availableOnly == availableOnly)&&const DeepCollectionEquality().equals(other.dietaryTags, dietaryTags));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categoryIds),minPrice,maxPrice,availableOnly,const DeepCollectionEquality().hash(dietaryTags));

@override
String toString() {
  return 'MealFilter(categoryIds: $categoryIds, minPrice: $minPrice, maxPrice: $maxPrice, availableOnly: $availableOnly, dietaryTags: $dietaryTags)';
}


}

/// @nodoc
abstract mixin class $MealFilterCopyWith<$Res>  {
  factory $MealFilterCopyWith(MealFilter value, $Res Function(MealFilter) _then) = _$MealFilterCopyWithImpl;
@useResult
$Res call({
 List<String> categoryIds, double? minPrice, double? maxPrice, bool availableOnly, List<String> dietaryTags
});




}
/// @nodoc
class _$MealFilterCopyWithImpl<$Res>
    implements $MealFilterCopyWith<$Res> {
  _$MealFilterCopyWithImpl(this._self, this._then);

  final MealFilter _self;
  final $Res Function(MealFilter) _then;

/// Create a copy of MealFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryIds = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? availableOnly = null,Object? dietaryTags = null,}) {
  return _then(_self.copyWith(
categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,availableOnly: null == availableOnly ? _self.availableOnly : availableOnly // ignore: cast_nullable_to_non_nullable
as bool,dietaryTags: null == dietaryTags ? _self.dietaryTags : dietaryTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [MealFilter].
extension MealFilterPatterns on MealFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealFilter value)  $default,){
final _that = this;
switch (_that) {
case _MealFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealFilter value)?  $default,){
final _that = this;
switch (_that) {
case _MealFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> categoryIds,  double? minPrice,  double? maxPrice,  bool availableOnly,  List<String> dietaryTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealFilter() when $default != null:
return $default(_that.categoryIds,_that.minPrice,_that.maxPrice,_that.availableOnly,_that.dietaryTags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> categoryIds,  double? minPrice,  double? maxPrice,  bool availableOnly,  List<String> dietaryTags)  $default,) {final _that = this;
switch (_that) {
case _MealFilter():
return $default(_that.categoryIds,_that.minPrice,_that.maxPrice,_that.availableOnly,_that.dietaryTags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> categoryIds,  double? minPrice,  double? maxPrice,  bool availableOnly,  List<String> dietaryTags)?  $default,) {final _that = this;
switch (_that) {
case _MealFilter() when $default != null:
return $default(_that.categoryIds,_that.minPrice,_that.maxPrice,_that.availableOnly,_that.dietaryTags);case _:
  return null;

}
}

}

/// @nodoc


class _MealFilter extends MealFilter {
  const _MealFilter({required final  List<String> categoryIds, this.minPrice, this.maxPrice, required this.availableOnly, required final  List<String> dietaryTags}): _categoryIds = categoryIds,_dietaryTags = dietaryTags,super._();
  

/// Category IDs to include. Empty list means all categories are shown.
 final  List<String> _categoryIds;
/// Category IDs to include. Empty list means all categories are shown.
@override List<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

/// Minimum price in XOF (inclusive). Null means no lower bound.
@override final  double? minPrice;
/// Maximum price in XOF (inclusive). Null means no upper bound.
@override final  double? maxPrice;
/// When `true`, only meals with [Meal.isAvailable] == true are shown.
@override final  bool availableOnly;
/// Dietary tags to filter by (e.g. 'vegetarian', 'halal').
/// A meal must match ALL tags in this list to be included.
/// Empty list means no dietary filtering.
 final  List<String> _dietaryTags;
/// Dietary tags to filter by (e.g. 'vegetarian', 'halal').
/// A meal must match ALL tags in this list to be included.
/// Empty list means no dietary filtering.
@override List<String> get dietaryTags {
  if (_dietaryTags is EqualUnmodifiableListView) return _dietaryTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryTags);
}


/// Create a copy of MealFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealFilterCopyWith<_MealFilter> get copyWith => __$MealFilterCopyWithImpl<_MealFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealFilter&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.availableOnly, availableOnly) || other.availableOnly == availableOnly)&&const DeepCollectionEquality().equals(other._dietaryTags, _dietaryTags));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categoryIds),minPrice,maxPrice,availableOnly,const DeepCollectionEquality().hash(_dietaryTags));

@override
String toString() {
  return 'MealFilter(categoryIds: $categoryIds, minPrice: $minPrice, maxPrice: $maxPrice, availableOnly: $availableOnly, dietaryTags: $dietaryTags)';
}


}

/// @nodoc
abstract mixin class _$MealFilterCopyWith<$Res> implements $MealFilterCopyWith<$Res> {
  factory _$MealFilterCopyWith(_MealFilter value, $Res Function(_MealFilter) _then) = __$MealFilterCopyWithImpl;
@override @useResult
$Res call({
 List<String> categoryIds, double? minPrice, double? maxPrice, bool availableOnly, List<String> dietaryTags
});




}
/// @nodoc
class __$MealFilterCopyWithImpl<$Res>
    implements _$MealFilterCopyWith<$Res> {
  __$MealFilterCopyWithImpl(this._self, this._then);

  final _MealFilter _self;
  final $Res Function(_MealFilter) _then;

/// Create a copy of MealFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryIds = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? availableOnly = null,Object? dietaryTags = null,}) {
  return _then(_MealFilter(
categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,availableOnly: null == availableOnly ? _self.availableOnly : availableOnly // ignore: cast_nullable_to_non_nullable
as bool,dietaryTags: null == dietaryTags ? _self._dietaryTags : dietaryTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
