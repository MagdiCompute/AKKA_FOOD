import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";

/**
 * aggregateAnalytics
 *
 * Scheduled Cloud Function (every 5 minutes).
 * Aggregates order/revenue/user metrics and writes to /analytics/summary.
 *
 * NOTE: This is a scheduled function — there is no caller auth context,
 * so the admin role guard is intentionally NOT applied here.
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

  // --- Fetch all orders in the last 30 days ---
  const ordersSnap = await db
    .collection("orders")
    .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .get();

  const orders = ordersSnap.docs.map((d) => d.data());

  // Helper: filter orders by start date
  const filterFrom = (startDate: Date) =>
    orders.filter(
      (o) =>
        o["createdAt"] &&
        (o["createdAt"] as admin.firestore.Timestamp).toDate() >= startDate
    );

  const computeTotals = (subset: FirebaseFirestore.DocumentData[]) => ({
    totalOrders: subset.length,
    totalRevenue: subset.reduce((sum, o) => sum + (o["total"] ?? 0), 0),
  });

  const todayOrders = filterFrom(startOfToday);
  const weekOrders = filterFrom(startOfWeek);
  const monthOrders = filterFrom(startOfMonth);

  // --- Active users (signed in within last 30 days) ---
  const usersSnap = await db
    .collection("users")
    .where(
      "lastSignInAt",
      ">=",
      admin.firestore.Timestamp.fromDate(thirtyDaysAgo)
    )
    .get();
  const activeUsers = usersSnap.size;

  // --- Top 5 meals by order count (last 30 days) ---
  const mealCounts: Record<string, { name: string; count: number }> = {};
  for (const order of orders) {
    const items: Array<{ mealId: string; mealName: string }> =
      order["items"] ?? [];
    for (const item of items) {
      if (!mealCounts[item.mealId]) {
        mealCounts[item.mealId] = { name: item.mealName, count: 0 };
      }
      mealCounts[item.mealId].count += 1;
    }
  }
  const topMeals = Object.entries(mealCounts)
    .map(([mealId, { name, count }]) => ({ mealId, name, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);

  // --- Daily order counts for the last 30 days ---
  const dailyMap: Record<string, number> = {};
  for (const order of orders) {
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

  // --- Write summary ---
  await db.doc("analytics/summary").set({
    today: computeTotals(todayOrders),
    week: computeTotals(weekOrders),
    month: computeTotals(monthOrders),
    activeUsers,
    topMeals,
    dailyOrders,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
