import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";

/**
 * aggregateAnalytics
 *
 * Scheduled Cloud Function (every 5 minutes).
 * Aggregates order/revenue/user metrics for today, week, and month periods,
 * then writes the result to /analytics/summary.
 *
 * NOTE: This is a scheduled function — there is no caller auth context,
 * so the admin role guard is intentionally NOT applied here.
 *
 * Firestore document structure written to /analytics/summary:
 * {
 *   today: { totalOrders, totalRevenue, activeUsers, topMeals, dailyOrders },
 *   week:  { totalOrders, totalRevenue, activeUsers, topMeals, dailyOrders },
 *   month: { totalOrders, totalRevenue, activeUsers, topMeals, dailyOrders },
 *   updatedAt: Timestamp
 * }
 */
export const aggregateAnalytics = onSchedule("every 5 minutes", async () => {
  const db = admin.firestore();
  const now = new Date();

  // --- Time boundaries ---
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);

  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  startOfWeek.setHours(0, 0, 0, 0);

  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const thirtyDaysAgo = new Date(now);
  thirtyDaysAgo.setDate(now.getDate() - 30);

  // --- Fetch all orders in the last 30 days (covers all periods) ---
  // Only count completed/delivered orders for revenue and totals
  const ordersSnap = await db
    .collection("orders")
    .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .get();

  const allOrders = ordersSnap.docs.map((d) => d.data());

  // Filter to only completed/delivered orders for metrics
  const completedStatuses = ["delivered", "completed"];
  const completedOrders = allOrders.filter((o) =>
    completedStatuses.includes(o["status"] ?? "")
  );

  // Helper: filter orders by start date
  const filterFrom = (
    subset: FirebaseFirestore.DocumentData[],
    startDate: Date
  ) =>
    subset.filter(
      (o) =>
        o["createdAt"] &&
        (o["createdAt"] as admin.firestore.Timestamp).toDate() >= startDate
    );

  const todayOrders = filterFrom(completedOrders, startOfToday);
  const weekOrders = filterFrom(completedOrders, startOfWeek);
  const monthOrders = filterFrom(completedOrders, startOfMonth);
  // All 30-day completed orders (used for dailyOrders chart)
  const thirtyDayOrders = completedOrders;

  // --- Compute per-period analytics ---
  const computePeriodData = (
    subset: FirebaseFirestore.DocumentData[],
    allThirtyDay: FirebaseFirestore.DocumentData[]
  ) => {
    // Total orders and revenue
    const totalOrders = subset.length;
    const totalRevenue = subset.reduce((sum, o) => sum + (o["total"] ?? 0), 0);

    // Active users: distinct UIDs with orders in this period
    const uids = new Set<string>(
      subset.map((o) => o["uid"] as string).filter(Boolean)
    );
    const activeUsers = uids.size;

    // Top 5 meals by order count within this period
    const mealCounts: Record<string, { mealName: string; orderCount: number }> =
      {};
    for (const order of subset) {
      const items: Array<{ mealId: string; mealName: string }> =
        order["items"] ?? [];
      for (const item of items) {
        if (!item.mealId) continue;
        if (!mealCounts[item.mealId]) {
          mealCounts[item.mealId] = {
            mealName: item.mealName ?? "",
            orderCount: 0,
          };
        }
        mealCounts[item.mealId].orderCount += 1;
      }
    }
    const topMeals = Object.entries(mealCounts)
      .map(([mealId, { mealName, orderCount }]) => ({
        mealId,
        mealName,
        orderCount,
      }))
      .sort((a, b) => b.orderCount - a.orderCount)
      .slice(0, 5);

    // Daily order counts for the last 30 days (same for all periods — shows trend)
    const dailyMap: Record<string, number> = {};
    for (const order of allThirtyDay) {
      if (!order["createdAt"]) continue;
      const date = (order["createdAt"] as admin.firestore.Timestamp)
        .toDate()
        .toISOString()
        .slice(0, 10); // YYYY-MM-DD
      dailyMap[date] = (dailyMap[date] ?? 0) + 1;
    }
    const dailyOrders = Object.entries(dailyMap)
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return { totalOrders, totalRevenue, activeUsers, topMeals, dailyOrders };
  };

  const todayData = computePeriodData(todayOrders, thirtyDayOrders);
  const weekData = computePeriodData(weekOrders, thirtyDayOrders);
  const monthData = computePeriodData(monthOrders, thirtyDayOrders);

  // --- Write summary to /analytics/summary ---
  await db.doc("analytics/summary").set({
    today: todayData,
    week: weekData,
    month: monthData,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
