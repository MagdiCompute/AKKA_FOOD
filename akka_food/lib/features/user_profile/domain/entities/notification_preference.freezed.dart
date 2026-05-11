// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_preference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationPreference {

 String get uid; bool get orderUpdates; bool get promotions; bool get coinEvents;
/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferenceCopyWith<NotificationPreference> get copyWith => _$NotificationPreferenceCopyWithImpl<NotificationPreference>(this as NotificationPreference, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreference&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.orderUpdates, orderUpdates) || other.orderUpdates == orderUpdates)&&(identical(other.promotions, promotions) || other.promotions == promotions)&&(identical(other.coinEvents, coinEvents) || other.coinEvents == coinEvents));
}


@override
int get hashCode => Object.hash(runtimeType,uid,orderUpdates,promotions,coinEvents);

@override
String toString() {
  return 'NotificationPreference(uid: $uid, orderUpdates: $orderUpdates, promotions: $promotions, coinEvents: $coinEvents)';
}


}

/// @nodoc
abstract mixin class $NotificationPreferenceCopyWith<$Res>  {
  factory $NotificationPreferenceCopyWith(NotificationPreference value, $Res Function(NotificationPreference) _then) = _$NotificationPreferenceCopyWithImpl;
@useResult
$Res call({
 String uid, bool orderUpdates, bool promotions, bool coinEvents
});




}
/// @nodoc
class _$NotificationPreferenceCopyWithImpl<$Res>
    implements $NotificationPreferenceCopyWith<$Res> {
  _$NotificationPreferenceCopyWithImpl(this._self, this._then);

  final NotificationPreference _self;
  final $Res Function(NotificationPreference) _then;

/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? orderUpdates = null,Object? promotions = null,Object? coinEvents = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,orderUpdates: null == orderUpdates ? _self.orderUpdates : orderUpdates // ignore: cast_nullable_to_non_nullable
as bool,promotions: null == promotions ? _self.promotions : promotions // ignore: cast_nullable_to_non_nullable
as bool,coinEvents: null == coinEvents ? _self.coinEvents : coinEvents // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreference].
extension NotificationPreferencePatterns on NotificationPreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreference value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreference value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  bool orderUpdates,  bool promotions,  bool coinEvents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
return $default(_that.uid,_that.orderUpdates,_that.promotions,_that.coinEvents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  bool orderUpdates,  bool promotions,  bool coinEvents)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreference():
return $default(_that.uid,_that.orderUpdates,_that.promotions,_that.coinEvents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  bool orderUpdates,  bool promotions,  bool coinEvents)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreference() when $default != null:
return $default(_that.uid,_that.orderUpdates,_that.promotions,_that.coinEvents);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationPreference extends NotificationPreference {
  const _NotificationPreference({required this.uid, this.orderUpdates = true, this.promotions = true, this.coinEvents = true}): super._();
  

@override final  String uid;
@override@JsonKey() final  bool orderUpdates;
@override@JsonKey() final  bool promotions;
@override@JsonKey() final  bool coinEvents;

/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferenceCopyWith<_NotificationPreference> get copyWith => __$NotificationPreferenceCopyWithImpl<_NotificationPreference>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreference&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.orderUpdates, orderUpdates) || other.orderUpdates == orderUpdates)&&(identical(other.promotions, promotions) || other.promotions == promotions)&&(identical(other.coinEvents, coinEvents) || other.coinEvents == coinEvents));
}


@override
int get hashCode => Object.hash(runtimeType,uid,orderUpdates,promotions,coinEvents);

@override
String toString() {
  return 'NotificationPreference(uid: $uid, orderUpdates: $orderUpdates, promotions: $promotions, coinEvents: $coinEvents)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferenceCopyWith<$Res> implements $NotificationPreferenceCopyWith<$Res> {
  factory _$NotificationPreferenceCopyWith(_NotificationPreference value, $Res Function(_NotificationPreference) _then) = __$NotificationPreferenceCopyWithImpl;
@override @useResult
$Res call({
 String uid, bool orderUpdates, bool promotions, bool coinEvents
});




}
/// @nodoc
class __$NotificationPreferenceCopyWithImpl<$Res>
    implements _$NotificationPreferenceCopyWith<$Res> {
  __$NotificationPreferenceCopyWithImpl(this._self, this._then);

  final _NotificationPreference _self;
  final $Res Function(_NotificationPreference) _then;

/// Create a copy of NotificationPreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? orderUpdates = null,Object? promotions = null,Object? coinEvents = null,}) {
  return _then(_NotificationPreference(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,orderUpdates: null == orderUpdates ? _self.orderUpdates : orderUpdates // ignore: cast_nullable_to_non_nullable
as bool,promotions: null == promotions ? _self.promotions : promotions // ignore: cast_nullable_to_non_nullable
as bool,coinEvents: null == coinEvents ? _self.coinEvents : coinEvents // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
