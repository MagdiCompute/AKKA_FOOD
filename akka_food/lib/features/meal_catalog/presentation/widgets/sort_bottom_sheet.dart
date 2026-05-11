import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_notifier.dart';

/// Human-readable labels for each [MealSortOption].
const _kSortLabels = {
  MealSortOption.priceAsc: 'Price: Low to High',
  MealSortOption.priceDesc: 'Price: High to Low',
  MealSortOption.popularityDesc: 'Most Popular',
  MealSortOption.newestFirst: 'Newest First',
};

/// Icons associated with each [MealSortOption].
const _kSortIcons = {
  MealSortOption.priceAsc: Icons.arrow_upward,
  MealSortOption.priceDesc: Icons.arrow_downward,
  MealSortOption.popularityDesc: Icons.local_fire_department_outlined,
  MealSortOption.newestFirst: Icons.schedule_outlined,
};

/// A modal bottom sheet that lets the user choose a [MealSortOption].
///
/// Selection is immediate — tapping an option applies the sort via
/// [CatalogNotifier.applySort] and dismisses the sheet.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   shape: const RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
///   ),
///   builder: (_) => SortBottomSheet(
///     activeSortOption: catalogAsync.valueOrNull?.sortOption
///         ?? MealSortOption.newestFirst,
///   ),
/// );
/// ```
class SortBottomSheet extends ConsumerWidget {
  const SortBottomSheet({
    super.key,
    required this.activeSortOption,
  });

  /// The currently active sort option — used to highlight the selected row.
  final MealSortOption activeSortOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────
          _buildHeader(context, theme),

          // ── Sort options ──────────────────────────────────────────────
          ...MealSortOption.values.map(
            (option) => _buildSortTile(
              context: context,
              ref: ref,
              option: option,
              colorScheme: colorScheme,
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Text(
            'Sort by',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Individual sort tile
  // ---------------------------------------------------------------------------

  Widget _buildSortTile({
    required BuildContext context,
    required WidgetRef ref,
    required MealSortOption option,
    required ColorScheme colorScheme,
  }) {
    final isActive = option == activeSortOption;
    final label = _kSortLabels[option] ?? option.name;
    final icon = _kSortIcons[option] ?? Icons.sort;

    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? colorScheme.primary : null,
        ),
      ),
      trailing: isActive
          ? Icon(Icons.check_circle, color: colorScheme.primary, size: 22)
          : Icon(
              Icons.radio_button_unchecked,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
      onTap: () {
        ref.read(catalogNotifierProvider.notifier).applySort(option);
        Navigator.pop(context);
      },
    );
  }
}
