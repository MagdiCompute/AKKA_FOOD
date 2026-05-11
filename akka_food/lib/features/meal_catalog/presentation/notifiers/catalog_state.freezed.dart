// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogState {

/// Full list of meals fetched from the network / cache.
/// Subsequent pages are appended here on [CatalogNotifier.loadMore].
 List<Meal> get allMeals;/// Result of running [allMeals] through the active filter + sort pipeline.
/// This is what the UI renders.
 List<Meal> get filteredMeals;/// Currently active filter. Defaults to [MealFilter.empty] (no-op).
 MealFilter get activeFilter;/// Currently active sort option. Defaults to [MealSortOption.newestFirst].
 MealSortOption get sortOption;/// True while the initial page is being fetched.
 bool get isLoading;/// True while a subsequent page is being fetched (pagination).
 bool get isLoadingMore;/// True when the repository indicates more pages are available.
 bool get hasMore;/// Non-null when the last operation produced an error.
 String? get error;/// The current search query, or null when no search is active.
 String? get searchQuery;/// Firestore cursor pointing to the last document of the most recently
/// fetched page. Passed as [startAfterDocument] on the next [loadMore].
 dynamic get lastDocument;
/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogStateCopyWith<CatalogState> get copyWith => _$CatalogStateCopyWithImpl<CatalogState>(this as CatalogState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogState&&const DeepCollectionEquality().equals(other.allMeals, allMeals)&&const DeepCollectionEquality().equals(other.filteredMeals, filteredMeals)&&(identical(other.activeFilter, activeFilter) || other.activeFilter == activeFilter)&&(identical(other.sortOption, sortOption) || other.sortOption == sortOption)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&const DeepCollectionEquality().equals(other.lastDocument, lastDocument));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(allMeals),const DeepCollectionEquality().hash(filteredMeals),activeFilter,sortOption,isLoading,isLoadingMore,hasMore,error,searchQuery,const DeepCollectionEquality().hash(lastDocument));

@override
String toString() {
  return 'CatalogState(allMeals: $allMeals, filteredMeals: $filteredMeals, activeFilter: $activeFilter, sortOption: $sortOption, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, error: $error, searchQuery: $searchQuery, lastDocument: $lastDocument)';
}


}

/// @nodoc
abstract mixin class $CatalogStateCopyWith<$Res>  {
  factory $CatalogStateCopyWith(CatalogState value, $Res Function(CatalogState) _then) = _$CatalogStateCopyWithImpl;
@useResult
$Res call({
 List<Meal> allMeals, List<Meal> filteredMeals, MealFilter activeFilter, MealSortOption sortOption, bool isLoading, bool isLoadingMore, bool hasMore, String? error, String? searchQuery, dynamic lastDocument
});


$MealFilterCopyWith<$Res> get activeFilter;

}
/// @nodoc
class _$CatalogStateCopyWithImpl<$Res>
    implements $CatalogStateCopyWith<$Res> {
  _$CatalogStateCopyWithImpl(this._self, this._then);

  final CatalogState _self;
  final $Res Function(CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allMeals = null,Object? filteredMeals = null,Object? activeFilter = null,Object? sortOption = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? error = freezed,Object? searchQuery = freezed,Object? lastDocument = freezed,}) {
  return _then(_self.copyWith(
allMeals: null == allMeals ? _self.allMeals : allMeals // ignore: cast_nullable_to_non_nullable
as List<Meal>,filteredMeals: null == filteredMeals ? _self.filteredMeals : filteredMeals // ignore: cast_nullable_to_non_nullable
as List<Meal>,activeFilter: null == activeFilter ? _self.activeFilter : activeFilter // ignore: cast_nullable_to_non_nullable
as MealFilter,sortOption: null == sortOption ? _self.sortOption : sortOption // ignore: cast_nullable_to_non_nullable
as MealSortOption,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: freezed == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String?,lastDocument: freezed == lastDocument ? _self.lastDocument : lastDocument // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}
/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MealFilterCopyWith<$Res> get activeFilter {
  
  return $MealFilterCopyWith<$Res>(_self.activeFilter, (value) {
    return _then(_self.copyWith(activeFilter: value));
  });
}
}


/// Adds pattern-matching-related methods to [CatalogState].
extension CatalogStatePatterns on CatalogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogState value)  $default,){
final _that = this;
switch (_that) {
case _CatalogState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogState value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Meal> allMeals,  List<Meal> filteredMeals,  MealFilter activeFilter,  MealSortOption sortOption,  bool isLoading,  bool isLoadingMore,  bool hasMore,  String? error,  String? searchQuery,  dynamic lastDocument)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.allMeals,_that.filteredMeals,_that.activeFilter,_that.sortOption,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.error,_that.searchQuery,_that.lastDocument);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Meal> allMeals,  List<Meal> filteredMeals,  MealFilter activeFilter,  MealSortOption sortOption,  bool isLoading,  bool isLoadingMore,  bool hasMore,  String? error,  String? searchQuery,  dynamic lastDocument)  $default,) {final _that = this;
switch (_that) {
case _CatalogState():
return $default(_that.allMeals,_that.filteredMeals,_that.activeFilter,_that.sortOption,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.error,_that.searchQuery,_that.lastDocument);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Meal> allMeals,  List<Meal> filteredMeals,  MealFilter activeFilter,  MealSortOption sortOption,  bool isLoading,  bool isLoadingMore,  bool hasMore,  String? error,  String? searchQuery,  dynamic lastDocument)?  $default,) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.allMeals,_that.filteredMeals,_that.activeFilter,_that.sortOption,_that.isLoading,_that.isLoadingMore,_that.hasMore,_that.error,_that.searchQuery,_that.lastDocument);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogState extends CatalogState {
  const _CatalogState({required final  List<Meal> allMeals, required final  List<Meal> filteredMeals, required this.activeFilter, required this.sortOption, required this.isLoading, required this.isLoadingMore, required this.hasMore, this.error, this.searchQuery, this.lastDocument}): _allMeals = allMeals,_filteredMeals = filteredMeals,super._();
  

/// Full list of meals fetched from the network / cache.
/// Subsequent pages are appended here on [CatalogNotifier.loadMore].
 final  List<Meal> _allMeals;
/// Full list of meals fetched from the network / cache.
/// Subsequent pages are appended here on [CatalogNotifier.loadMore].
@override List<Meal> get allMeals {
  if (_allMeals is EqualUnmodifiableListView) return _allMeals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allMeals);
}

/// Result of running [allMeals] through the active filter + sort pipeline.
/// This is what the UI renders.
 final  List<Meal> _filteredMeals;
/// Result of running [allMeals] through the active filter + sort pipeline.
/// This is what the UI renders.
@override List<Meal> get filteredMeals {
  if (_filteredMeals is EqualUnmodifiableListView) return _filteredMeals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filteredMeals);
}

/// Currently active filter. Defaults to [MealFilter.empty] (no-op).
@override final  MealFilter activeFilter;
/// Currently active sort option. Defaults to [MealSortOption.newestFirst].
@override final  MealSortOption sortOption;
/// True while the initial page is being fetched.
@override final  bool isLoading;
/// True while a subsequent page is being fetched (pagination).
@override final  bool isLoadingMore;
/// True when the repository indicates more pages are available.
@override final  bool hasMore;
/// Non-null when the last operation produced an error.
@override final  String? error;
/// The current search query, or null when no search is active.
@override final  String? searchQuery;
/// Firestore cursor pointing to the last document of the most recently
/// fetched page. Passed as [startAfterDocument] on the next [loadMore].
@override final  dynamic lastDocument;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogStateCopyWith<_CatalogState> get copyWith => __$CatalogStateCopyWithImpl<_CatalogState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogState&&const DeepCollectionEquality().equals(other._allMeals, _allMeals)&&const DeepCollectionEquality().equals(other._filteredMeals, _filteredMeals)&&(identical(other.activeFilter, activeFilter) || other.activeFilter == activeFilter)&&(identical(other.sortOption, sortOption) || other.sortOption == sortOption)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&const DeepCollectionEquality().equals(other.lastDocument, lastDocument));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allMeals),const DeepCollectionEquality().hash(_filteredMeals),activeFilter,sortOption,isLoading,isLoadingMore,hasMore,error,searchQuery,const DeepCollectionEquality().hash(lastDocument));

@override
String toString() {
  return 'CatalogState(allMeals: $allMeals, filteredMeals: $filteredMeals, activeFilter: $activeFilter, sortOption: $sortOption, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasMore: $hasMore, error: $error, searchQuery: $searchQuery, lastDocument: $lastDocument)';
}


}

/// @nodoc
abstract mixin class _$CatalogStateCopyWith<$Res> implements $CatalogStateCopyWith<$Res> {
  factory _$CatalogStateCopyWith(_CatalogState value, $Res Function(_CatalogState) _then) = __$CatalogStateCopyWithImpl;
@override @useResult
$Res call({
 List<Meal> allMeals, List<Meal> filteredMeals, MealFilter activeFilter, MealSortOption sortOption, bool isLoading, bool isLoadingMore, bool hasMore, String? error, String? searchQuery, dynamic lastDocument
});


@override $MealFilterCopyWith<$Res> get activeFilter;

}
/// @nodoc
class __$CatalogStateCopyWithImpl<$Res>
    implements _$CatalogStateCopyWith<$Res> {
  __$CatalogStateCopyWithImpl(this._self, this._then);

  final _CatalogState _self;
  final $Res Function(_CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allMeals = null,Object? filteredMeals = null,Object? activeFilter = null,Object? sortOption = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasMore = null,Object? error = freezed,Object? searchQuery = freezed,Object? lastDocument = freezed,}) {
  return _then(_CatalogState(
allMeals: null == allMeals ? _self._allMeals : allMeals // ignore: cast_nullable_to_non_nullable
as List<Meal>,filteredMeals: null == filteredMeals ? _self._filteredMeals : filteredMeals // ignore: cast_nullable_to_non_nullable
as List<Meal>,activeFilter: null == activeFilter ? _self.activeFilter : activeFilter // ignore: cast_nullable_to_non_nullable
as MealFilter,sortOption: null == sortOption ? _self.sortOption : sortOption // ignore: cast_nullable_to_non_nullable
as MealSortOption,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: freezed == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String?,lastDocument: freezed == lastDocument ? _self.lastDocument : lastDocument // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MealFilterCopyWith<$Res> get activeFilter {
  
  return $MealFilterCopyWith<$Res>(_self.activeFilter, (value) {
    return _then(_self.copyWith(activeFilter: value));
  });
}
}

// dart format on
