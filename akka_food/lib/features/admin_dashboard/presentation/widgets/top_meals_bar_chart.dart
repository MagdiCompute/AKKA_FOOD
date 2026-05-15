import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/analytics_summary.dart';

/// Displays a horizontal bar chart of the top 5 best-selling meals.
///
/// Uses [fl_chart]'s [BarChart] widget.
/// Satisfies Requirement 5.2.
class TopMealsBarChart extends StatelessWidget {
  const TopMealsBarChart({
    super.key,
    required this.topMeals,
  });

  final List<MealStat> topMeals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (topMeals.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Aucune donnée disponible',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Take at most 5 meals, sorted descending by orderCount.
    final meals = [...topMeals]
      ..sort((a, b) => b.orderCount.compareTo(a.orderCount));
    final top = meals.take(5).toList();

    final maxCount =
        top.map((m) => m.orderCount).reduce((a, b) => a > b ? a : b).toDouble();

    // Build bar groups — one bar per meal, displayed top-to-bottom (index 0 = top).
    final barGroups = top.asMap().entries.map((entry) {
      final i = entry.key;
      final meal = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: meal.orderCount.toDouble(),
            color: _barColor(colorScheme, i),
            width: 18,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.25).ceilToDouble(),
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                maxCount > 0 ? (maxCount / 4).ceilToDouble() : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: maxCount > 0 ? (maxCount / 4).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= top.length) {
                    return const SizedBox.shrink();
                  }
                  final name = top[i].mealName;
                  // Truncate long names.
                  final label =
                      name.length > 10 ? '${name.substring(0, 9)}…' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final meal = top[group.x];
                return BarTooltipItem(
                  '${meal.mealName}\n${rod.toY.toInt()} commandes',
                  textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                      ) ??
                      const TextStyle(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Color _barColor(ColorScheme cs, int index) {
    const palette = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFFF44336),
    ];
    return palette[index % palette.length];
  }
}
