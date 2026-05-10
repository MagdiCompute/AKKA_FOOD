/// Analytics period selector.
enum AnalyticsPeriod { today, week, month }

// ---------------------------------------------------------------------------
// MealStat
// ---------------------------------------------------------------------------

/// Represents a single meal's order count for the analytics top-meals list.
class MealStat {
  const MealStat({
    required this.mealId,
    required this.mealName,
    required this.orderCount,
  });

  final String mealId;
  final String mealName;
  final int orderCount;

  factory MealStat.fromMap(Map<String, dynamic> map) {
    return MealStat(
      mealId: (map['mealId'] as String?) ?? '',
      mealName: (map['mealName'] as String?) ?? '',
      orderCount: (map['orderCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'mealId': mealId,
        'mealName': mealName,
        'orderCount': orderCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealStat &&
          runtimeType == other.runtimeType &&
          mealId == other.mealId &&
          mealName == other.mealName &&
          orderCount == other.orderCount;

  @override
  int get hashCode => Object.hash(mealId, mealName, orderCount);

  @override
  String toString() =>
      'MealStat(mealId: $mealId, mealName: $mealName, orderCount: $orderCount)';

  MealStat copyWith({
    String? mealId,
    String? mealName,
    int? orderCount,
  }) {
    return MealStat(
      mealId: mealId ?? this.mealId,
      mealName: mealName ?? this.mealName,
      orderCount: orderCount ?? this.orderCount,
    );
  }
}

// ---------------------------------------------------------------------------
// DailyOrderCount
// ---------------------------------------------------------------------------

/// Represents the number of orders on a specific date (YYYY-MM-DD).
class DailyOrderCount {
  const DailyOrderCount({
    required this.date,
    required this.count,
  });

  /// Date string in `YYYY-MM-DD` format.
  final String date;
  final int count;

  factory DailyOrderCount.fromMap(Map<String, dynamic> map) {
    return DailyOrderCount(
      date: (map['date'] as String?) ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'count': count,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyOrderCount &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          count == other.count;

  @override
  int get hashCode => Object.hash(date, count);

  @override
  String toString() => 'DailyOrderCount(date: $date, count: $count)';

  DailyOrderCount copyWith({String? date, int? count}) {
    return DailyOrderCount(
      date: date ?? this.date,
      count: count ?? this.count,
    );
  }
}

// ---------------------------------------------------------------------------
// AnalyticsSummary
// ---------------------------------------------------------------------------

/// Aggregated analytics data for a specific [AnalyticsPeriod].
///
/// Populated from the `/analytics/summary` Firestore document which is
/// updated every 5 minutes by the `aggregateAnalytics` Cloud Function.
class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalOrders,
    required this.totalRevenue,
    required this.activeUsers,
    required this.topMeals,
    required this.dailyOrders,
    required this.period,
  });

  final int totalOrders;
  final double totalRevenue;
  final int activeUsers;

  /// Top 5 best-selling meals by order count for the selected period.
  final List<MealStat> topMeals;

  /// Daily order counts for the past 30 days (shared across all periods).
  final List<DailyOrderCount> dailyOrders;

  /// The period this summary represents.
  final AnalyticsPeriod period;

  /// Creates an [AnalyticsSummary] from a period sub-map (e.g. `doc['today']`)
  /// and the [period] enum value.
  factory AnalyticsSummary.fromMap(
    Map<String, dynamic> map,
    AnalyticsPeriod period,
  ) {
    final rawTopMeals = map['topMeals'] as List<dynamic>? ?? [];
    final rawDailyOrders = map['dailyOrders'] as List<dynamic>? ?? [];

    return AnalyticsSummary(
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      activeUsers: (map['activeUsers'] as num?)?.toInt() ?? 0,
      topMeals: rawTopMeals
          .map((e) => MealStat.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      dailyOrders: rawDailyOrders
          .map((e) =>
              DailyOrderCount.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      period: period,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsSummary &&
          runtimeType == other.runtimeType &&
          totalOrders == other.totalOrders &&
          totalRevenue == other.totalRevenue &&
          activeUsers == other.activeUsers &&
          period == other.period;

  @override
  int get hashCode =>
      Object.hash(totalOrders, totalRevenue, activeUsers, period);

  @override
  String toString() => 'AnalyticsSummary('
      'totalOrders: $totalOrders, '
      'totalRevenue: $totalRevenue, '
      'activeUsers: $activeUsers, '
      'period: $period)';

  AnalyticsSummary copyWith({
    int? totalOrders,
    double? totalRevenue,
    int? activeUsers,
    List<MealStat>? topMeals,
    List<DailyOrderCount>? dailyOrders,
    AnalyticsPeriod? period,
  }) {
    return AnalyticsSummary(
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      activeUsers: activeUsers ?? this.activeUsers,
      topMeals: topMeals ?? this.topMeals,
      dailyOrders: dailyOrders ?? this.dailyOrders,
      period: period ?? this.period,
    );
  }
}
