"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.aggregateAnalytics = void 0;
const admin = __importStar(require("firebase-admin"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
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
exports.aggregateAnalytics = (0, scheduler_1.onSchedule)("every 5 minutes", async () => {
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
    const completedOrders = allOrders.filter((o) => { var _a; return completedStatuses.includes((_a = o["status"]) !== null && _a !== void 0 ? _a : ""); });
    // Helper: filter orders by start date
    const filterFrom = (subset, startDate) => subset.filter((o) => o["createdAt"] &&
        o["createdAt"].toDate() >= startDate);
    const todayOrders = filterFrom(completedOrders, startOfToday);
    const weekOrders = filterFrom(completedOrders, startOfWeek);
    const monthOrders = filterFrom(completedOrders, startOfMonth);
    // All 30-day completed orders (used for dailyOrders chart)
    const thirtyDayOrders = completedOrders;
    // --- Compute per-period analytics ---
    const computePeriodData = (subset, allThirtyDay) => {
        var _a, _b, _c;
        // Total orders and revenue
        const totalOrders = subset.length;
        const totalRevenue = subset.reduce((sum, o) => { var _a; return sum + ((_a = o["total"]) !== null && _a !== void 0 ? _a : 0); }, 0);
        // Active users: distinct UIDs with orders in this period
        const uids = new Set(subset.map((o) => o["uid"]).filter(Boolean));
        const activeUsers = uids.size;
        // Top 5 meals by order count within this period
        const mealCounts = {};
        for (const order of subset) {
            const items = (_a = order["items"]) !== null && _a !== void 0 ? _a : [];
            for (const item of items) {
                if (!item.mealId)
                    continue;
                if (!mealCounts[item.mealId]) {
                    mealCounts[item.mealId] = {
                        mealName: (_b = item.mealName) !== null && _b !== void 0 ? _b : "",
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
        const dailyMap = {};
        for (const order of allThirtyDay) {
            if (!order["createdAt"])
                continue;
            const date = order["createdAt"]
                .toDate()
                .toISOString()
                .slice(0, 10); // YYYY-MM-DD
            dailyMap[date] = ((_c = dailyMap[date]) !== null && _c !== void 0 ? _c : 0) + 1;
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
//# sourceMappingURL=aggregateAnalytics.js.map