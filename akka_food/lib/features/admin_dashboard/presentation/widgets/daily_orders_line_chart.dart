import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/analytics_summary.dart';

/// Displays a line chart of daily order counts for the past 30 days.
///
/// Uses [fl_chart]'s [LineChart] widget.
/// Satisfies Requirement 5.3.
class DailyOrdersLineChart extends StatelessWidget {
  const DailyOrdersLineChart({
    super.key,
    required this.dailyOrders,
  });

  final List<DailyOrderCount> dailyOrders;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (dailyOrders.isEmpty) {
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

    final spots = dailyOrders.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
    }).toList();

    final maxY = dailyOrders
        .map((d) => d.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (dailyOrders.length - 1).toDouble(),
          minY: 0,
          maxY: (maxY * 1.2).ceilToDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
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
                interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
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
                reservedSize: 24,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dailyOrders.length) {
                    return const SizedBox.shrink();
                  }
                  final date = dailyOrders[index].date;
                  // date is YYYY-MM-DD, show as DD/MM
                  final parts = date.split('-');
                  if (parts.length < 3) return const SizedBox.shrink();
                  final label = '${parts[2]}/${parts[1]}';
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
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
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = index < dailyOrders.length
                      ? dailyOrders[index].date
                      : '';
                  return LineTooltipItem(
                    '$date\n${spot.y.toInt()} commandes',
                    textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                        ) ??
                        const TextStyle(),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: colorScheme.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: dailyOrders.length <= 15,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: colorScheme.primary,
                  strokeWidth: 1.5,
                  strokeColor: colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withAlpha(30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
