// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_validation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CartValidationResult {

 bool get isValid; List<String> get unavailableMealIds; bool get missingDeliveryAddress; bool get emptyCart;
/// Create a copy of CartValidationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartValidationResultCopyWith<CartValidationResult> get copyWith => _$CartValidationResultCopyWithImpl<CartValidationResult>(this as CartValidationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartValidationResult&&(identical(other.isValid, isValid) || other.isValid == isValid)&&const DeepCollectionEquality().equals(other.unavailableMealIds, unavailableMealIds)&&(identical(other.missingDeliveryAddress, missingDeliveryAddress) || other.missingDeliveryAddress == missingDeliveryAddress)&&(identical(other.emptyCart, emptyCart) || other.emptyCart == emptyCart));
}


@override
int get hashCode => Object.hash(runtimeType,isValid,const DeepCollectionEquality().hash(unavailableMealIds),missingDeliveryAddress,emptyCart);

@override
String toString() {
  return 'CartValidationResult(isValid: $isValid, unavailableMealIds: $unavailableMealIds, missingDeliveryAddress: $missingDeliveryAddress, emptyCart: $emptyCart)';
}


}

/// @nodoc
abstract mixin class $CartValidationResultCopyWith<$Res>  {
  factory $CartValidationResultCopyWith(CartValidationResult value, $Res Function(CartValidationResult) _then) = _$CartValidationResultCopyWithImpl;
@useResult
$Res call({
 bool isValid, List<String> unavailableMealIds, bool missingDeliveryAddress, bool emptyCart
});




}
/// @nodoc
class _$CartValidationResultCopyWithImpl<$Res>
    implements $CartValidationResultCopyWith<$Res> {
  _$CartValidationResultCopyWithImpl(this._self, this._then);

  final CartValidationResult _self;
  final $Res Function(CartValidationResult) _then;

/// Create a copy of CartValidationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isValid = null,Object? unavailableMealIds = null,Object? missingDeliveryAddress = null,Object? emptyCart = null,}) {
  return _then(_self.copyWith(
isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,unavailableMealIds: null == unavailableMealIds ? _self.unavailableMealIds : unavailableMealIds // ignore: cast_nullable_to_non_nullable
as List<String>,missingDeliveryAddress: null == missingDeliveryAddress ? _self.missingDeliveryAddress : missingDeliveryAddress // ignore: cast_nullable_to_non_nullable
as bool,emptyCart: null == emptyCart ? _self.emptyCart : emptyCart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CartValidationResult].
extension CartValidationResultPatterns on CartValidationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartValidationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartValidationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartValidationResult value)  $default,){
final _that = this;
switch (_that) {
case _CartValidationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartValidationResult value)?  $default,){
final _that = this;
switch (_that) {
case _CartValidationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isValid,  List<String> unavailableMealIds,  bool missingDeliveryAddress,  bool emptyCart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartValidationResult() when $default != null:
return $default(_that.isValid,_that.unavailableMealIds,_that.missingDeliveryAddress,_that.emptyCart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isValid,  List<String> unavailableMealIds,  bool missingDeliveryAddress,  bool emptyCart)  $default,) {final _that = this;
switch (_that) {
case _CartValidationResult():
return $default(_that.isValid,_that.unavailableMealIds,_that.missingDeliveryAddress,_that.emptyCart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isValid,  List<String> unavailableMealIds,  bool missingDeliveryAddress,  bool emptyCart)?  $default,) {final _that = this;
switch (_that) {
case _CartValidationResult() when $default != null:
return $default(_that.isValid,_that.unavailableMealIds,_that.missingDeliveryAddress,_that.emptyCart);case _:
  return null;

}
}

}

/// @nodoc


class _CartValidationResult extends CartValidationResult {
  const _CartValidationResult({required this.isValid, required final  List<String> unavailableMealIds, required this.missingDeliveryAddress, required this.emptyCart}): _unavailableMealIds = unavailableMealIds,super._();
  

@override final  bool isValid;
 final  List<String> _unavailableMealIds;
@override List<String> get unavailableMealIds {
  if (_unavailableMealIds is EqualUnmodifiableListView) return _unavailableMealIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unavailableMealIds);
}

@override final  bool missingDeliveryAddress;
@override final  bool emptyCart;

/// Create a copy of CartValidationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartValidationResultCopyWith<_CartValidationResult> get copyWith => __$CartValidationResultCopyWithImpl<_CartValidationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartValidationResult&&(identical(other.isValid, isValid) || other.isValid == isValid)&&const DeepCollectionEquality().equals(other._unavailableMealIds, _unavailableMealIds)&&(identical(other.missingDeliveryAddress, missingDeliveryAddress) || other.missingDeliveryAddress == missingDeliveryAddress)&&(identical(other.emptyCart, emptyCart) || other.emptyCart == emptyCart));
}


@override
int get hashCode => Object.hash(runtimeType,isValid,const DeepCollectionEquality().hash(_unavailableMealIds),missingDeliveryAddress,emptyCart);

@override
String toString() {
  return 'CartValidationResult(isValid: $isValid, unavailableMealIds: $unavailableMealIds, missingDeliveryAddress: $missingDeliveryAddress, emptyCart: $emptyCart)';
}


}

/// @nodoc
abstract mixin class _$CartValidationResultCopyWith<$Res> implements $CartValidationResultCopyWith<$Res> {
  factory _$CartValidationResultCopyWith(_CartValidationResult value, $Res Function(_CartValidationResult) _then) = __$CartValidationResultCopyWithImpl;
@override @useResult
$Res call({
 bool isValid, List<String> unavailableMealIds, bool missingDeliveryAddress, bool emptyCart
});




}
/// @nodoc
class __$CartValidationResultCopyWithImpl<$Res>
    implements _$CartValidationResultCopyWith<$Res> {
  __$CartValidationResultCopyWithImpl(this._self, this._then);

  final _CartValidationResult _self;
  final $Res Function(_CartValidationResult) _then;

/// Create a copy of CartValidationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isValid = null,Object? unavailableMealIds = null,Object? missingDeliveryAddress = null,Object? emptyCart = null,}) {
  return _then(_CartValidationResult(
isValid: null == isValid ? _self.isValid : isValid // ignore: cast_nullable_to_non_nullable
as bool,unavailableMealIds: null == unavailableMealIds ? _self._unavailableMealIds : unavailableMealIds // ignore: cast_nullable_to_non_nullable
as List<String>,missingDeliveryAddress: null == missingDeliveryAddress ? _self.missingDeliveryAddress : missingDeliveryAddress // ignore: cast_nullable_to_non_nullable
as bool,emptyCart: null == emptyCart ? _self.emptyCart : emptyCart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
