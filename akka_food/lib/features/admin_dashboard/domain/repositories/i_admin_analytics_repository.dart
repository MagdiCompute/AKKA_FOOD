/// Abstract repository interface for admin analytics operations.
///
/// Implementations live in the data layer and depend on Firebase.
/// The domain layer only depends on this interface.
abstract interface class IAdminAnalyticsRepository {
  /// Returns a real-time stream of the raw `/analytics/summary` document.
  ///
  /// The map contains keys `today`, `week`, and `month`, each holding a
  /// sub-map with `totalOrders`, `totalRevenue`, `activeUsers`, `topMeals`,
  /// and `dailyOrders` fields as written by the `aggregateAnalytics`
  /// Cloud Function.
  ///
  /// Emits a new value whenever the document is updated (every ~5 minutes).
  Stream<Map<String, dynamic>> watchSummary();
}
