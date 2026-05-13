import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../notifiers/admin_user_notifier.dart';

/// Displays a searchable list of all registered users.
///
/// Shows display name, email, registration date, and order count.
/// Satisfies Requirement 6.1.
class AdminUserListScreen extends ConsumerStatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  ConsumerState<AdminUserListScreen> createState() =>
      _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(adminUserNotifierProvider.notifier).setSearchQuery(value);
    });
  }

  Future<void> _onRefresh() async {
    // Invalidating the provider causes the notifier to rebuild and
    // re-subscribe to the Firestore stream, effectively refreshing the data.
    ref.invalidate(adminUserNotifierProvider);
    // Wait briefly so the RefreshIndicator spinner is visible.
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(adminUserNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou e-mail…',
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: userState.whenOrNull(
                  data: (state) => state.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _debounce?.cancel();
                            ref
                                .read(adminUserNotifierProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // ── User list ───────────────────────────────────────────────────
          Expanded(
            child: userState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Échec du chargement des utilisateurs.\n$error',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (state) {
                final users = state.filteredUsers;
                if (users.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              state.allUsers.isEmpty
                                  ? 'Aucun utilisateur inscrit.'
                                  : 'Aucun utilisateur ne correspond à votre recherche.',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        key: ValueKey(user.uid),
                        leading: CircleAvatar(
                          backgroundColor: user.isDeactivated
                              ? colorScheme.errorContainer
                              : colorScheme.primaryContainer,
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: user.isDeactivated
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isDeactivated)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Désactivé',                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${user.email ?? 'Pas d\'e-mail'} · '
                          '${user.orderCount} commandes · '
                          'Inscrit le ${_formatDate(user.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/admin/users/${user.uid}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
