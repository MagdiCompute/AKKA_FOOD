import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/firestore_admin_analytics_data_source.dart';
import '../../data/repositories/admin_analytics_repository.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/repositories/i_admin_analytics_repository.dart';
import '../../domain/usecases/get_analytics_summary_use_case.dart';

part 'admin_analytics_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the [IAdminAnalyticsRepository] instance.
///
/// Exposed as a provider so it can be overridden in tests.
@riverpod
IAdminAnalyticsRepository adminAnalyticsRepository(Ref ref) {
  return AdminAnalyticsRepository(FirestoreAdminAnalyticsDataSource());
}

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

/// Holds the UI state for [AdminAnalyticsScreen].
class AdminAnalyticsState {
  const AdminAnalyticsState({
    required this.summary,
    this.selectedPeriod = AnalyticsPeriod.today,
  });

  /// The analytics summary for the currently selected period.
  final AnalyticsSummary summary;

  /// The currently selected period (default: today).
  final AnalyticsPeriod selectedPeriod;

  AdminAnalyticsState copyWith({
    AnalyticsSummary? summary,
    AnalyticsPeriod? selectedPeriod,
  }) {
    return AdminAnalyticsState(
      summary: summary ?? this.summary,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the state for [AdminAnalyticsScreen].
///
/// Listens to the real-time Firestore stream of `/analytics/summary` and
/// exposes period switching (today | week | month).
///
/// Satisfies Requirements 5.1, 5.2, 5.3, and 5.4.
@riverpod
class AdminAnalyticsNotifier extends _$AdminAnalyticsNotifier {
  StreamSubscription<Map<String, dynamic>>? _subscription;

  /// The raw summary document cached so period switches don't require a
  /// new network request.
  Map<String, dynamic> _rawDoc = {};

  /// The currently selected period (default: today).
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.today;

  @override
  AsyncValue<AdminAnalyticsState> build() {
    final repository = ref.watch(adminAnalyticsRepositoryProvider);
    final useCase = GetAnalyticsSummaryUseCase(repository);

    // Cancel any previous subscription when the notifier is rebuilt.
    ref.onDispose(() => _subscription?.cancel());

    // Start listening to the Firestore stream.
    _subscription = useCase().listen(
      (rawDoc) {
        _rawDoc = rawDoc;
        _emitState();
      },
      onError: (Object error, StackTrace stack) {
        state = AsyncError(error, stack);
      },
    );

    return const AsyncLoading();
  }

  // ---------------------------------------------------------------------------
  // Period switching
  // ---------------------------------------------------------------------------

  /// Switches the analytics view to the given [period].
  ///
  /// If the raw document has already been received, the state is updated
  /// immediately without waiting for a new Firestore event.
  void setPeriod(AnalyticsPeriod period) {
    _selectedPeriod = period;
    if (_rawDoc.isNotEmpty) {
      _emitState();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Extracts the sub-map for [_selectedPeriod] from [_rawDoc] and emits
  /// a new [AsyncData] state.
  void _emitState() {
    final periodKey = _periodKey(_selectedPeriod);
    final periodMap = _rawDoc[periodKey];

    if (periodMap == null) {
      // Document exists but the period key is missing — treat as empty data.
      state = AsyncData(
        AdminAnalyticsState(
          summary: AnalyticsSummary(
            totalOrders: 0,
            totalRevenue: 0,
            activeUsers: 0,
            topMeals: const [],
            dailyOrders: const [],
            period: _selectedPeriod,
          ),
          selectedPeriod: _selectedPeriod,
        ),
      );
      return;
    }

    final summary = AnalyticsSummary.fromMap(
      Map<String, dynamic>.from(periodMap as Map),
      _selectedPeriod,
    );

    state = AsyncData(
      AdminAnalyticsState(
        summary: summary,
        selectedPeriod: _selectedPeriod,
      ),
    );
  }

  /// Maps an [AnalyticsPeriod] to its Firestore document key.
  static String _periodKey(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.today:
        return 'today';
      case AnalyticsPeriod.week:
        return 'week';
      case AnalyticsPeriod.month:
        return 'month';
    }
  }
}
