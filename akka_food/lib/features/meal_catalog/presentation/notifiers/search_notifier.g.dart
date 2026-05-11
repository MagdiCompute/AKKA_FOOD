// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchNotifierHash() => r'b494eefc66ef4781d184742d3a10ea91f1d27566';

/// Manages the search query text and debounces keystrokes before delegating
/// the actual search to [CatalogNotifier].
///
/// State type: [String] — the current raw query text shown in the search field.
///
/// The debounce window is 300 ms. On every keystroke [state] is updated
/// immediately so the text field stays in sync, but the call to
/// [CatalogNotifier.search] is deferred until the user stops typing.
///
/// Copied from [SearchNotifier].
@ProviderFor(SearchNotifier)
final searchNotifierProvider =
    AutoDisposeNotifierProvider<SearchNotifier, String>.internal(
      SearchNotifier.new,
      name: r'searchNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchNotifier = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
