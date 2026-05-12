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
exports.onOrderCompletedRecommendations = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const firestore_1 = require("firebase-functions/v2/firestore");
/**
 * onOrderCompletedRecommendations
 *
 * Firestore trigger on `/orders/{orderId}` document updates.
 * Fires when the `status` field changes TO `'delivered'` and performs:
 * 1. Increments `popularityScore` by 1 for each meal in the order (atomic)
 * 2. Deletes `/recommendations/{uid}` to invalidate the user's recommendation cache
 *
 * This is separate from the delivery system's `onOrderStatusChanged` trigger.
 * It handles recommendation-specific concerns: popularity scoring and cache invalidation.
 *
 * Validates:
 * - Req 5 AC1: Increment Popularity_Score of each ordered meal by 1
 * - Req 5 AC2: Updated atomically using FieldValue.increment(1)
 * - Req 3 AC1: Recompute recommendations within 60 min of new order (cache invalidation)
 */
exports.onOrderCompletedRecommendations = (0, firestore_1.onDocumentUpdated)("orders/{orderId}", async (event) => {
    var _a, _b, _c;
    const beforeData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const afterData = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!beforeData || !afterData) {
        functions.logger.warn("onOrderCompletedRecommendations: Missing before/after data");
        return;
    }
    const previousStatus = beforeData.status;
    const newStatus = afterData.status;
    // Only act when status changes TO 'delivered'
    if (newStatus !== "delivered" || previousStatus === "delivered") {
        return;
    }
    const orderId = event.params.orderId;
    const uid = afterData.uid;
    const items = afterData.items;
    const db = admin.firestore();
    functions.logger.info("Order completed — updating popularity scores", {
        orderId,
        uid,
        itemCount: (_c = items === null || items === void 0 ? void 0 : items.length) !== null && _c !== void 0 ? _c : 0,
    });
    // ── 1. Increment popularityScore for each ordered meal ────────────────
    if (items && Array.isArray(items)) {
        const updatePromises = items
            .filter((item) => item.mealId)
            .map((item) => db.doc(`meals/${item.mealId}`).update({
            popularityScore: admin.firestore.FieldValue.increment(1),
        }));
        await Promise.all(updatePromises);
        functions.logger.info("Popularity scores incremented", {
            orderId,
            mealIds: items.filter((item) => item.mealId).map((item) => item.mealId),
        });
    }
    // ── 2. Invalidate user's recommendation cache ─────────────────────────
    if (uid) {
        await db.doc(`recommendations/${uid}`).delete();
        functions.logger.info("Recommendation cache invalidated", {
            orderId,
            uid,
        });
    }
});
//# sourceMappingURL=onOrderCompleted.js.map