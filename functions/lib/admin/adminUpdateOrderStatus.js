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
exports.adminUpdateOrderStatus = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const verifyAdmin_1 = require("../helpers/verifyAdmin");
const sendOrderStatusNotification_1 = require("../helpers/sendOrderStatusNotification");
/**
 * Valid delivery status values.
 */
const VALID_STATUSES = new Set([
    "pending",
    "confirmed",
    "preparing",
    "ready_for_pickup",
    "out_for_delivery",
    "delivered",
    "cancelled",
]);
/**
 * Allowed status transitions.
 * Terminal states (delivered, cancelled) map to an empty set — no transitions allowed.
 */
const ALLOWED_TRANSITIONS = {
    pending: new Set(["confirmed", "cancelled"]),
    confirmed: new Set(["preparing", "cancelled"]),
    preparing: new Set(["ready_for_pickup", "cancelled"]),
    ready_for_pickup: new Set(["out_for_delivery", "delivered", "cancelled"]),
    out_for_delivery: new Set(["delivered", "cancelled"]),
    delivered: new Set(),
    cancelled: new Set(),
};
/**
 * adminUpdateOrderStatus
 *
 * Updates the delivery status of an order.
 * Requires the caller to have the 'admin' role.
 *
 * Request data:
 *   - orderId: string
 *   - status: string  (new delivery status)
 *   - etaMinutes?: number  (required when status == 'out_for_delivery')
 */
exports.adminUpdateOrderStatus = (0, https_1.onCall)(async (request) => {
    await (0, verifyAdmin_1.verifyAdmin)(request.auth);
    const { orderId, status, etaMinutes } = request.data;
    // ── Field validation ──────────────────────────────────────────────────────
    if (!orderId || typeof orderId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "orderId is required.");
    }
    if (!status || typeof status !== "string") {
        throw new https_1.HttpsError("invalid-argument", "status is required.");
    }
    if (!VALID_STATUSES.has(status)) {
        throw new https_1.HttpsError("invalid-argument", `Invalid status value: ${status}.`);
    }
    if (status === "out_for_delivery" && typeof etaMinutes !== "number") {
        throw new https_1.HttpsError("invalid-argument", "etaMinutes is required when status is out_for_delivery.");
    }
    // ── Order existence check ─────────────────────────────────────────────────
    const db = admin.firestore();
    const orderRef = db.doc(`orders/${orderId}`);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
        throw new https_1.HttpsError("not-found", `Order ${orderId} not found.`);
    }
    const orderData = orderSnap.data();
    const currentStatus = orderData["status"];
    // ── Status transition validation ──────────────────────────────────────────
    if (!currentStatus || !ALLOWED_TRANSITIONS[currentStatus]) {
        throw new https_1.HttpsError("failed-precondition", `Order ${orderId} has an unrecognised current status: ${currentStatus}.`);
    }
    if (!ALLOWED_TRANSITIONS[currentStatus].has(status)) {
        throw new https_1.HttpsError("failed-precondition", `Invalid status transition from ${currentStatus} to ${status}.`);
    }
    // ── Persist the update ────────────────────────────────────────────────────
    const updateData = {
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (status === "out_for_delivery" && etaMinutes !== undefined) {
        updateData["etaMinutes"] = etaMinutes;
    }
    await orderRef.update(updateData);
    // ── Push notification to customer (Requirement 4.3) ───────────────────────
    const uid = orderData["uid"];
    if (uid) {
        await (0, sendOrderStatusNotification_1.sendOrderStatusNotification)(orderId, uid, status, etaMinutes);
    }
    return { success: true };
});
//# sourceMappingURL=adminUpdateOrderStatus.js.map