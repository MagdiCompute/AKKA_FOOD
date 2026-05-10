import '../repositories/i_admin_analytics_repository.dart';

/// Returns a real-time stream of the raw analytics summary document.
///
/// Wraps [IAdminAnalyticsRepository.watchSummary] as a single-responsibility
/// use case following Clean Architecture conventions.
///
/// The caller (notifier) is responsible for extracting the desired period
/// sub-map and converting it to an [AnalyticsSummary] entity.
class GetAnalyticsSummaryUseCase {
  const GetAnalyticsSummaryUseCase(this._repository);

  final IAdminAnalyticsRepository _repository;

  /// Executes the use case.
  ///
  /// Returns a [Stream] that emits the raw summary [Map] whenever the
  /// `/analytics/summary` Firestore document changes.
  Stream<Map<String, dynamic>> call() => _repository.watchSummary();
}
