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
exports.initiatePayment = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const uuid_1 = require("uuid");
const functions = __importStar(require("firebase-functions"));
/**
 * Orange Money Mali API key stored in Firebase Secret Manager.
 * Accessed only by Cloud Functions — never exposed to the client.
 */
const orangeMoneyApiKey = (0, params_1.defineSecret)("ORANGE_MONEY_API_KEY");
/**
 * Orange Money Mali API base URL.
 * Stored as a secret so it can differ between environments.
 */
const orangeMoneyBaseUrl = (0, params_1.defineSecret)("ORANGE_MONEY_BASE_URL");
/**
 * The public callback URL that Orange Money will call when payment status changes.
 */
const orangeMoneyCallbackUrl = (0, params_1.defineSecret)("ORANGE_MONEY_CALLBACK_URL");
/**
 * initiatePayment — HTTPS Callable Cloud Function
 *
 * Steps:
 * 1. Validate caller's auth token
 * 2. Generate unique reference (UUID v4)
 * 3. Create /transactions/{id} with status `pending`
 * 4. Call Orange Money Mali API: POST /payment with { amount, reference, phoneNumber, callbackUrl }
 * 5. Return { transactionId, reference } to Flutter app
 *
 * Validates:
 * - Req 1 AC1: Initiate payment request with amount, reference, phone number
 * - Req 1 AC3: Create Transaction record with status `pending`
 * - Req 1 AC4: Generate unique, non-guessable transaction reference
 * - Req 6 AC2: API calls from Cloud Functions only
 * - Req 6 AC3: Log all Transaction state changes with timestamps
 */
exports.initiatePayment = (0, https_1.onCall)({ secrets: [orangeMoneyApiKey, orangeMoneyBaseUrl, orangeMoneyCallbackUrl] }, async (request) => {
    // ── Step 1: Validate caller's auth token ──────────────────────────────
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated to initiate a payment.");
    }
    const uid = request.auth.uid;
    // ── Validate request data ─────────────────────────────────────────────
    const { amount, phoneNumber, orderId, cartItems, subtotal, deliveryFee, discount, redeemedCoins } = request.data;
    if (!amount || typeof amount !== "number" || amount <= 0) {
        throw new https_1.HttpsError("invalid-argument", "amount is required and must be a positive number (XOF).");
    }
    if (!Number.isInteger(amount)) {
        throw new https_1.HttpsError("invalid-argument", "amount must be a whole number (XOF does not use decimals).");
    }
    if (!phoneNumber || typeof phoneNumber !== "string") {
        throw new https_1.HttpsError("invalid-argument", "phoneNumber is required.");
    }
    // Basic phone number format validation for Mali (8 digits, optionally prefixed)
    const sanitizedPhone = phoneNumber.replace(/\s+/g, "");
    if (!/^\+?223\d{8}$|^\d{8}$/.test(sanitizedPhone)) {
        throw new https_1.HttpsError("invalid-argument", "phoneNumber must be a valid Mali phone number.");
    }
    // ── Step 2: Generate unique reference (UUID v4) ───────────────────────
    const reference = (0, uuid_1.v4)();
    // ── Step 3: Create /transactions/{id} with status `pending` ───────────
    const db = admin.firestore();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const transactionData = {
        reference,
        uid,
        amount,
        status: "pending",
        orderId: orderId || null,
        createdAt: now,
        updatedAt: now,
    };
    const transactionRef = await db.collection("transactions").add(transactionData);
    const transactionId = transactionRef.id;
    // Audit log: Transaction state change (Req 6 AC3)
    functions.logger.info("Transaction created", {
        transactionId,
        reference,
        uid,
        amount,
        status: "pending",
        timestamp: new Date().toISOString(),
    });
    // ── Step 3b: Save cart snapshot to prevent cart changes mid-payment ────
    if (cartItems && Array.isArray(cartItems) && cartItems.length > 0) {
        const cartSnapshotData = {
            items: cartItems.map((item) => ({
                mealId: item.mealId,
                mealName: item.mealName,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
            })),
            subtotal: subtotal !== null && subtotal !== void 0 ? subtotal : amount,
            deliveryFee: deliveryFee !== null && deliveryFee !== void 0 ? deliveryFee : 0,
            discount: discount !== null && discount !== void 0 ? discount : 0,
            total: amount,
            redeemedCoins: redeemedCoins !== null && redeemedCoins !== void 0 ? redeemedCoins : 0,
            savedAt: now,
        };
        await db
            .collection("transactions")
            .doc(transactionId)
            .collection("cartSnapshot")
            .doc("items")
            .set(cartSnapshotData);
        functions.logger.info("Cart snapshot saved", {
            transactionId,
            reference,
            itemCount: cartItems.length,
            timestamp: new Date().toISOString(),
        });
    }
    // ── Step 4: Call Orange Money Mali API ─────────────────────────────────
    const apiKey = orangeMoneyApiKey.value();
    const baseUrl = orangeMoneyBaseUrl.value();
    const callbackUrl = orangeMoneyCallbackUrl.value();
    const paymentPayload = {
        amount,
        reference,
        phoneNumber: sanitizedPhone,
        callbackUrl,
    };
    try {
        const response = await fetch(`${baseUrl}/payment`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${apiKey}`,
            },
            body: JSON.stringify(paymentPayload),
        });
        if (!response.ok) {
            const errorBody = await response.text();
            functions.logger.error("Orange Money API error", {
                transactionId,
                reference,
                statusCode: response.status,
                error: errorBody,
            });
            // Update transaction to failed if API rejects the request
            await transactionRef.update({
                status: "failed",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            functions.logger.info("Transaction status updated", {
                transactionId,
                reference,
                oldStatus: "pending",
                newStatus: "failed",
                reason: "Orange Money API rejected request",
                timestamp: new Date().toISOString(),
            });
            throw new https_1.HttpsError("internal", "Payment initiation failed. Please try again.");
        }
        functions.logger.info("Orange Money API payment initiated", {
            transactionId,
            reference,
            timestamp: new Date().toISOString(),
        });
    }
    catch (error) {
        // If it's already an HttpsError, re-throw it
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        functions.logger.error("Orange Money API network error", {
            transactionId,
            reference,
            error: error instanceof Error ? error.message : String(error),
        });
        // Update transaction to failed on network error
        await transactionRef.update({
            status: "failed",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.info("Transaction status updated", {
            transactionId,
            reference,
            oldStatus: "pending",
            newStatus: "failed",
            reason: "Network error calling Orange Money API",
            timestamp: new Date().toISOString(),
        });
        throw new https_1.HttpsError("internal", "Payment initiation failed due to a network error. Please try again.");
    }
    // ── Step 5: Return { transactionId, reference } to Flutter app ────────
    return {
        transactionId,
        reference,
    };
});
//# sourceMappingURL=initiatePayment.js.map