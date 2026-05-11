// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coin_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoinTransaction {

 String get id; String get uid; int get amount; String get reason; String? get orderId; DateTime get timestamp;
/// Create a copy of CoinTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoinTransactionCopyWith<CoinTransaction> get copyWith => _$CoinTransactionCopyWithImpl<CoinTransaction>(this as CoinTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoinTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,id,uid,amount,reason,orderId,timestamp);

@override
String toString() {
  return 'CoinTransaction(id: $id, uid: $uid, amount: $amount, reason: $reason, orderId: $orderId, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $CoinTransactionCopyWith<$Res>  {
  factory $CoinTransactionCopyWith(CoinTransaction value, $Res Function(CoinTransaction) _then) = _$CoinTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String uid, int amount, String reason, String? orderId, DateTime timestamp
});




}
/// @nodoc
class _$CoinTransactionCopyWithImpl<$Res>
    implements $CoinTransactionCopyWith<$Res> {
  _$CoinTransactionCopyWithImpl(this._self, this._then);

  final CoinTransaction _self;
  final $Res Function(CoinTransaction) _then;

/// Create a copy of CoinTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uid = null,Object? amount = null,Object? reason = null,Object? orderId = freezed,Object? timestamp = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CoinTransaction].
extension CoinTransactionPatterns on CoinTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoinTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoinTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoinTransaction value)  $default,){
final _that = this;
switch (_that) {
case _CoinTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoinTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _CoinTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String uid,  int amount,  String reason,  String? orderId,  DateTime timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoinTransaction() when $default != null:
return $default(_that.id,_that.uid,_that.amount,_that.reason,_that.orderId,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String uid,  int amount,  String reason,  String? orderId,  DateTime timestamp)  $default,) {final _that = this;
switch (_that) {
case _CoinTransaction():
return $default(_that.id,_that.uid,_that.amount,_that.reason,_that.orderId,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String uid,  int amount,  String reason,  String? orderId,  DateTime timestamp)?  $default,) {final _that = this;
switch (_that) {
case _CoinTransaction() when $default != null:
return $default(_that.id,_that.uid,_that.amount,_that.reason,_that.orderId,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc


class _CoinTransaction extends CoinTransaction {
  const _CoinTransaction({required this.id, required this.uid, required this.amount, required this.reason, this.orderId, required this.timestamp}): super._();
  

@override final  String id;
@override final  String uid;
@override final  int amount;
@override final  String reason;
@override final  String? orderId;
@override final  DateTime timestamp;

/// Create a copy of CoinTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoinTransactionCopyWith<_CoinTransaction> get copyWith => __$CoinTransactionCopyWithImpl<_CoinTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoinTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,id,uid,amount,reason,orderId,timestamp);

@override
String toString() {
  return 'CoinTransaction(id: $id, uid: $uid, amount: $amount, reason: $reason, orderId: $orderId, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$CoinTransactionCopyWith<$Res> implements $CoinTransactionCopyWith<$Res> {
  factory _$CoinTransactionCopyWith(_CoinTransaction value, $Res Function(_CoinTransaction) _then) = __$CoinTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String uid, int amount, String reason, String? orderId, DateTime timestamp
});




}
/// @nodoc
class __$CoinTransactionCopyWithImpl<$Res>
    implements _$CoinTransactionCopyWith<$Res> {
  __$CoinTransactionCopyWithImpl(this._self, this._then);

  final _CoinTransaction _self;
  final $Res Function(_CoinTransaction) _then;

/// Create a copy of CoinTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? uid = null,Object? amount = null,Object? reason = null,Object? orderId = freezed,Object? timestamp = null,}) {
  return _then(_CoinTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String?,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
