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
exports.orangeMoneyCallback = void 0;
exports.computeHmacSignature = computeHmacSignature;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const functions = __importStar(require("firebase-functions"));
const crypto = __importStar(require("crypto"));
const postPaymentActions_1 = require("./postPaymentActions");
/**
 * Shared secret for HMAC-SHA256 callback signature validation.
 * Stored in Firebase Secret Manager — never exposed to the client.
 */
const orangeMoneyCallbackSecret = (0, params_1.defineSecret)("ORANGE_MONEY_CALLBACK_SECRET");
/**
 * Computes HMAC-SHA256 signature over the request body fields (excluding `signature`).
 * The fields are sorted alphabetically by key and concatenated as key=value pairs
 * joined by `&`, then signed with the shared secret.
 */
function computeHmacSignature(body, secret) {
    // Exclude the signature field from the payload
    const payload = Object.keys(body)
        .filter((key) => key !== "signature")
        .sort()
        .map((key) => `${key}=${body[key]}`)
        .join("&");
    return crypto
        .createHmac("sha256", secret)
        .update(payload)
        .digest("hex");
}
/**
 * orangeMoneyCallback — HTTPS Trigger (public endpoint)
 *
 * Called by Orange Money Mali when a payment status changes.
 *
 * Steps:
 * 1. Validate request signature (HMAC-SHA256)
 * 2. Look up transaction by `reference`
 * 3. Check idempotency: if already `success`, return 200 immediately
 * 4. Update transaction status atomically via Firestore transaction
 * 5. If `success`: create order, credit coins, clear cart, send FCM notification
 *
 * Validates:
 * - Req 6 AC1: Validate callback signatures before processing
 * - Req 6 AC4: Idempotent — same callback twice won't duplicate effects
 * - Req 6 AC3: Log all Transaction state changes with timestamps
 * - Req 2 AC1: Update Transaction status to `success` on success callback
 * - Req 3 AC1: Update Transaction status to `failed` on failure callback
 */
exports.orangeMoneyCallback = (0, https_1.onRequest)({ secrets: [orangeMoneyCallbackSecret] }, async (req, res) => {
    var _a;
    // Only accept POST requests
    if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
    }
    const body = req.body;
    // ── Step 1: Validate HMAC signature (Req 6 AC1) ─────────────────────────
    const { signature, reference, status: callbackStatus, transactionId: externalTxnId } = body;
    if (!signature || !reference || !callbackStatus) {
        functions.logger.warn("Callback missing required fields", {
            hasSignature: !!signature,
            hasReference: !!reference,
            hasStatus: !!callbackStatus,
            timestamp: new Date().toISOString(),
        });
        res.status(400).json({ error: "Missing required fields" });
        return;
    }
    const secret = orangeMoneyCallbackSecret.value();
    const expectedSignature = computeHmacSignature(body, secret);
    if (!crypto.timingSafeEqual(Buffer.from(signature, "hex"), Buffer.from(expectedSignature, "hex"))) {
        functions.logger.warn("Invalid callback signature", {
            reference,
            timestamp: new Date().toISOString(),
        });
        res.status(401).json({ error: "Invalid signature" });
        return;
    }
    // ── Step 2: Look up transaction by reference ────────────────────────────
    const db = admin.firestore();
    const transactionsRef = db.collection("transactions");
    const querySnapshot = await transactionsRef
        .where("reference", "==", reference)
        .limit(1)
        .get();
    if (querySnapshot.empty) {
        functions.logger.warn("Transaction not found for reference", {
            reference,
            timestamp: new Date().toISOString(),
        });
        res.status(404).json({ error: "Transaction not found" });
        return;
    }
    const transactionDoc = querySnapshot.docs[0];
    const transactionRef = transactionDoc.ref;
    // Map callback status to our internal status
    const newStatus = mapCallbackStatus(callbackStatus);
    if (!newStatus) {
        functions.logger.warn("Unknown callback status", {
            reference,
            callbackStatus,
            timestamp: new Date().toISOString(),
        });
        res.status(400).json({ error: "Unknown status" });
        return;
    }
    // ── Steps 3 & 4: Idempotency check + atomic status update (Req 6 AC4) ──
    let alreadyProcessed = false;
    await db.runTransaction(async (t) => {
        const doc = await t.get(transactionRef);
        const currentData = doc.data();
        if (!currentData) {
            throw new Error("Transaction document data is missing");
        }
        // Idempotency: if already in terminal state `success`, skip
        if (currentData.status === "success") {
            alreadyProcessed = true;
            return;
        }
        // Update transaction status atomically
        const now = admin.firestore.FieldValue.serverTimestamp();
        t.update(transactionRef, {
            status: newStatus,
            updatedAt: now,
        });
    });
    // Audit log: Transaction state change (Req 6 AC3)
    if (alreadyProcessed) {
        functions.logger.info("Duplicate callback — already processed", {
            transactionId: transactionDoc.id,
            reference,
            currentStatus: "success",
            callbackStatus,
            timestamp: new Date().toISOString(),
        });
        res.status(200).json({ message: "Already processed" });
        return;
    }
    functions.logger.info("Transaction status updated", {
        transactionId: transactionDoc.id,
        reference,
        externalTransactionId: externalTxnId,
        oldStatus: (_a = transactionDoc.data()) === null || _a === void 0 ? void 0 : _a.status,
        newStatus,
        timestamp: new Date().toISOString(),
    });
    // ── Step 5: Post-success actions (Req 2 AC2, AC3, AC4, AC6) ────────────
    if (newStatus === "success") {
        try {
            const transactionData = transactionDoc.data();
            const { orderId } = await (0, postPaymentActions_1.executePostPaymentActions)({
                transactionId: transactionDoc.id,
                uid: transactionData === null || transactionData === void 0 ? void 0 : transactionData.uid,
                amount: transactionData === null || transactionData === void 0 ? void 0 : transactionData.amount,
                reference: reference,
            });
            functions.logger.info("Post-payment actions completed", {
                transactionId: transactionDoc.id,
                orderId,
                reference,
                timestamp: new Date().toISOString(),
            });
        }
        catch (error) {
            // Log the error but still return 200 to Orange Money
            // (the transaction status is already updated; post-actions can be retried)
            functions.logger.error("Post-payment actions failed", {
                transactionId: transactionDoc.id,
                reference,
                error: error instanceof Error ? error.message : String(error),
                timestamp: new Date().toISOString(),
            });
        }
    }
    res.status(200).json({ message: "OK", status: newStatus });
});
/**
 * Maps Orange Money callback status strings to internal PaymentStatus values.
 * Returns null for unrecognized statuses.
 */
function mapCallbackStatus(callbackStatus) {
    const statusMap = {
        success: "success",
        successful: "success",
        completed: "success",
        failed: "failed",
        failure: "failed",
        rejected: "failed",
        cancelled: "cancelled",
        canceled: "cancelled",
    };
    return statusMap[callbackStatus.toLowerCase()] || null;
}
//# sourceMappingURL=orangeMoneyCallback.js.map