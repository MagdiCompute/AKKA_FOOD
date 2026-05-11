// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutritional_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NutritionalInfo {

/// Energy in kilocalories (kcal). Must be ≥ 0.
 double get calories;/// Protein content in grams. Must be ≥ 0.
 double get proteins;/// Carbohydrate content in grams. Must be ≥ 0.
 double get carbohydrates;/// Fat content in grams. Must be ≥ 0.
 double get fats;
/// Create a copy of NutritionalInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NutritionalInfoCopyWith<NutritionalInfo> get copyWith => _$NutritionalInfoCopyWithImpl<NutritionalInfo>(this as NutritionalInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NutritionalInfo&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.proteins, proteins) || other.proteins == proteins)&&(identical(other.carbohydrates, carbohydrates) || other.carbohydrates == carbohydrates)&&(identical(other.fats, fats) || other.fats == fats));
}


@override
int get hashCode => Object.hash(runtimeType,calories,proteins,carbohydrates,fats);

@override
String toString() {
  return 'NutritionalInfo(calories: $calories, proteins: $proteins, carbohydrates: $carbohydrates, fats: $fats)';
}


}

/// @nodoc
abstract mixin class $NutritionalInfoCopyWith<$Res>  {
  factory $NutritionalInfoCopyWith(NutritionalInfo value, $Res Function(NutritionalInfo) _then) = _$NutritionalInfoCopyWithImpl;
@useResult
$Res call({
 double calories, double proteins, double carbohydrates, double fats
});




}
/// @nodoc
class _$NutritionalInfoCopyWithImpl<$Res>
    implements $NutritionalInfoCopyWith<$Res> {
  _$NutritionalInfoCopyWithImpl(this._self, this._then);

  final NutritionalInfo _self;
  final $Res Function(NutritionalInfo) _then;

/// Create a copy of NutritionalInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? calories = null,Object? proteins = null,Object? carbohydrates = null,Object? fats = null,}) {
  return _then(_self.copyWith(
calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,proteins: null == proteins ? _self.proteins : proteins // ignore: cast_nullable_to_non_nullable
as double,carbohydrates: null == carbohydrates ? _self.carbohydrates : carbohydrates // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NutritionalInfo].
extension NutritionalInfoPatterns on NutritionalInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NutritionalInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NutritionalInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NutritionalInfo value)  $default,){
final _that = this;
switch (_that) {
case _NutritionalInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NutritionalInfo value)?  $default,){
final _that = this;
switch (_that) {
case _NutritionalInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double calories,  double proteins,  double carbohydrates,  double fats)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NutritionalInfo() when $default != null:
return $default(_that.calories,_that.proteins,_that.carbohydrates,_that.fats);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double calories,  double proteins,  double carbohydrates,  double fats)  $default,) {final _that = this;
switch (_that) {
case _NutritionalInfo():
return $default(_that.calories,_that.proteins,_that.carbohydrates,_that.fats);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double calories,  double proteins,  double carbohydrates,  double fats)?  $default,) {final _that = this;
switch (_that) {
case _NutritionalInfo() when $default != null:
return $default(_that.calories,_that.proteins,_that.carbohydrates,_that.fats);case _:
  return null;

}
}

}

/// @nodoc


class _NutritionalInfo extends NutritionalInfo {
  const _NutritionalInfo({required this.calories, required this.proteins, required this.carbohydrates, required this.fats}): super._();
  

/// Energy in kilocalories (kcal). Must be ≥ 0.
@override final  double calories;
/// Protein content in grams. Must be ≥ 0.
@override final  double proteins;
/// Carbohydrate content in grams. Must be ≥ 0.
@override final  double carbohydrates;
/// Fat content in grams. Must be ≥ 0.
@override final  double fats;

/// Create a copy of NutritionalInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NutritionalInfoCopyWith<_NutritionalInfo> get copyWith => __$NutritionalInfoCopyWithImpl<_NutritionalInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NutritionalInfo&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.proteins, proteins) || other.proteins == proteins)&&(identical(other.carbohydrates, carbohydrates) || other.carbohydrates == carbohydrates)&&(identical(other.fats, fats) || other.fats == fats));
}


@override
int get hashCode => Object.hash(runtimeType,calories,proteins,carbohydrates,fats);

@override
String toString() {
  return 'NutritionalInfo(calories: $calories, proteins: $proteins, carbohydrates: $carbohydrates, fats: $fats)';
}


}

/// @nodoc
abstract mixin class _$NutritionalInfoCopyWith<$Res> implements $NutritionalInfoCopyWith<$Res> {
  factory _$NutritionalInfoCopyWith(_NutritionalInfo value, $Res Function(_NutritionalInfo) _then) = __$NutritionalInfoCopyWithImpl;
@override @useResult
$Res call({
 double calories, double proteins, double carbohydrates, double fats
});




}
/// @nodoc
class __$NutritionalInfoCopyWithImpl<$Res>
    implements _$NutritionalInfoCopyWith<$Res> {
  __$NutritionalInfoCopyWithImpl(this._self, this._then);

  final _NutritionalInfo _self;
  final $Res Function(_NutritionalInfo) _then;

/// Create a copy of NutritionalInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? calories = null,Object? proteins = null,Object? carbohydrates = null,Object? fats = null,}) {
  return _then(_NutritionalInfo(
calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as double,proteins: null == proteins ? _self.proteins : proteins // ignore: cast_nullable_to_non_nullable
as double,carbohydrates: null == carbohydrates ? _self.carbohydrates : carbohydrates // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
