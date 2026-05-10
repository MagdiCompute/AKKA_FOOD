import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/cloud_function_admin_data_source.dart';
import '../../data/datasources/firestore_admin_category_data_source.dart';
import '../../data/repositories/admin_category_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/i_admin_category_repository.dart';
import '../../domain/usecases/get_admin_categories_use_case.dart';

part 'admin_category_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the [IAdminCategoryRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
@riverpod
IAdminCategoryRepository adminCategoryRepository(Ref ref) {
  return AdminCategoryRepository(
    FirestoreAdminCategoryDataSource(),
    CloudFunctionAdminDataSource(),
  );
}

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Holds the UI state for the admin category list screen.
class AdminCategoryState {
  const AdminCategoryState({
    required this.allCategories,
    this.searchQuery = '',
  });

  /// The full unfiltered list of categories from Firestore.
  final List<Category> allCategories;

  /// Current search query (matches category name, case-insensitive).
  final String searchQuery;

  /// Returns the list of categories after applying the search filter.
  List<Category> get filteredCategories {
    if (searchQuery.isEmpty) return allCategories;
    final query = searchQuery.toLowerCase();
    return allCategories
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  }

  AdminCategoryState copyWith({
    List<Category>? allCategories,
    String? searchQuery,
  }) {
    return AdminCategoryState(
      allCategories: allCategories ?? this.allCategories,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for [AdminCategoryListScreen].
///
/// Listens to the real-time Firestore stream of all categories and exposes
/// a search control.
///
/// Satisfies Requirement 3.1.
@riverpod
class AdminCategoryNotifier extends _$AdminCategoryNotifier {
  StreamSubscription<List<Category>>? _subscription;

  @override
  AsyncValue<AdminCategoryState> build() {
    final repository = ref.watch(adminCategoryRepositoryProvider);
    final useCase = GetAdminCategoriesUseCase(repository);

    // Cancel any previous subscription when the notifier is rebuilt.
    ref.onDispose(() => _subscription?.cancel());

    // Start listening to the Firestore stream.
    _subscription = useCase().listen(
      (categories) {
        final current = state.valueOrNull;
        state = AsyncData(
          AdminCategoryState(
            allCategories: categories,
            searchQuery: current?.searchQuery ?? '',
          ),
        );
      },
      onError: (Object error, StackTrace stack) {
        state = AsyncError(error, stack);
      },
    );

    return const AsyncLoading();
  }

  /// Updates the search query used to filter categories by name.
  void setSearchQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }
}
