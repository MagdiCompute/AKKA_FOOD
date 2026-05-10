import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/cloud_function_admin_data_source.dart';
import '../../data/datasources/firestore_admin_meal_data_source.dart';
import '../../data/repositories/admin_meal_repository.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/i_admin_meal_repository.dart';
import '../../domain/usecases/get_admin_meals_use_case.dart';

part 'admin_meal_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the [IAdminMealRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
@riverpod
IAdminMealRepository adminMealRepository(Ref ref) {
  return AdminMealRepository(
    FirestoreAdminMealDataSource(),
    CloudFunctionAdminDataSource(),
  );
}

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Holds the UI state for the admin meal list screen.
class AdminMealState {
  const AdminMealState({
    required this.allMeals,
    this.searchQuery = '',
    this.selectedCategory,
  });

  /// The full unfiltered list of meals from Firestore.
  final List<Meal> allMeals;

  /// Current search query (matches meal name, case-insensitive).
  final String searchQuery;

  /// Currently selected category filter; `null` means "All".
  final String? selectedCategory;

  /// Returns the list of meals after applying search and category filters.
  List<Meal> get filteredMeals {
    var meals = allMeals;

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      meals = meals
          .where((m) => m.name.toLowerCase().contains(query))
          .toList();
    }

    if (selectedCategory != null) {
      meals = meals.where((m) => m.category == selectedCategory).toList();
    }

    return meals;
  }

  /// Returns the sorted, deduplicated list of category names from all meals.
  List<String> get categories {
    final cats = allMeals.map((m) => m.category).toSet().toList()..sort();
    return cats;
  }

  AdminMealState copyWith({
    List<Meal>? allMeals,
    String? searchQuery,
    Object? selectedCategory = _sentinel,
  }) {
    return AdminMealState(
      allMeals: allMeals ?? this.allMeals,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory == _sentinel
          ? this.selectedCategory
          : selectedCategory as String?,
    );
  }
}

// Sentinel value to distinguish "not provided" from explicit null.
const _sentinel = Object();

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for [AdminMealListScreen].
///
/// Listens to the real-time Firestore stream of all meals and exposes
/// search/filter controls.
@riverpod
class AdminMealNotifier extends _$AdminMealNotifier {
  StreamSubscription<List<Meal>>? _subscription;

  @override
  AsyncValue<AdminMealState> build() {
    final repository = ref.watch(adminMealRepositoryProvider);
    final useCase = GetAdminMealsUseCase(repository);

    // Cancel any previous subscription when the notifier is rebuilt.
    ref.onDispose(() => _subscription?.cancel());

    // Start listening to the Firestore stream.
    _subscription = useCase().listen(
      (meals) {
        final current = state.valueOrNull;
        state = AsyncData(
          AdminMealState(
            allMeals: meals,
            searchQuery: current?.searchQuery ?? '',
            selectedCategory: current?.selectedCategory,
          ),
        );
      },
      onError: (Object error, StackTrace stack) {
        state = AsyncError(error, stack);
      },
    );

    return const AsyncLoading();
  }

  /// Updates the search query used to filter meals by name.
  void setSearchQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }

  /// Sets the active category filter.
  ///
  /// Pass `null` to clear the filter and show all categories.
  void setCategory(String? category) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(selectedCategory: category),
    );
  }

  /// Toggles the availability of the meal with [mealId].
  ///
  /// Optimistically updates the local state and writes to Firestore.
  /// On error, reverts the optimistic update.
  Future<void> toggleAvailability(
    String mealId, {
    required bool isAvailable,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update.
    final updatedMeals = current.allMeals.map((m) {
      return m.id == mealId ? m.copyWith(isAvailable: isAvailable) : m;
    }).toList();
    state = AsyncData(current.copyWith(allMeals: updatedMeals));

    try {
      final repository = ref.read(adminMealRepositoryProvider);
      await repository.toggleAvailability(mealId, isAvailable: isAvailable);
    } catch (e, st) {
      // Revert optimistic update on failure.
      state = AsyncData(current);
      // Re-throw so the UI can show an error snackbar.
      Error.throwWithStackTrace(e, st);
    }
  }
}
