import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/analytics_summary.dart';
import '../notifiers/admin_analytics_notifier.dart';
import '../widgets/daily_orders_line_chart.dart';
import '../widgets/top_meals_bar_chart.dart';

// ---------------------------------------------------------------------------
// AdminAnalyticsScreen
// ---------------------------------------------------------------------------

/// Displays aggregated analytics for the admin dashboard.
///
/// Shows:
/// - A period selector (Today | Week | Month)
/// - Three summary cards: Total Orders, Revenue (XOF), Active Users
/// - Placeholder sections for charts (implemented in tasks 6.3 and 6.4)
///
/// Satisfies Requirements 5.1, 5.2, 5.3, and 5.4.
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(adminAnalyticsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: false,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(error: error),
        data: (analyticsState) => _AnalyticsBody(state: analyticsState),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnalyticsBody
// ---------------------------------------------------------------------------

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.state});

  final AdminAnalyticsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        _PeriodSelector(selectedPeriod: state.selectedPeriod),
        const SizedBox(height: 20),

        // Summary cards row
        _SummaryCardsRow(summary: state.summary),
        const SizedBox(height: 24),

        // Daily orders line chart (task 6.3)
        _ChartCard(
          title: 'Daily Orders (Last 30 Days)',
          child: DailyOrdersLineChart(dailyOrders: state.summary.dailyOrders),
        ),
        const SizedBox(height: 16),
        // Top 5 meals bar chart (task 6.4)
        _ChartCard(
          title: 'Top 5 Best-Selling Meals',
          child: TopMealsBarChart(topMeals: state.summary.topMeals),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _PeriodSelector
// ---------------------------------------------------------------------------

class _PeriodSelector extends ConsumerWidget {
  const _PeriodSelector({required this.selectedPeriod});

  final AnalyticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminAnalyticsNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<AnalyticsPeriod>(
      segments: const [
        ButtonSegment(
          value: AnalyticsPeriod.today,
          label: Text('Today'),
          icon: Icon(Icons.today),
        ),
        ButtonSegment(
          value: AnalyticsPeriod.week,
          label: Text('Week'),
          icon: Icon(Icons.date_range),
        ),
        ButtonSegment(
          value: AnalyticsPeriod.month,
          label: Text('Month'),
          icon: Icon(Icons.calendar_month),
        ),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (Set<AnalyticsPeriod> selection) {
        if (selection.isNotEmpty) {
          notifier.setPeriod(selection.first);
        }
      },
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onSecondaryContainer;
          }
          return colorScheme.onSurface;
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SummaryCardsRow
// ---------------------------------------------------------------------------

class _SummaryCardsRow extends StatelessWidget {
  const _SummaryCardsRow({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Orders',
            value: summary.totalOrders.toString(),
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Revenue (XOF)',
            value: _formatRevenue(summary.totalRevenue),
            icon: Icons.payments,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Active Users',
            value: summary.activeUsers.toString(),
            icon: Icons.people,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  /// Formats a revenue value as a compact string (e.g. 1 250 000 → "1.25M").
  /// For values under 1 000 000 shows the full integer with no decimals.
  String _formatRevenue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

// ---------------------------------------------------------------------------
// _SummaryCard
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ChartCard
// ---------------------------------------------------------------------------

/// A card wrapper for chart sections with a title.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
