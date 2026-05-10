import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/cloud_function_admin_data_source.dart';
import '../../data/datasources/firestore_admin_user_data_source.dart';
import '../../data/repositories/admin_user_repository.dart';
import '../../domain/entities/admin_order_view.dart';
import '../../domain/entities/admin_user_view.dart';
import '../../domain/repositories/i_admin_user_repository.dart';
import '../../domain/usecases/get_admin_users_use_case.dart';
import '../../domain/usecases/get_user_orders_use_case.dart';
import '../../domain/usecases/manage_user_use_case.dart';

part 'admin_user_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

@riverpod
IAdminUserRepository adminUserRepository(Ref ref) {
  return AdminUserRepository(
    FirestoreAdminUserDataSource(),
    CloudFunctionAdminDataSource(),
  );
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminUserState {
  const AdminUserState({
    required this.allUsers,
    this.searchQuery = '',
  });

  final List<AdminUserView> allUsers;
  final String searchQuery;

  List<AdminUserView> get filteredUsers {
    if (searchQuery.isEmpty) return allUsers;
    final q = searchQuery.toLowerCase();
    return allUsers
        .where((u) =>
            u.displayName.toLowerCase().contains(q) ||
            (u.email?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  AdminUserState copyWith({
    List<AdminUserView>? allUsers,
    String? searchQuery,
  }) {
    return AdminUserState(
      allUsers: allUsers ?? this.allUsers,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class AdminUserNotifier extends _$AdminUserNotifier {
  StreamSubscription<List<AdminUserView>>? _subscription;

  @override
  AsyncValue<AdminUserState> build() {
    final repository = ref.watch(adminUserRepositoryProvider);
    final useCase = GetAdminUsersUseCase(repository);

    ref.onDispose(() => _subscription?.cancel());

    _subscription = useCase().listen(
      (users) {
        final current = state.valueOrNull;
        state = AsyncData(AdminUserState(
          allUsers: users,
          searchQuery: current?.searchQuery ?? '',
        ));
      },
      onError: (Object error, StackTrace stack) {
        state = AsyncError(error, stack);
      },
    );

    return const AsyncLoading();
  }

  void setSearchQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }

  /// Deactivates the user with [uid]. Optimistically updates local state.
  Future<void> deactivateUser(String uid) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update.
    final updated = current.allUsers
        .map((u) => u.uid == uid ? u.copyWith(isDeactivated: true) : u)
        .toList();
    state = AsyncData(current.copyWith(allUsers: updated));

    try {
      final repository = ref.read(adminUserRepositoryProvider);
      final useCase = ManageUserUseCase(repository);
      await useCase.deactivate(uid);
    } catch (e, st) {
      // Revert on failure.
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Reactivates the user with [uid]. Optimistically updates local state.
  Future<void> reactivateUser(String uid) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.allUsers
        .map((u) => u.uid == uid ? u.copyWith(isDeactivated: false) : u)
        .toList();
    state = AsyncData(current.copyWith(allUsers: updated));

    try {
      final repository = ref.read(adminUserRepositoryProvider);
      final useCase = ManageUserUseCase(repository);
      await useCase.reactivate(uid);
    } catch (e, st) {
      state = AsyncData(current);
      Error.throwWithStackTrace(e, st);
    }
  }
}

// ---------------------------------------------------------------------------
// User detail state
// ---------------------------------------------------------------------------

/// Holds the combined data for the user detail screen.
class AdminUserDetailState {
  const AdminUserDetailState({
    required this.user,
    required this.orders,
  });

  final AdminUserView user;
  final List<AdminOrderView> orders;
}

// ---------------------------------------------------------------------------
// User detail provider
// ---------------------------------------------------------------------------

/// Fetches a single user and their order history for the detail screen.
///
/// Keyed by [userId] so each user gets its own cached provider instance.
@riverpod
Future<AdminUserDetailState> adminUserDetail(Ref ref, String userId) async {
  final repository = ref.watch(adminUserRepositoryProvider);

  final results = await Future.wait([
    repository.getUserById(userId),
    GetUserOrdersUseCase(repository).call(userId),
  ]);

  final user = results[0] as AdminUserView?;
  final orders = results[1] as List<AdminOrderView>;

  if (user == null) {
    throw Exception('User $userId not found.');
  }

  return AdminUserDetailState(user: user, orders: orders);
}
