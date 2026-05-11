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
exports.createOrder = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const functions = __importStar(require("firebase-functions"));
/**
 * createOrder — HTTPS Callable Cloud Function
 *
 * Standalone callable for creating an order from a successful transaction's
 * cart snapshot. Useful for admin retry scenarios or independent invocation
 * when the automatic post-payment flow needs to be re-triggered.
 *
 * Steps:
 * 1. Validate caller's auth token
 * 2. Validate the transaction exists and has status `success`
 * 3. Check idempotency: if an order already exists for this transaction, return it
 * 4. Read cart snapshot from `/transactions/{transactionId}/cartSnapshot/items`
 * 5. Create `/orders/{orderId}` with order data
 * 6. Link orderId back to the transaction document
 * 7. Return { orderId }
 *
 * Validates:
 * - Req 2 AC2: Order_Service SHALL create a new Order from Cart summary with unique Order ID
 * - Req 6 AC4: Idempotency — processing same request twice SHALL NOT create duplicate Orders
 */
exports.createOrder = (0, https_1.onCall)(async (request) => {
    var _a;
    // ── Step 1: Validate caller's auth token ──────────────────────────────
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated to create an order.");
    }
    const uid = request.auth.uid;
    // ── Validate request data ─────────────────────────────────────────────
    const { transactionId } = request.data;
    if (!transactionId || typeof transactionId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "transactionId is required and must be a string.");
    }
    const db = admin.firestore();
    // ── Step 2: Validate the transaction exists and has status `success` ───
    const transactionRef = db.collection("transactions").doc(transactionId);
    const transactionDoc = await transactionRef.get();
    if (!transactionDoc.exists) {
        throw new https_1.HttpsError("not-found", "Transaction not found.");
    }
    const transactionData = transactionDoc.data();
    // Verify the caller owns this transaction (unless admin)
    if (transactionData.uid !== uid) {
        // Check if caller is admin
        const userDoc = await db.collection("users").doc(uid).get();
        const isAdmin = userDoc.exists && ((_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role) === "admin";
        if (!isAdmin) {
            throw new https_1.HttpsError("permission-denied", "You do not have permission to create an order for this transaction.");
        }
    }
    if (transactionData.status !== "success") {
        throw new https_1.HttpsError("failed-precondition", `Transaction status is '${transactionData.status}'. Only successful transactions can generate orders.`);
    }
    // ── Step 3: Idempotency check — return existing order if already created ─
    if (transactionData.orderId) {
        functions.logger.info("Order already exists for transaction (idempotent return)", {
            transactionId,
            orderId: transactionData.orderId,
            uid,
            timestamp: new Date().toISOString(),
        });
        return { orderId: transactionData.orderId };
    }
    // ── Step 4: Read cart snapshot ────────────────────────────────────────
    const snapshotDoc = await transactionRef
        .collection("cartSnapshot")
        .doc("items")
        .get();
    let items = [];
    if (snapshotDoc.exists) {
        const snapshotData = snapshotDoc.data();
        items = (snapshotData === null || snapshotData === void 0 ? void 0 : snapshotData.items) || [];
    }
    else {
        // Fallback: read current cart
        const cartDoc = await db.collection("carts").doc(transactionData.uid).get();
        if (cartDoc.exists) {
            const cartData = cartDoc.data();
            items = (cartData === null || cartData === void 0 ? void 0 : cartData.items) || [];
        }
        functions.logger.warn("Cart snapshot not found, using current cart", {
            transactionId,
            uid: transactionData.uid,
            timestamp: new Date().toISOString(),
        });
    }
    // ── Step 5: Create order document ─────────────────────────────────────
    const orderData = {
        uid: transactionData.uid,
        items,
        totalAmount: transactionData.amount,
        status: "confirmed",
        transactionId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const orderRef = await db.collection("orders").add(orderData);
    const orderId = orderRef.id;
    // ── Step 6: Link orderId back to the transaction ──────────────────────
    await transactionRef.update({
        orderId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Order created via createOrder callable", {
        orderId,
        transactionId,
        uid: transactionData.uid,
        totalAmount: transactionData.amount,
        itemCount: Array.isArray(items) ? items.length : 0,
        timestamp: new Date().toISOString(),
    });
    return { orderId };
});
//# sourceMappingURL=createOrder.js.map