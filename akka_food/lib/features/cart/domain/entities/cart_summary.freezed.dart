// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CartSummary {

 List<CartItem> get items; double get subtotal; double get deliveryFee; double get discount; double get total; int get redeemedCoins; DeliveryOption get deliveryOption;@_DeliveryAddressConverter() DeliveryAddress? get deliveryAddress;
/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartSummaryCopyWith<CartSummary> get copyWith => _$CartSummaryCopyWithImpl<CartSummary>(this as CartSummary, _$identity);

  /// Serializes this CartSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartSummary&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.total, total) || other.total == total)&&(identical(other.redeemedCoins, redeemedCoins) || other.redeemedCoins == redeemedCoins)&&(identical(other.deliveryOption, deliveryOption) || other.deliveryOption == deliveryOption)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),subtotal,deliveryFee,discount,total,redeemedCoins,deliveryOption,deliveryAddress);

@override
String toString() {
  return 'CartSummary(items: $items, subtotal: $subtotal, deliveryFee: $deliveryFee, discount: $discount, total: $total, redeemedCoins: $redeemedCoins, deliveryOption: $deliveryOption, deliveryAddress: $deliveryAddress)';
}


}

/// @nodoc
abstract mixin class $CartSummaryCopyWith<$Res>  {
  factory $CartSummaryCopyWith(CartSummary value, $Res Function(CartSummary) _then) = _$CartSummaryCopyWithImpl;
@useResult
$Res call({
 List<CartItem> items, double subtotal, double deliveryFee, double discount, double total, int redeemedCoins, DeliveryOption deliveryOption,@_DeliveryAddressConverter() DeliveryAddress? deliveryAddress
});


$DeliveryAddressCopyWith<$Res>? get deliveryAddress;

}
/// @nodoc
class _$CartSummaryCopyWithImpl<$Res>
    implements $CartSummaryCopyWith<$Res> {
  _$CartSummaryCopyWithImpl(this._self, this._then);

  final CartSummary _self;
  final $Res Function(CartSummary) _then;

/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? subtotal = null,Object? deliveryFee = null,Object? discount = null,Object? total = null,Object? redeemedCoins = null,Object? deliveryOption = null,Object? deliveryAddress = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,deliveryFee: null == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,redeemedCoins: null == redeemedCoins ? _self.redeemedCoins : redeemedCoins // ignore: cast_nullable_to_non_nullable
as int,deliveryOption: null == deliveryOption ? _self.deliveryOption : deliveryOption // ignore: cast_nullable_to_non_nullable
as DeliveryOption,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,
  ));
}
/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get deliveryAddress {
    if (_self.deliveryAddress == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress!, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}
}


/// Adds pattern-matching-related methods to [CartSummary].
extension CartSummaryPatterns on CartSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartSummary value)  $default,){
final _that = this;
switch (_that) {
case _CartSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CartItem> items,  double subtotal,  double deliveryFee,  double discount,  double total,  int redeemedCoins,  DeliveryOption deliveryOption, @_DeliveryAddressConverter()  DeliveryAddress? deliveryAddress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
return $default(_that.items,_that.subtotal,_that.deliveryFee,_that.discount,_that.total,_that.redeemedCoins,_that.deliveryOption,_that.deliveryAddress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CartItem> items,  double subtotal,  double deliveryFee,  double discount,  double total,  int redeemedCoins,  DeliveryOption deliveryOption, @_DeliveryAddressConverter()  DeliveryAddress? deliveryAddress)  $default,) {final _that = this;
switch (_that) {
case _CartSummary():
return $default(_that.items,_that.subtotal,_that.deliveryFee,_that.discount,_that.total,_that.redeemedCoins,_that.deliveryOption,_that.deliveryAddress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CartItem> items,  double subtotal,  double deliveryFee,  double discount,  double total,  int redeemedCoins,  DeliveryOption deliveryOption, @_DeliveryAddressConverter()  DeliveryAddress? deliveryAddress)?  $default,) {final _that = this;
switch (_that) {
case _CartSummary() when $default != null:
return $default(_that.items,_that.subtotal,_that.deliveryFee,_that.discount,_that.total,_that.redeemedCoins,_that.deliveryOption,_that.deliveryAddress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartSummary extends CartSummary {
  const _CartSummary({required final  List<CartItem> items, required this.subtotal, required this.deliveryFee, required this.discount, required this.total, required this.redeemedCoins, required this.deliveryOption, @_DeliveryAddressConverter() this.deliveryAddress}): _items = items,super._();
  factory _CartSummary.fromJson(Map<String, dynamic> json) => _$CartSummaryFromJson(json);

 final  List<CartItem> _items;
@override List<CartItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  double subtotal;
@override final  double deliveryFee;
@override final  double discount;
@override final  double total;
@override final  int redeemedCoins;
@override final  DeliveryOption deliveryOption;
@override@_DeliveryAddressConverter() final  DeliveryAddress? deliveryAddress;

/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartSummaryCopyWith<_CartSummary> get copyWith => __$CartSummaryCopyWithImpl<_CartSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartSummary&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.total, total) || other.total == total)&&(identical(other.redeemedCoins, redeemedCoins) || other.redeemedCoins == redeemedCoins)&&(identical(other.deliveryOption, deliveryOption) || other.deliveryOption == deliveryOption)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),subtotal,deliveryFee,discount,total,redeemedCoins,deliveryOption,deliveryAddress);

@override
String toString() {
  return 'CartSummary(items: $items, subtotal: $subtotal, deliveryFee: $deliveryFee, discount: $discount, total: $total, redeemedCoins: $redeemedCoins, deliveryOption: $deliveryOption, deliveryAddress: $deliveryAddress)';
}


}

/// @nodoc
abstract mixin class _$CartSummaryCopyWith<$Res> implements $CartSummaryCopyWith<$Res> {
  factory _$CartSummaryCopyWith(_CartSummary value, $Res Function(_CartSummary) _then) = __$CartSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<CartItem> items, double subtotal, double deliveryFee, double discount, double total, int redeemedCoins, DeliveryOption deliveryOption,@_DeliveryAddressConverter() DeliveryAddress? deliveryAddress
});


@override $DeliveryAddressCopyWith<$Res>? get deliveryAddress;

}
/// @nodoc
class __$CartSummaryCopyWithImpl<$Res>
    implements _$CartSummaryCopyWith<$Res> {
  __$CartSummaryCopyWithImpl(this._self, this._then);

  final _CartSummary _self;
  final $Res Function(_CartSummary) _then;

/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? subtotal = null,Object? deliveryFee = null,Object? discount = null,Object? total = null,Object? redeemedCoins = null,Object? deliveryOption = null,Object? deliveryAddress = freezed,}) {
  return _then(_CartSummary(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as double,deliveryFee: null == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as double,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,redeemedCoins: null == redeemedCoins ? _self.redeemedCoins : redeemedCoins // ignore: cast_nullable_to_non_nullable
as int,deliveryOption: null == deliveryOption ? _self.deliveryOption : deliveryOption // ignore: cast_nullable_to_non_nullable
as DeliveryOption,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as DeliveryAddress?,
  ));
}

/// Create a copy of CartSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeliveryAddressCopyWith<$Res>? get deliveryAddress {
    if (_self.deliveryAddress == null) {
    return null;
  }

  return $DeliveryAddressCopyWith<$Res>(_self.deliveryAddress!, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}
}

// dart format on
