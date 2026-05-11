import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'catalog_notifier.dart';

part 'search_notifier.g.dart';

/// Manages the search query text and debounces keystrokes before delegating
/// the actual search to [CatalogNotifier].
///
/// State type: [String] — the current raw query text shown in the search field.
///
/// The debounce window is 300 ms. On every keystroke [state] is updated
/// immediately so the text field stays in sync, but the call to
/// [CatalogNotifier.search] is deferred until the user stops typing.
@riverpod
class SearchNotifier extends _$SearchNotifier {
  Timer? _debounceTimer;

  @override
  String build() {
    // Cancel the debounce timer when the provider is disposed to prevent
    // memory leaks and stale callbacks.
    ref.onDispose(() => _debounceTimer?.cancel());
    return ''; // initial query is empty
  }

  /// Called on every keystroke. Updates [state] immediately for UI
  /// responsiveness, then debounces 300 ms before triggering the search.
  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    state = query;

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(catalogNotifierProvider.notifier).search(query);
    });
  }

  /// Clears the search query, cancels any pending debounce timer, and
  /// instructs [CatalogNotifier] to restore the unfiltered meal list.
  void clear() {
    _debounceTimer?.cancel();
    state = '';
    ref.read(catalogNotifierProvider.notifier).clearSearch();
  }
}
