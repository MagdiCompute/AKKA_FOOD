import 'package:flutter/material.dart';

import 'package:akka_food/features/meal_catalog/domain/entities/category.dart';

/// Stub widget for [CategoryChip].
///
/// Displays a category name as a selectable chip.
/// Full implementation (with icon and selected state) is in task 6.3.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    this.onTap,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(category.name),
        selected: isSelected,
        onSelected: (_) => onTap?.call(),
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        labelStyle: TextStyle(
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface,
        ),
      ),
    );
  }
}
