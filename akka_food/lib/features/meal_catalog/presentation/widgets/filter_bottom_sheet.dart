import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/meal_filter.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/catalog_notifier.dart';
import 'package:akka_food/features/meal_catalog/presentation/notifiers/category_providers.dart';

/// Dietary tag options available for filtering.
const _kDietaryTags = [
  'vegetarian',
  'vegan',
  'gluten-free',
  'spicy',
  'halal',
];

/// Maximum price value for the range slider (in XOF).
const double _kMaxPrice = 50000;

/// Minimum price value for the range slider (in XOF).
const double _kMinPrice = 0;

/// Step size for the price range slider (in XOF).
const double _kPriceStep = 500;

/// A modal bottom sheet that lets the user configure meal catalog filters.
///
/// Maintains a local copy of [MealFilter] while open; changes are only
/// committed to [CatalogNotifier] when the user taps "Apply".
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   shape: const RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
///   ),
///   builder: (_) => FilterBottomSheet(
///     activeFilter: catalogAsync.valueOrNull?.activeFilter ?? MealFilter.empty(),
///   ),
/// );
/// ```
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({
    super.key,
    required this.activeFilter,
  });

  /// The currently active filter — used to pre-populate local state.
  final MealFilter activeFilter;

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  // Local mutable copy of the filter — not applied until "Apply" is tapped.
  late List<String> _categoryIds;
  late double _minPrice;
  late double _maxPrice;
  late List<String> _dietaryTags;
  late bool _availableOnly;

  @override
  void initState() {
    super.initState();
    _initFromFilter(widget.activeFilter);
  }

  void _initFromFilter(MealFilter filter) {
    _categoryIds = List<String>.from(filter.categoryIds);
    _minPrice = filter.minPrice ?? _kMinPrice;
    _maxPrice = filter.maxPrice ?? _kMaxPrice;
    _dietaryTags = List<String>.from(filter.dietaryTags);
    _availableOnly = filter.availableOnly;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _toggleCategory(String id) {
    setState(() {
      if (_categoryIds.contains(id)) {
        _categoryIds.remove(id);
      } else {
        _categoryIds.add(id);
      }
    });
  }

  void _toggleDietaryTag(String tag) {
    setState(() {
      if (_dietaryTags.contains(tag)) {
        _dietaryTags.remove(tag);
      } else {
        _dietaryTags.add(tag);
      }
    });
  }

  void _clear() {
    setState(() {
      _initFromFilter(MealFilter.empty());
    });
  }

  void _apply() {
    final filter = MealFilter(
      categoryIds: List<String>.from(_categoryIds),
      minPrice: _minPrice > _kMinPrice ? _minPrice : null,
      maxPrice: _maxPrice < _kMaxPrice ? _maxPrice : null,
      availableOnly: _availableOnly,
      dietaryTags: List<String>.from(_dietaryTags),
    );
    ref.read(catalogNotifierProvider.notifier).applyFilter(filter);
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _buildHeader(context, theme),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _buildCategoriesSection(theme),
                  const SizedBox(height: 24),
                  _buildPriceRangeSection(theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildDietaryTagsSection(theme),
                  const SizedBox(height: 24),
                  _buildAvailabilitySection(),
                ],
              ),
            ),

            // ── Bottom action buttons ────────────────────────────────────
            _buildBottomButtons(context, theme, colorScheme),
          ],
        );
      },
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
            'Filtres',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Fermer',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Categories section
  // ---------------------------------------------------------------------------

  Widget _buildCategoriesSection(ThemeData theme) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          loading: () => const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => const Text('Impossible de charger les catégories'),
          data: (categories) {
            if (categories.isEmpty) {
              return const Text('Aucune catégorie disponible');
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((category) {
                  final isSelected = _categoryIds.contains(category.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(category.id),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Price range section
  // ---------------------------------------------------------------------------

  Widget _buildPriceRangeSection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fourchette de prix',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_minPrice.toInt()} XOF',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_maxPrice.toInt()} XOF',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(_minPrice, _maxPrice),
          min: _kMinPrice,
          max: _kMaxPrice,
          divisions: (_kMaxPrice / _kPriceStep).round(),
          labels: RangeLabels(
            '${_minPrice.toInt()} XOF',
            '${_maxPrice.toInt()} XOF',
          ),
          onChanged: (values) {
            setState(() {
              _minPrice = values.start;
              _maxPrice = values.end;
            });
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dietary tags section
  // ---------------------------------------------------------------------------

  Widget _buildDietaryTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Régime alimentaire',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kDietaryTags.map((tag) {
              final isSelected = _dietaryTags.contains(tag);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_formatTag(tag)),
                  selected: isSelected,
                  onSelected: (_) => _toggleDietaryTag(tag),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Availability section
  // ---------------------------------------------------------------------------

  Widget _buildAvailabilitySection() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Disponibles uniquement'),
      subtitle: const Text('Afficher uniquement les plats en stock'),
      value: _availableOnly,
      onChanged: (value) {
        setState(() {
          _availableOnly = value;
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom buttons
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _clear,
                child: const Text('Effacer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _apply,
                child: const Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Capitalises the first letter of a dietary tag for display.
  String _formatTag(String tag) {
    if (tag.isEmpty) return tag;
    return tag[0].toUpperCase() + tag.substring(1);
  }
}
