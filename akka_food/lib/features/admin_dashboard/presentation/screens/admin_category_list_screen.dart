import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../notifiers/admin_category_notifier.dart';
import '../widgets/category_list_tile.dart';

/// Displays all categories (active and inactive) with name, image thumbnail,
/// and active/inactive status badge.
///
/// Satisfies Requirement 3.1.
class AdminCategoryListScreen extends ConsumerStatefulWidget {
  const AdminCategoryListScreen({super.key});

  @override
  ConsumerState<AdminCategoryListScreen> createState() =>
      _AdminCategoryListScreenState();
}

class _AdminCategoryListScreenState
    extends ConsumerState<AdminCategoryListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(adminCategoryNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Rechercher des catégories…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(adminCategoryNotifierProvider.notifier)
                          .setSearchQuery('');
                    },
                  ),
              ],
              onChanged: (query) {
                ref
                    .read(adminCategoryNotifierProvider.notifier)
                    .setSearchQuery(query);
              },
            ),
          ),

          // ── Category list ────────────────────────────────────────────────
          Expanded(
            child: categoryState.when(
              data: (state) {
                final categories = state.filteredCategories;

                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.allCategories.isEmpty
                              ? 'Aucune catégorie.\nAppuyez sur + pour ajouter la première.'
                              : 'Aucune catégorie ne correspond à votre recherche.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // The stream auto-refreshes; this gives visual feedback.
                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return CategoryListTile(
                        key: ValueKey(category.id),
                        category: category,
                        onTap: () => context.push(
                          '/admin/categories/${category.id}/edit',
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Échec du chargement des catégories.\n$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── FAB: Add new category ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminCategoryNew),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une catégorie'),
      ),
    );
  }
}
