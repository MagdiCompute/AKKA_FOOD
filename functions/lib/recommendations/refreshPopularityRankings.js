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
exports.refreshPopularityRankings = void 0;
const admin = __importStar(require("firebase-admin"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const functions = __importStar(require("firebase-functions"));
/**
 * refreshPopularityRankings — Scheduled Cloud Function (every hour)
 *
 * Queries the top 50 meals by popularityScore and writes them to
 * `/analytics/popularMeals` for fast reads by the admin dashboard
 * and cold-start recommendation logic.
 *
 * Validates:
 * - Req 5 AC3: Recompute global popularity rankings at least once per hour
 */
exports.refreshPopularityRankings = (0, scheduler_1.onSchedule)("every 60 minutes", async () => {
    const db = admin.firestore();
    // Query top 50 meals ordered by popularityScore descending
    const topMealsSnap = await db
        .collection("meals")
        .orderBy("popularityScore", "desc")
        .limit(50)
        .get();
    if (topMealsSnap.empty) {
        functions.logger.info("No meals found for popularity rankings", {
            timestamp: new Date().toISOString(),
        });
        return;
    }
    // Build the ranked list with meal IDs, names, and scores
    const rankedMeals = topMealsSnap.docs.map((doc) => {
        const data = doc.data();
        return {
            mealId: doc.id,
            name: data.name || null,
            popularityScore: data.popularityScore || 0,
        };
    });
    const mealIds = rankedMeals.map((m) => m.mealId);
    // Write to /analytics/popularMeals for fast reads
    await db.doc("analytics/popularMeals").set({
        mealIds,
        rankedMeals,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Popularity rankings refreshed", {
        mealCount: mealIds.length,
        topMealId: mealIds[0] || null,
        timestamp: new Date().toISOString(),
    });
});
//# sourceMappingURL=refreshPopularityRankings.js.map