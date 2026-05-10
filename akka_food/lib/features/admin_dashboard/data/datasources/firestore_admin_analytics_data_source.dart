import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles real-time Firestore reads for the `/analytics/summary` document.
///
/// The document is written every 5 minutes by the `aggregateAnalytics`
/// Cloud Function and has the shape:
/// ```json
/// {
///   "today": { "totalOrders": ..., "totalRevenue": ..., "activeUsers": ...,
///              "topMeals": [...], "dailyOrders": [...] },
///   "week":  { ... },
///   "month": { ... },
///   "updatedAt": Timestamp
/// }
/// ```
class FirestoreAdminAnalyticsDataSource {
  FirestoreAdminAnalyticsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _summaryDoc =>
      _firestore.doc('analytics/summary');

  /// Returns a real-time stream of the raw `/analytics/summary` document.
  ///
  /// Emits a new [Map] whenever the document is updated.
  /// Emits an empty map if the document does not exist yet.
  Stream<Map<String, dynamic>> watchSummary() {
    return _summaryDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return <String, dynamic>{};
      return snapshot.data() ?? <String, dynamic>{};
    });
  }
}
