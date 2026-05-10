import '../../domain/repositories/i_admin_analytics_repository.dart';
import '../datasources/firestore_admin_analytics_data_source.dart';

/// Concrete implementation of [IAdminAnalyticsRepository].
///
/// Delegates all reads to [FirestoreAdminAnalyticsDataSource].
class AdminAnalyticsRepository implements IAdminAnalyticsRepository {
  AdminAnalyticsRepository(this._dataSource);

  final FirestoreAdminAnalyticsDataSource _dataSource;

  @override
  Stream<Map<String, dynamic>> watchSummary() => _dataSource.watchSummary();
}
