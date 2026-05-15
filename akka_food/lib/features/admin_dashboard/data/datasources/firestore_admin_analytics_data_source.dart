import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles Firestore reads for admin analytics by computing data directly
/// from the `/orders` and `/users` collections.
///
/// Previously relied on a `/analytics/summary` document written by a Cloud
/// Function. Now computes analytics on-the-fly from actual collection data.
class FirestoreAdminAnalyticsDataSource {
  FirestoreAdminAnalyticsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns a real-time stream of computed analytics data.
  ///
  /// Listens to the `/orders` collection and recomputes analytics whenever
  /// orders change. Emits a [Map] with keys `today`, `week`, and `month`,
  /// each containing `totalOrders`, `totalRevenue`, `activeUsers`,
  /// `topMeals`, and `dailyOrders`.
  Stream<Map<String, dynamic>> watchSummary() {
    return _firestore
        .collection('orders')
        .snapshots()
        .asyncMap((ordersSnapshot) async {
      // Fetch user count
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Parse all orders
      final allOrders = ordersSnapshot.docs.map((doc) {
        final data = doc.data();
        DateTime? createdAt;
        final rawCreatedAt = data['createdAt'];
        if (rawCreatedAt is Timestamp) {
          createdAt = rawCreatedAt.toDate();
        }
        final total = (data['total'] as num?)?.toDouble() ??
            (data['totalAmount'] as num?)?.toDouble() ??
            0.0;
        final items = data['items'] as List<dynamic>? ?? [];
        return _OrderData(
          createdAt: createdAt,
          total: total,
          items: items,
        );
      }).toList();

      // Compute period data
      final todayData = _computePeriod(
        allOrders.where((o) =>
            o.createdAt != null && o.createdAt!.isAfter(todayStart)).toList(),
        totalUsers,
        allOrders,
      );
      final weekData = _computePeriod(
        allOrders.where((o) =>
            o.createdAt != null && o.createdAt!.isAfter(weekStart)).toList(),
        totalUsers,
        allOrders,
      );
      final monthData = _computePeriod(
        allOrders.where((o) =>
            o.createdAt != null && o.createdAt!.isAfter(monthStart)).toList(),
        totalUsers,
        allOrders,
      );

      return <String, dynamic>{
        'today': todayData,
        'week': weekData,
        'month': monthData,
      };
    });
  }

  /// Computes analytics for a filtered list of orders.
  Map<String, dynamic> _computePeriod(
    List<_OrderData> periodOrders,
    int totalUsers,
    List<_OrderData> allOrders,
  ) {
    final totalOrders = periodOrders.length;
    final totalRevenue =
        periodOrders.fold<double>(0.0, (acc, o) => acc + o.total);

    // Top 5 meals by order count
    final mealCounts = <String, _MealCount>{};
    for (final order in periodOrders) {
      for (final item in order.items) {
        if (item is Map) {
          final name = (item['name'] as String?) ??
              (item['mealName'] as String?) ??
              'Inconnu';
          final mealId = (item['mealId'] as String?) ?? name;
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          mealCounts.putIfAbsent(mealId, () => _MealCount(mealId, name));
          mealCounts[mealId]!.count += qty;
        }
      }
    }
    final topMeals = mealCounts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final top5 = topMeals.take(5).map((m) => {
          'mealId': m.mealId,
          'mealName': m.mealName,
          'orderCount': m.count,
        }).toList();

    // Daily orders for the past 30 days
    final dailyOrders = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      final count = allOrders.where((o) =>
          o.createdAt != null &&
          o.createdAt!.isAfter(day) &&
          o.createdAt!.isBefore(dayEnd)).length;
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      dailyOrders.add({'date': dateStr, 'count': count});
    }

    return <String, dynamic>{
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'activeUsers': totalUsers,
      'topMeals': top5,
      'dailyOrders': dailyOrders,
    };
  }
}

/// Internal helper to hold parsed order data.
class _OrderData {
  _OrderData({
    required this.createdAt,
    required this.total,
    required this.items,
  });

  final DateTime? createdAt;
  final double total;
  final List<dynamic> items;
}

/// Internal helper to count meal occurrences.
class _MealCount {
  _MealCount(this.mealId, this.mealName);

  final String mealId;
  final String mealName;
  int count = 0;
}
