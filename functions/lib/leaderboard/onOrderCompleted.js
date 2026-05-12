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
exports.onOrderCompletedLeaderboard = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const firestore_1 = require("firebase-functions/v2/firestore");
const pubsub_1 = require("@google-cloud/pubsub");
/**
 * onOrderCompletedLeaderboard
 *
 * Firestore trigger on `/orders/{orderId}` document updates.
 * Fires when the `status` field changes TO `'delivered'` or `'completed'`
 * (and was NOT already that status) and performs:
 *
 * 1. Atomically increments `allTimeScore`, `monthlyScore`, `weeklyScore` by 1
 *    in `/userScores/{uid}` using a Firestore transaction
 * 2. Sets `leaderboardVisible` to `true` if the document doesn't exist yet (merge)
 * 3. Invalidates the user's recommendation cache
 * 4. Triggers leaderboard rebuild via Pub/Sub message to `rebuild-leaderboard` topic
 *
 * Idempotency: Does NOT increment if the previous status was already
 * 'delivered' or 'completed' (prevents double-counting on retries).
 *
 * Validates:
 * - Req 3 AC1: Count only orders with status `delivered` or `completed`
 * - Req 3 AC2: Do NOT count cancelled or refunded orders
 * - Req 3 AC3: Update User's Score within 60 seconds of status change
 * - Req 1 AC5: Rankings update within 60 seconds of a new completed order
 */
exports.onOrderCompletedLeaderboard = (0, firestore_1.onDocumentUpdated)("orders/{orderId}", async (event) => {
    var _a, _b;
    const beforeData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const afterData = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!beforeData || !afterData) {
        functions.logger.warn("onOrderCompletedLeaderboard: Missing before/after data");
        return;
    }
    const previousStatus = beforeData.status;
    const newStatus = afterData.status;
    // Only proceed if status changed to 'delivered' or 'completed'
    const completedStatuses = ["delivered", "completed"];
    if (!newStatus || !completedStatuses.includes(newStatus)) {
        return;
    }
    // Idempotency: don't increment if previous status was already delivered/completed
    if (previousStatus && completedStatuses.includes(previousStatus)) {
        return;
    }
    const orderId = event.params.orderId;
    const uid = afterData.uid;
    if (!uid) {
        functions.logger.error("onOrderCompletedLeaderboard: Missing uid on order", {
            orderId,
            timestamp: new Date().toISOString(),
        });
        return;
    }
    const db = admin.firestore();
    functions.logger.info("Order completed — updating leaderboard scores", {
        orderId,
        uid,
        newStatus,
        previousStatus,
    });
    // ── 1. Atomically increment userScores ────────────────────────────────
    try {
        await db.runTransaction(async (t) => {
            var _a;
            const scoreRef = db.doc(`userScores/${uid}`);
            const scoreSnap = await t.get(scoreRef);
            const scores = scoreSnap.data() || {};
            t.set(scoreRef, {
                allTimeScore: (scores.allTimeScore || 0) + 1,
                monthlyScore: (scores.monthlyScore || 0) + 1,
                weeklyScore: (scores.weeklyScore || 0) + 1,
                leaderboardVisible: (_a = scores.leaderboardVisible) !== null && _a !== void 0 ? _a : true,
            }, { merge: true });
        });
        functions.logger.info("Leaderboard scores incremented", {
            orderId,
            uid,
        });
    }
    catch (error) {
        functions.logger.error("Failed to increment leaderboard scores", {
            orderId,
            uid,
            error: error instanceof Error ? error.message : String(error),
            timestamp: new Date().toISOString(),
        });
        throw error; // Re-throw to trigger Cloud Functions retry
    }
    // ── 2. Invalidate recommendation cache ────────────────────────────────
    try {
        await db.doc(`recommendations/${uid}`).delete();
        functions.logger.info("Recommendation cache invalidated for leaderboard", {
            orderId,
            uid,
        });
    }
    catch (error) {
        // Non-critical: log but don't fail the function
        functions.logger.warn("Failed to invalidate recommendation cache", {
            orderId,
            uid,
            error: error instanceof Error ? error.message : String(error),
        });
    }
    // ── 3. Trigger leaderboard rebuild via Pub/Sub ──────────────────────────
    try {
        const pubsub = new pubsub_1.PubSub();
        const topic = pubsub.topic("rebuild-leaderboard");
        await topic.publishMessage({
            json: { uid, orderId, timestamp: new Date().toISOString() },
        });
        functions.logger.info("Published rebuild-leaderboard message", {
            orderId,
            uid,
        });
    }
    catch (error) {
        // Non-critical: log but don't fail the function
        functions.logger.warn("Failed to publish rebuild-leaderboard message", {
            orderId,
            uid,
            error: error instanceof Error ? error.message : String(error),
        });
    }
});
//# sourceMappingURL=onOrderCompleted.js.map