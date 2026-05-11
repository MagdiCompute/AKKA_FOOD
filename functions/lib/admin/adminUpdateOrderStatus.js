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
 * Valid delivery status values per the design doc.
 */
const VALID_STATUSES = new Set([
    "pending",
    "confirmed",
    "preparing",
    "out_for_delivery",
    "delivered",
    "failed",
]);
/**
 * Allowed status transitions per the design doc:
 *   pending → confirmed → preparing → out_for_delivery → delivered
 *                                                       → failed
 *
 * Terminal states (delivered, failed) have no outgoing transitions.
 */
const ALLOWED_TRANSITIONS = {
    pending: new Set(["confirmed"]),
    confirmed: new Set(["preparing"]),
    preparing: new Set(["out_for_delivery"]),
    out_for_delivery: new Set(["delivered", "failed"]),
    delivered: new Set(),
    failed: new Set(),
};
/**
 * adminUpdateOrderStatus
 *
 * HTTPS Callable Cloud Function that updates the delivery status of an order.
 * Requires the caller to have the 'admin' role (checked via users/{uid}.role).
 *
 * Request data:
 *   - orderId: string        — the order document ID
 *   - status: string         — the new delivery status
 *   - etaMinutes?: number    — required when status is 'out_for_delivery'
 *
 * Returns: { success: true } on success.
 *
 * Error codes:
 *   - unauthenticated    — caller is not authenticated
 *   - permission-denied  — caller is not an admin
 *   - invalid-argument   — missing/invalid fields or etaMinutes not provided for out_for_delivery
 *   - not-found          — order does not exist
 *   - failed-precondition — illegal status transition
 */
exports.adminUpdateOrderStatus = (0, https_1.onCall)(async (request) => {
    // 1. Validate admin role
    await (0, verifyAdmin_1.verifyAdmin)(request.auth);
    const { orderId, status, etaMinutes } = request.data;
    // 2. Field validation
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
    // 3. Order existence check
    const db = admin.firestore();
    const orderRef = db.doc(`orders/${orderId}`);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
        throw new https_1.HttpsError("not-found", `Order ${orderId} not found.`);
    }
    const orderData = orderSnap.data();
    const currentStatus = orderData["status"];
    // 4. Status transition validation
    if (!currentStatus || !ALLOWED_TRANSITIONS[currentStatus]) {
        throw new https_1.HttpsError("failed-precondition", `Order ${orderId} has an unrecognised current status: ${currentStatus}.`);
    }
    if (!ALLOWED_TRANSITIONS[currentStatus].has(status)) {
        throw new https_1.HttpsError("failed-precondition", `Invalid status transition from ${currentStatus} to ${status}.`);
    }
    // 5. Persist the update
    const updateData = {
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (status === "out_for_delivery" && etaMinutes !== undefined) {
        updateData["etaMinutes"] = etaMinutes;
    }
    await orderRef.update(updateData);
    // 6. Send push notification to customer
    const uid = orderData["uid"];
    if (uid) {
        await (0, sendOrderStatusNotification_1.sendOrderStatusNotification)(orderId, uid, status, etaMinutes);
    }
    return { success: true };
});
//# sourceMappingURL=adminUpdateOrderStatus.js.map