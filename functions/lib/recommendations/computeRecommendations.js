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
exports.computeRecommendations = void 0;
exports.getCompletedOrders = getCompletedOrders;
exports.computePersonalized = computePersonalized;
exports.getPopularMeals = getPopularMeals;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const functions = __importStar(require("firebase-functions"));
const CACHE_TTL_MS = 60 * 60 * 1000; // 60 minutes
/**
 * Fetches completed (delivered) orders for a given user.
 * Returns an array of order documents with their data.
 */
async function getCompletedOrders(uid) {
    const db = admin.firestore();
    const ordersSnap = await db
        .collection("orders")
        .where("uid", "==", uid)
        .where("status", "==", "delivered")
        .get();
    return ordersSnap.docs.map((doc) => (Object.assign({ id: doc.id }, doc.data())));
}
/**
 * Computes personalized meal recommendations based on order history.
 * Stub — full implementation in task 3.2.
 *
 * @param orders - Array of completed order documents
 * @returns Array of up to 10 meal IDs sorted by weighted score
 */
async function computePersonalized(orders) {
    // Stub: extract unique mealIds from orders, return up to 10
    // Full algorithm (frequency map, recency boost, exclusions) implemented in task 3.2
    const mealIdSet = new Set();
    for (const order of orders) {
        const items = order.items;
        if (items && Array.isArray(items)) {
            for (const item of items) {
                if (item.mealId) {
                    mealIdSet.add(item.mealId);
                }
            }
        }
    }
    return Array.from(mealIdSet).slice(0, 10);
}
/**
 * Returns popular meals for cold-start users (< 3 orders).
 * Stub — full implementation in task 3.3.
 *
 * @returns Array of up to 10 meal IDs sorted by popularity score
 */
async function getPopularMeals() {
    // Stub: query top 10 meals by popularityScore where isAvailable == true
    // Full implementation in task 3.3
    const db = admin.firestore();
    const mealsSnap = await db
        .collection("meals")
        .where("isAvailable", "==", true)
        .orderBy("popularityScore", "desc")
        .limit(10)
        .get();
    return mealsSnap.docs.map((doc) => doc.id);
}
/**
 * computeRecommendations — HTTPS Callable Cloud Function
 *
 * Computes personalized or cold-start meal recommendations for the authenticated user.
 *
 * Steps:
 * 1. Validate caller's auth token
 * 2. Check cache at /recommendations/{uid} — if fresh (< 60 min), return cached data
 * 3. Fetch completed orders for the user
 * 4. If >= 3 orders: compute personalized recommendations
 * 5. If < 3 orders: return popularity-based recommendations (cold start)
 * 6. Write result to /recommendations/{uid} with serverTimestamp
 * 7. Return { mealIds, isPersonalized }
 *
 * Validates:
 * - Req 1 AC1: Return up to 10 personalized meals for users with >= 3 orders
 * - Req 2 AC1: Return top 10 by popularity for users with < 3 orders
 * - Req 3 AC2: Cache with 60-minute TTL
 */
exports.computeRecommendations = (0, https_1.onCall)(async (request) => {
    // ── Step 1: Validate authentication ─────────────────────────────────────
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated to get recommendations.");
    }
    const uid = request.auth.uid;
    const db = admin.firestore();
    // ── Step 2: Check cache ─────────────────────────────────────────────────
    const cacheRef = db.doc(`recommendations/${uid}`);
    const cacheDoc = await cacheRef.get();
    if (cacheDoc.exists) {
        const cacheData = cacheDoc.data();
        if (cacheData === null || cacheData === void 0 ? void 0 : cacheData.computedAt) {
            const computedAtMillis = cacheData.computedAt.toMillis();
            const age = Date.now() - computedAtMillis;
            if (age < CACHE_TTL_MS) {
                functions.logger.info("Serving cached recommendations", {
                    uid,
                    ageMinutes: Math.round(age / 60000),
                });
                return {
                    mealIds: cacheData.mealIds,
                    isPersonalized: cacheData.isPersonalized,
                };
            }
        }
    }
    // ── Step 3: Fetch completed orders ──────────────────────────────────────
    const orders = await getCompletedOrders(uid);
    functions.logger.info("Computing recommendations", {
        uid,
        completedOrders: orders.length,
        isPersonalized: orders.length >= 3,
    });
    // ── Step 4/5: Compute recommendations ───────────────────────────────────
    let mealIds;
    if (orders.length >= 3) {
        mealIds = await computePersonalized(orders);
    }
    else {
        mealIds = await getPopularMeals();
    }
    const isPersonalized = orders.length >= 3;
    // ── Step 6: Cache result ────────────────────────────────────────────────
    await cacheRef.set({
        mealIds,
        isPersonalized,
        computedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Recommendations computed and cached", {
        uid,
        mealCount: mealIds.length,
        isPersonalized,
    });
    // ── Step 7: Return result ───────────────────────────────────────────────
    return { mealIds, isPersonalized };
});
//# sourceMappingURL=computeRecommendations.js.map