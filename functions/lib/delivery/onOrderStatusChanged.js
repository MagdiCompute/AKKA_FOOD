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
exports.onOrderStatusChanged = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
const firestore_1 = require("firebase-functions/v2/firestore");
/**
 * Push notification payloads per status (from design.md).
 */
function buildNotificationPayload(status, orderId, etaMinutes) {
    switch (status) {
        case "out_for_delivery":
            return {
                title: "Your order is on the way!",
                body: `ETA: ${etaMinutes !== null && etaMinutes !== void 0 ? etaMinutes : "?"} minutes`,
                data: { orderId },
            };
        case "delivered":
            return {
                title: "Order delivered!",
                body: "Tap to rate your experience",
                data: { orderId },
            };
        case "failed":
            return {
                title: "Delivery issue",
                body: "We couldn't deliver your order. We'll contact you shortly.",
                data: { orderId },
            };
        case "confirmed":
            return {
                title: "Order confirmed",
                body: "Your order has been confirmed!",
                data: { orderId },
            };
        case "preparing":
            return {
                title: "Order update",
                body: "Your order is being prepared.",
                data: { orderId },
            };
        default:
            return null;
    }
}
/**
 * onOrderStatusChanged
 *
 * Firestore trigger on `/orders/{orderId}` document updates.
 * Fires when the `status` field changes and performs:
 * 1. Creates a TrackingUpdate record in `/orders/{orderId}/trackingUpdates/{updateId}`
 * 2. Sends FCM push notification to the user (if notifications enabled in preferences)
 * 3. If status == 'delivered': updates leaderboard score and triggers coin credit
 * 4. If status == 'failed': flags for admin follow-up
 */
exports.onOrderStatusChanged = (0, firestore_1.onDocumentUpdated)("orders/{orderId}", async (event) => {
    var _a, _b;
    const beforeData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const afterData = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!beforeData || !afterData) {
        functions.logger.warn("onOrderStatusChanged: Missing before/after data");
        return;
    }
    const previousStatus = beforeData.status;
    const newStatus = afterData.status;
    // Only proceed if the status field actually changed
    if (!newStatus || previousStatus === newStatus) {
        return;
    }
    const orderId = event.params.orderId;
    const uid = afterData.uid;
    const etaMinutes = afterData.etaMinutes;
    const failureReason = afterData.failureReason;
    const db = admin.firestore();
    functions.logger.info("Order status changed", {
        orderId,
        previousStatus,
        newStatus,
        uid,
        timestamp: new Date().toISOString(),
    });
    // ── 1. Create TrackingUpdate record ───────────────────────────────────────
    await createTrackingUpdate(db, orderId, newStatus, failureReason);
    // ── 2. Send FCM push notification (if user preferences allow) ─────────────
    if (uid) {
        await sendPushNotification(db, uid, orderId, newStatus, etaMinutes);
    }
    // ── 3. If delivered: update leaderboard + credit coins ────────────────────
    if (newStatus === "delivered" && uid) {
        await handleDelivered(db, orderId, uid, afterData);
    }
    // ── 4. If failed: flag for admin follow-up ────────────────────────────────
    if (newStatus === "failed") {
        await handleFailed(db, orderId, uid, failureReason);
    }
});
/**
 * Creates a TrackingUpdate record in the order's subcollection.
 */
async function createTrackingUpdate(db, orderId, status, note) {
    const trackingData = {
        status,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (note) {
        trackingData.note = note;
    }
    await db
        .collection("orders")
        .doc(orderId)
        .collection("trackingUpdates")
        .add(trackingData);
    functions.logger.info("TrackingUpdate created", {
        orderId,
        status,
        timestamp: new Date().toISOString(),
    });
}
/**
 * Sends an FCM push notification to the user if their notification preferences allow it.
 * Checks `users/{uid}.preferences.notificationsEnabled` (defaults to true if not set).
 */
async function sendPushNotification(db, uid, orderId, status, etaMinutes) {
    const userSnap = await db.doc(`users/${uid}`).get();
    if (!userSnap.exists) {
        functions.logger.warn("User not found for notification", { uid, orderId });
        return;
    }
    const userData = userSnap.data();
    // Check user notification preferences — default to enabled if not explicitly set
    const preferences = userData === null || userData === void 0 ? void 0 : userData.preferences;
    const notificationsEnabled = (preferences === null || preferences === void 0 ? void 0 : preferences.notificationsEnabled) !== false;
    if (!notificationsEnabled) {
        functions.logger.info("Notifications disabled for user, skipping", { uid, orderId });
        return;
    }
    const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
    if (!fcmToken) {
        functions.logger.warn("No FCM token for user, skipping notification", { uid, orderId });
        return;
    }
    const payload = buildNotificationPayload(status, orderId, etaMinutes);
    if (!payload) {
        functions.logger.info("No notification payload for status", { status, orderId });
        return;
    }
    const message = {
        token: fcmToken,
        notification: {
            title: payload.title,
            body: payload.body,
        },
        data: Object.assign(Object.assign({}, payload.data), { status, type: "order_status_update" }),
        android: {
            notification: {
                channelId: "order_updates",
                priority: "high",
            },
        },
        apns: {
            payload: {
                aps: {
                    sound: "default",
                },
            },
        },
    };
    try {
        await admin.messaging().send(message);
        functions.logger.info("Push notification sent", { uid, orderId, status });
    }
    catch (err) {
        // Log but don't fail — notification delivery is best-effort
        functions.logger.error("Failed to send push notification", {
            uid,
            orderId,
            status,
            error: err instanceof Error ? err.message : String(err),
        });
    }
}
/**
 * Handles the 'delivered' status:
 * - Records delivery timestamp on the order
 * - Updates leaderboard score (increment deliveries count)
 * - Credits bonus coins (5% of order total)
 */
async function handleDelivered(db, orderId, uid, orderData) {
    var _a, _b;
    const total = ((_b = (_a = orderData.total) !== null && _a !== void 0 ? _a : orderData.totalAmount) !== null && _b !== void 0 ? _b : 0);
    // Record delivery timestamp on the order
    await db.doc(`orders/${orderId}`).update({
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Update leaderboard: increment user's completed deliveries count
    const leaderboardRef = db.doc(`leaderboard/${uid}`);
    await leaderboardRef.set({
        uid,
        deliveries: admin.firestore.FieldValue.increment(1),
        totalSpent: admin.firestore.FieldValue.increment(total),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    // Credit coins: 5% of order total, rounded down
    const coins = Math.floor(total * 0.05);
    if (coins > 0) {
        await db.doc(`users/${uid}`).update({
            coins: admin.firestore.FieldValue.increment(coins),
        });
        // Record coin transaction for audit trail
        await db.collection("users").doc(uid).collection("coinHistory").add({
            amount: coins,
            type: "delivery_reward",
            orderId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.info("Delivery coins credited", { uid, orderId, coins });
    }
    functions.logger.info("Delivery completed — leaderboard updated", { uid, orderId, total });
}
/**
 * Handles the 'failed' status:
 * - Creates an admin follow-up flag document
 */
async function handleFailed(db, orderId, uid, failureReason) {
    await db.collection("adminFollowUps").add({
        orderId,
        uid: uid !== null && uid !== void 0 ? uid : null,
        reason: failureReason !== null && failureReason !== void 0 ? failureReason : "Delivery failed — no reason provided",
        status: "pending",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Admin follow-up flagged for failed delivery", {
        orderId,
        uid,
        failureReason,
    });
}
//# sourceMappingURL=onOrderStatusChanged.js.map