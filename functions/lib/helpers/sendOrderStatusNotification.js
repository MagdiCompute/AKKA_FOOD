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
exports.buildNotificationPayload = buildNotificationPayload;
exports.sendOrderStatusNotification = sendOrderStatusNotification;
const admin = __importStar(require("firebase-admin"));
/**
 * Builds the push notification payload for a given delivery status.
 * Payloads match the design doc specification exactly.
 *
 * @param status - The new delivery status string.
 * @param orderId - The Firestore order document ID.
 * @param etaMinutes - Optional ETA in minutes (used for out_for_delivery).
 * @returns Notification payload with title, body, and data, or null for unknown statuses.
 */
function buildNotificationPayload(status, orderId, etaMinutes) {
    switch (status) {
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
        default:
            return null;
    }
}
/**
 * Sends a push notification to the customer when their order status changes.
 *
 * Looks up the customer's FCM token from `/users/{uid}.fcmToken`.
 * Silently skips if the user has no FCM token (e.g. they haven't granted
 * notification permission or the token hasn't been stored yet).
 *
 * The notification includes:
 * - Per-status title and body matching the design doc
 * - Data payload with orderId, status, and type for deep linking
 * - Android notification channel ("order_updates") with high priority
 * - iOS default sound
 *
 * @param orderId  - The Firestore order document ID.
 * @param uid      - The customer's Firebase Auth UID.
 * @param newStatus - The new delivery status string.
 * @param etaMinutes - Optional ETA in minutes (only relevant for out_for_delivery).
 */
async function sendOrderStatusNotification(orderId, uid, newStatus, etaMinutes) {
    const db = admin.firestore();
    const userSnap = await db.doc(`users/${uid}`).get();
    if (!userSnap.exists)
        return;
    const userData = userSnap.data();
    const fcmToken = userData === null || userData === void 0 ? void 0 : userData["fcmToken"];
    if (!fcmToken)
        return;
    // Check user notification preferences — default to enabled if not explicitly set
    const preferences = userData === null || userData === void 0 ? void 0 : userData["preferences"];
    const notificationsEnabled = (preferences === null || preferences === void 0 ? void 0 : preferences.notificationsEnabled) !== false;
    if (!notificationsEnabled)
        return;
    const payload = buildNotificationPayload(newStatus, orderId, etaMinutes);
    if (!payload)
        return;
    const message = {
        token: fcmToken,
        notification: {
            title: payload.title,
            body: payload.body,
        },
        data: Object.assign(Object.assign({}, payload.data), { status: newStatus, type: "order_status_update" }),
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
    }
    catch (err) {
        // Log but don't fail the status update if notification delivery fails.
        console.error(`[sendOrderStatusNotification] Failed to send FCM message for order ${orderId}:`, err);
    }
}
//# sourceMappingURL=sendOrderStatusNotification.js.map