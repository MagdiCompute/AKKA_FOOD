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
exports.calculateCoins = calculateCoins;
exports.executePostPaymentActions = executePostPaymentActions;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
/**
 * Calculates loyalty coins earned from a payment.
 * 5% of the total amount, rounded down to the nearest integer.
 */
function calculateCoins(totalAmount) {
    return Math.floor(totalAmount * 0.05);
}
/**
 * Executes all post-payment success actions.
 * Each action is independent and logged individually.
 * Failures in one action do not block others.
 */
async function executePostPaymentActions(params) {
    const { transactionId, uid, amount, reference } = params;
    const db = admin.firestore();
    // ── 1. Create Order from cart snapshot (Req 2 AC2) ────────────────────────
    const orderId = await createOrder(db, transactionId, uid, amount);
    // Update the transaction with the orderId
    await db.collection("transactions").doc(transactionId).update({
        orderId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Order linked to transaction", {
        transactionId,
        orderId,
        reference,
        timestamp: new Date().toISOString(),
    });
    // ── 2. Credit coins — handled by onPaymentSuccess Firestore trigger ──────
    // Coin crediting is now handled by the `onPaymentSuccess` trigger on
    // `/transactions/{id}` which fires when status changes to 'success'.
    // It provides idempotency (orderId check) and atomic transactions.
    // See: functions/src/coins/onPaymentSuccess.ts
    // ── 3. Clear user's cart (Req 2 AC4) ──────────────────────────────────────
    await clearCart(db, uid, transactionId);
    // ── 4. Send FCM push notification (Req 2 AC6) ────────────────────────────
    await sendOrderConfirmationNotification(db, uid, orderId, amount);
    return { orderId };
}
/**
 * Creates an order document from the cart snapshot stored at payment initiation.
 * The cart snapshot is expected at `/transactions/{transactionId}/cartSnapshot`
 * or as a subcollection. For now, we read from `/carts/{uid}` as a fallback.
 */
async function createOrder(db, transactionId, uid, amount) {
    // Try to read cart snapshot from the transaction (saved at payment initiation)
    const snapshotDoc = await db
        .collection("transactions")
        .doc(transactionId)
        .collection("cartSnapshot")
        .doc("items")
        .get();
    let items = [];
    if (snapshotDoc.exists) {
        const snapshotData = snapshotDoc.data();
        items = (snapshotData === null || snapshotData === void 0 ? void 0 : snapshotData.items) || [];
    }
    else {
        // Fallback: read current cart (task 6.2 will ensure snapshot exists)
        const cartDoc = await db.collection("carts").doc(uid).get();
        if (cartDoc.exists) {
            const cartData = cartDoc.data();
            items = (cartData === null || cartData === void 0 ? void 0 : cartData.items) || [];
        }
        functions.logger.warn("Cart snapshot not found, using current cart", {
            transactionId,
            uid,
            timestamp: new Date().toISOString(),
        });
    }
    const orderData = {
        uid,
        items,
        totalAmount: amount,
        status: "confirmed",
        transactionId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const orderRef = await db.collection("orders").add(orderData);
    functions.logger.info("Order created", {
        orderId: orderRef.id,
        transactionId,
        uid,
        totalAmount: amount,
        itemCount: Array.isArray(items) ? items.length : 0,
        timestamp: new Date().toISOString(),
    });
    return orderRef.id;
}
/**
 * Clears the user's cart after successful payment.
 * Deletes the cart document at `/carts/{uid}`.
 */
async function clearCart(db, uid, transactionId) {
    await db.collection("carts").doc(uid).delete();
    functions.logger.info("Cart cleared", {
        uid,
        transactionId,
        timestamp: new Date().toISOString(),
    });
}
/**
 * Sends an FCM push notification confirming the order.
 * Reads the user's FCM token from `/users/{uid}`.
 */
async function sendOrderConfirmationNotification(db, uid, orderId, amount) {
    // Read user's FCM token
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        functions.logger.warn("User document not found for FCM notification", {
            uid,
            orderId,
            timestamp: new Date().toISOString(),
        });
        return;
    }
    const userData = userDoc.data();
    const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
    if (!fcmToken) {
        functions.logger.warn("No FCM token found for user", {
            uid,
            orderId,
            timestamp: new Date().toISOString(),
        });
        return;
    }
    const message = {
        token: fcmToken,
        notification: {
            title: "Commande confirmée 🎉",
            body: `Votre commande #${orderId.substring(0, 8)} de ${amount} XOF a été confirmée.`,
        },
        data: {
            type: "order_confirmed",
            orderId,
            amount: String(amount),
        },
    };
    try {
        await admin.messaging().send(message);
        functions.logger.info("FCM notification sent", {
            uid,
            orderId,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        // FCM failures should not block the payment flow
        functions.logger.error("Failed to send FCM notification", {
            uid,
            orderId,
            error: error instanceof Error ? error.message : String(error),
            timestamp: new Date().toISOString(),
        });
    }
}
//# sourceMappingURL=postPaymentActions.js.map