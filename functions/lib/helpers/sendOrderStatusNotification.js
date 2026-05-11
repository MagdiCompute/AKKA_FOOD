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
exports.sendOrderStatusNotification = sendOrderStatusNotification;
const admin = __importStar(require("firebase-admin"));
/**
 * Human-readable labels for each delivery status, used in push notification bodies.
 */
const STATUS_LABELS = {
    confirmed: "Your order has been confirmed!",
    preparing: "Your order is being prepared.",
    ready_for_pickup: "Your order is ready for pickup.",
    out_for_delivery: "Your order is on its way!",
    delivered: "Your order has been delivered. Enjoy!",
    cancelled: "Your order has been cancelled.",
};
/**
 * Sends a push notification to the customer when their order status changes.
 *
 * Looks up the customer's FCM token from `/users/{uid}.fcmToken`.
 * Silently skips if the user has no FCM token (e.g. they haven't granted
 * notification permission or the token hasn't been stored yet).
 *
 * @param orderId  - The Firestore order document ID.
 * @param uid      - The customer's Firebase Auth UID.
 * @param newStatus - The new delivery status string.
 * @param etaMinutes - Optional ETA in minutes (only relevant for out_for_delivery).
 */
async function sendOrderStatusNotification(orderId, uid, newStatus, etaMinutes) {
    var _a;
    const db = admin.firestore();
    const userSnap = await db.doc(`users/${uid}`).get();
    if (!userSnap.exists)
        return;
    const fcmToken = (_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a["fcmToken"];
    if (!fcmToken)
        return;
    const body = buildNotificationBody(newStatus, etaMinutes);
    const message = {
        token: fcmToken,
        notification: {
            title: "Order Update",
            body,
        },
        data: {
            orderId,
            status: newStatus,
        },
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
function buildNotificationBody(status, etaMinutes) {
    var _a;
    if (status === "out_for_delivery" && typeof etaMinutes === "number") {
        return `Your order is on its way! Estimated arrival: ${etaMinutes} minute${etaMinutes === 1 ? "" : "s"}.`;
    }
    return (_a = STATUS_LABELS[status]) !== null && _a !== void 0 ? _a : `Your order status has been updated to: ${status}.`;
}
//# sourceMappingURL=sendOrderStatusNotification.js.map