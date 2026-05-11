// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Meal {

 String get id; String get name; String get description;/// Price in XOF (West African CFA franc). Must be > 0.
 double get price; String get categoryId; List<String> get imageUrls; bool get isAvailable; bool get isFeatured;/// Admin-defined display order within the featured section.
 int get featuredOrder;/// Optional nutritional breakdown. Null when not provided by admin.
 NutritionalInfo? get nutritionalInfo;/// Dietary labels, e.g. ['vegetarian', 'vegan', 'gluten-free', 'spicy', 'halal'].
 List<String> get dietaryTags;/// Incremented on each order; used for popularity-based sorting.
 int get popularityScore; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealCopyWith<Meal> get copyWith => _$MealCopyWithImpl<Meal>(this as Meal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Meal&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.imageUrls, imageUrls)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.featuredOrder, featuredOrder) || other.featuredOrder == featuredOrder)&&(identical(other.nutritionalInfo, nutritionalInfo) || other.nutritionalInfo == nutritionalInfo)&&const DeepCollectionEquality().equals(other.dietaryTags, dietaryTags)&&(identical(other.popularityScore, popularityScore) || other.popularityScore == popularityScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,price,categoryId,const DeepCollectionEquality().hash(imageUrls),isAvailable,isFeatured,featuredOrder,nutritionalInfo,const DeepCollectionEquality().hash(dietaryTags),popularityScore,createdAt,updatedAt);

@override
String toString() {
  return 'Meal(id: $id, name: $name, description: $description, price: $price, categoryId: $categoryId, imageUrls: $imageUrls, isAvailable: $isAvailable, isFeatured: $isFeatured, featuredOrder: $featuredOrder, nutritionalInfo: $nutritionalInfo, dietaryTags: $dietaryTags, popularityScore: $popularityScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MealCopyWith<$Res>  {
  factory $MealCopyWith(Meal value, $Res Function(Meal) _then) = _$MealCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, double price, String categoryId, List<String> imageUrls, bool isAvailable, bool isFeatured, int featuredOrder, NutritionalInfo? nutritionalInfo, List<String> dietaryTags, int popularityScore, DateTime createdAt, DateTime updatedAt
});


$NutritionalInfoCopyWith<$Res>? get nutritionalInfo;

}
/// @nodoc
class _$MealCopyWithImpl<$Res>
    implements $MealCopyWith<$Res> {
  _$MealCopyWithImpl(this._self, this._then);

  final Meal _self;
  final $Res Function(Meal) _then;

/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? price = null,Object? categoryId = null,Object? imageUrls = null,Object? isAvailable = null,Object? isFeatured = null,Object? featuredOrder = null,Object? nutritionalInfo = freezed,Object? dietaryTags = null,Object? popularityScore = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,imageUrls: null == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,featuredOrder: null == featuredOrder ? _self.featuredOrder : featuredOrder // ignore: cast_nullable_to_non_nullable
as int,nutritionalInfo: freezed == nutritionalInfo ? _self.nutritionalInfo : nutritionalInfo // ignore: cast_nullable_to_non_nullable
as NutritionalInfo?,dietaryTags: null == dietaryTags ? _self.dietaryTags : dietaryTags // ignore: cast_nullable_to_non_nullable
as List<String>,popularityScore: null == popularityScore ? _self.popularityScore : popularityScore // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NutritionalInfoCopyWith<$Res>? get nutritionalInfo {
    if (_self.nutritionalInfo == null) {
    return null;
  }

  return $NutritionalInfoCopyWith<$Res>(_self.nutritionalInfo!, (value) {
    return _then(_self.copyWith(nutritionalInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [Meal].
extension MealPatterns on Meal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Meal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Meal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Meal value)  $default,){
final _that = this;
switch (_that) {
case _Meal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Meal value)?  $default,){
final _that = this;
switch (_that) {
case _Meal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  double price,  String categoryId,  List<String> imageUrls,  bool isAvailable,  bool isFeatured,  int featuredOrder,  NutritionalInfo? nutritionalInfo,  List<String> dietaryTags,  int popularityScore,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Meal() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.price,_that.categoryId,_that.imageUrls,_that.isAvailable,_that.isFeatured,_that.featuredOrder,_that.nutritionalInfo,_that.dietaryTags,_that.popularityScore,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  double price,  String categoryId,  List<String> imageUrls,  bool isAvailable,  bool isFeatured,  int featuredOrder,  NutritionalInfo? nutritionalInfo,  List<String> dietaryTags,  int popularityScore,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Meal():
return $default(_that.id,_that.name,_that.description,_that.price,_that.categoryId,_that.imageUrls,_that.isAvailable,_that.isFeatured,_that.featuredOrder,_that.nutritionalInfo,_that.dietaryTags,_that.popularityScore,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  double price,  String categoryId,  List<String> imageUrls,  bool isAvailable,  bool isFeatured,  int featuredOrder,  NutritionalInfo? nutritionalInfo,  List<String> dietaryTags,  int popularityScore,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Meal() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.price,_that.categoryId,_that.imageUrls,_that.isAvailable,_that.isFeatured,_that.featuredOrder,_that.nutritionalInfo,_that.dietaryTags,_that.popularityScore,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Meal extends Meal {
  const _Meal({required this.id, required this.name, required this.description, required this.price, required this.categoryId, required final  List<String> imageUrls, required this.isAvailable, required this.isFeatured, required this.featuredOrder, this.nutritionalInfo, required final  List<String> dietaryTags, required this.popularityScore, required this.createdAt, required this.updatedAt}): _imageUrls = imageUrls,_dietaryTags = dietaryTags,super._();
  

@override final  String id;
@override final  String name;
@override final  String description;
/// Price in XOF (West African CFA franc). Must be > 0.
@override final  double price;
@override final  String categoryId;
 final  List<String> _imageUrls;
@override List<String> get imageUrls {
  if (_imageUrls is EqualUnmodifiableListView) return _imageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageUrls);
}

@override final  bool isAvailable;
@override final  bool isFeatured;
/// Admin-defined display order within the featured section.
@override final  int featuredOrder;
/// Optional nutritional breakdown. Null when not provided by admin.
@override final  NutritionalInfo? nutritionalInfo;
/// Dietary labels, e.g. ['vegetarian', 'vegan', 'gluten-free', 'spicy', 'halal'].
 final  List<String> _dietaryTags;
/// Dietary labels, e.g. ['vegetarian', 'vegan', 'gluten-free', 'spicy', 'halal'].
@override List<String> get dietaryTags {
  if (_dietaryTags is EqualUnmodifiableListView) return _dietaryTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryTags);
}

/// Incremented on each order; used for popularity-based sorting.
@override final  int popularityScore;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealCopyWith<_Meal> get copyWith => __$MealCopyWithImpl<_Meal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Meal&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.price, price) || other.price == price)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other._imageUrls, _imageUrls)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.featuredOrder, featuredOrder) || other.featuredOrder == featuredOrder)&&(identical(other.nutritionalInfo, nutritionalInfo) || other.nutritionalInfo == nutritionalInfo)&&const DeepCollectionEquality().equals(other._dietaryTags, _dietaryTags)&&(identical(other.popularityScore, popularityScore) || other.popularityScore == popularityScore)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,price,categoryId,const DeepCollectionEquality().hash(_imageUrls),isAvailable,isFeatured,featuredOrder,nutritionalInfo,const DeepCollectionEquality().hash(_dietaryTags),popularityScore,createdAt,updatedAt);

@override
String toString() {
  return 'Meal(id: $id, name: $name, description: $description, price: $price, categoryId: $categoryId, imageUrls: $imageUrls, isAvailable: $isAvailable, isFeatured: $isFeatured, featuredOrder: $featuredOrder, nutritionalInfo: $nutritionalInfo, dietaryTags: $dietaryTags, popularityScore: $popularityScore, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MealCopyWith<$Res> implements $MealCopyWith<$Res> {
  factory _$MealCopyWith(_Meal value, $Res Function(_Meal) _then) = __$MealCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, double price, String categoryId, List<String> imageUrls, bool isAvailable, bool isFeatured, int featuredOrder, NutritionalInfo? nutritionalInfo, List<String> dietaryTags, int popularityScore, DateTime createdAt, DateTime updatedAt
});


@override $NutritionalInfoCopyWith<$Res>? get nutritionalInfo;

}
/// @nodoc
class __$MealCopyWithImpl<$Res>
    implements _$MealCopyWith<$Res> {
  __$MealCopyWithImpl(this._self, this._then);

  final _Meal _self;
  final $Res Function(_Meal) _then;

/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? price = null,Object? categoryId = null,Object? imageUrls = null,Object? isAvailable = null,Object? isFeatured = null,Object? featuredOrder = null,Object? nutritionalInfo = freezed,Object? dietaryTags = null,Object? popularityScore = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Meal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,imageUrls: null == imageUrls ? _self._imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,featuredOrder: null == featuredOrder ? _self.featuredOrder : featuredOrder // ignore: cast_nullable_to_non_nullable
as int,nutritionalInfo: freezed == nutritionalInfo ? _self.nutritionalInfo : nutritionalInfo // ignore: cast_nullable_to_non_nullable
as NutritionalInfo?,dietaryTags: null == dietaryTags ? _self._dietaryTags : dietaryTags // ignore: cast_nullable_to_non_nullable
as List<String>,popularityScore: null == popularityScore ? _self.popularityScore : popularityScore // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Meal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NutritionalInfoCopyWith<$Res>? get nutritionalInfo {
    if (_self.nutritionalInfo == null) {
    return null;
  }

  return $NutritionalInfoCopyWith<$Res>(_self.nutritionalInfo!, (value) {
    return _then(_self.copyWith(nutritionalInfo: value));
  });
}
}

// dart format on
