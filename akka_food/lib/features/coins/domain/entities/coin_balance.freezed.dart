// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coin_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoinBalance {

 int get total; int get nextThreshold; int get coinsToNext;
/// Create a copy of CoinBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoinBalanceCopyWith<CoinBalance> get copyWith => _$CoinBalanceCopyWithImpl<CoinBalance>(this as CoinBalance, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoinBalance&&(identical(other.total, total) || other.total == total)&&(identical(other.nextThreshold, nextThreshold) || other.nextThreshold == nextThreshold)&&(identical(other.coinsToNext, coinsToNext) || other.coinsToNext == coinsToNext));
}


@override
int get hashCode => Object.hash(runtimeType,total,nextThreshold,coinsToNext);

@override
String toString() {
  return 'CoinBalance(total: $total, nextThreshold: $nextThreshold, coinsToNext: $coinsToNext)';
}


}

/// @nodoc
abstract mixin class $CoinBalanceCopyWith<$Res>  {
  factory $CoinBalanceCopyWith(CoinBalance value, $Res Function(CoinBalance) _then) = _$CoinBalanceCopyWithImpl;
@useResult
$Res call({
 int total, int nextThreshold, int coinsToNext
});




}
/// @nodoc
class _$CoinBalanceCopyWithImpl<$Res>
    implements $CoinBalanceCopyWith<$Res> {
  _$CoinBalanceCopyWithImpl(this._self, this._then);

  final CoinBalance _self;
  final $Res Function(CoinBalance) _then;

/// Create a copy of CoinBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? nextThreshold = null,Object? coinsToNext = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,nextThreshold: null == nextThreshold ? _self.nextThreshold : nextThreshold // ignore: cast_nullable_to_non_nullable
as int,coinsToNext: null == coinsToNext ? _self.coinsToNext : coinsToNext // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CoinBalance].
extension CoinBalancePatterns on CoinBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoinBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoinBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoinBalance value)  $default,){
final _that = this;
switch (_that) {
case _CoinBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoinBalance value)?  $default,){
final _that = this;
switch (_that) {
case _CoinBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int nextThreshold,  int coinsToNext)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoinBalance() when $default != null:
return $default(_that.total,_that.nextThreshold,_that.coinsToNext);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int nextThreshold,  int coinsToNext)  $default,) {final _that = this;
switch (_that) {
case _CoinBalance():
return $default(_that.total,_that.nextThreshold,_that.coinsToNext);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int nextThreshold,  int coinsToNext)?  $default,) {final _that = this;
switch (_that) {
case _CoinBalance() when $default != null:
return $default(_that.total,_that.nextThreshold,_that.coinsToNext);case _:
  return null;

}
}

}

/// @nodoc


class _CoinBalance extends CoinBalance {
  const _CoinBalance({required this.total, required this.nextThreshold, required this.coinsToNext}): super._();
  

@override final  int total;
@override final  int nextThreshold;
@override final  int coinsToNext;

/// Create a copy of CoinBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoinBalanceCopyWith<_CoinBalance> get copyWith => __$CoinBalanceCopyWithImpl<_CoinBalance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoinBalance&&(identical(other.total, total) || other.total == total)&&(identical(other.nextThreshold, nextThreshold) || other.nextThreshold == nextThreshold)&&(identical(other.coinsToNext, coinsToNext) || other.coinsToNext == coinsToNext));
}


@override
int get hashCode => Object.hash(runtimeType,total,nextThreshold,coinsToNext);

@override
String toString() {
  return 'CoinBalance(total: $total, nextThreshold: $nextThreshold, coinsToNext: $coinsToNext)';
}


}

/// @nodoc
abstract mixin class _$CoinBalanceCopyWith<$Res> implements $CoinBalanceCopyWith<$Res> {
  factory _$CoinBalanceCopyWith(_CoinBalance value, $Res Function(_CoinBalance) _then) = __$CoinBalanceCopyWithImpl;
@override @useResult
$Res call({
 int total, int nextThreshold, int coinsToNext
});




}
/// @nodoc
class __$CoinBalanceCopyWithImpl<$Res>
    implements _$CoinBalanceCopyWith<$Res> {
  __$CoinBalanceCopyWithImpl(this._self, this._then);

  final _CoinBalance _self;
  final $Res Function(_CoinBalance) _then;

/// Create a copy of CoinBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? nextThreshold = null,Object? coinsToNext = null,}) {
  return _then(_CoinBalance(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,nextThreshold: null == nextThreshold ? _self.nextThreshold : nextThreshold // ignore: cast_nullable_to_non_nullable
as int,coinsToNext: null == coinsToNext ? _self.coinsToNext : coinsToNext // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
