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
exports.redeemCoins = void 0;
exports.validateRedemptionAmount = validateRedemptionAmount;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
/**
 * Validates that the redeemed coins amount is a positive multiple of 1000.
 *
 * Validates: Req 2 AC2 — Only allow redemption in multiples of 1000
 */
function validateRedemptionAmount(redeemedCoins) {
    return (typeof redeemedCoins === "number" &&
        Number.isInteger(redeemedCoins) &&
        redeemedCoins > 0 &&
        redeemedCoins % 1000 === 0);
}
/**
 * redeemCoins — HTTPS Callable Cloud Function
 *
 * Called from the Cart checkout flow to redeem loyalty coins for a discount.
 *
 * Steps:
 * 1. Validate caller is authenticated
 * 2. Validate redeemedCoins is a positive multiple of 1000
 * 3. Atomic Firestore transaction:
 *    a. Read current coinBalance from /users/{uid}
 *    b. Verify balance >= redeemedCoins (Req 2 AC1, Req 2 AC5)
 *    c. Create CoinTransaction doc with amount (-redeemedCoins), reason "Redemption", orderId, timestamp
 *    d. Update coinBalance (balance - redeemedCoins)
 * 4. Return success
 *
 * Validates:
 * - Req 2 AC1: Verify balance >= 1000 before allowing redemption
 * - Req 2 AC2: Only allow redemption in multiples of 1000
 * - Req 2 AC3: Debit redeemed amount and create CoinTransaction with reason "Redemption"
 * - Req 2 AC5: Ensure balance never goes below 0
 * - Req 5 AC2: Use Firestore transactions for atomic updates
 */
exports.redeemCoins = (0, https_1.onCall)(async (request) => {
    // ── Step 1: Validate authentication ───────────────────────────────────────
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated to redeem coins.");
    }
    const uid = request.auth.uid;
    const { redeemedCoins, orderId } = request.data;
    // ── Step 2: Validate redeemedCoins is a multiple of 1000 (Req 2 AC2) ─────
    if (!validateRedemptionAmount(redeemedCoins)) {
        throw new https_1.HttpsError("invalid-argument", "Redeemed coins must be a positive integer and a multiple of 1000.");
    }
    if (!orderId || typeof orderId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "A valid orderId is required.");
    }
    const amount = redeemedCoins;
    const db = admin.firestore();
    // ── Step 3: Atomic Firestore transaction (Req 5 AC2) ──────────────────────
    try {
        await db.runTransaction(async (t) => {
            var _a;
            const userRef = db.doc(`users/${uid}`);
            const userSnap = await t.get(userRef);
            const balance = ((_a = userSnap.data()) === null || _a === void 0 ? void 0 : _a.coinBalance) || 0;
            // Verify balance >= redeemedCoins (Req 2 AC1, Req 2 AC5)
            if (balance < amount) {
                throw new https_1.HttpsError("failed-precondition", "Insufficient coins. Current balance is less than the requested redemption amount.");
            }
            // Create CoinTransaction record (Req 2 AC3)
            const coinTxRef = db
                .collection("users")
                .doc(uid)
                .collection("coinTransactions")
                .doc();
            t.set(coinTxRef, {
                amount: -amount,
                reason: "Redemption",
                orderId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Update user's coinBalance atomically
            t.update(userRef, {
                coinBalance: balance - amount,
            });
        });
        return { success: true };
    }
    catch (error) {
        // Re-throw HttpsError instances directly so the client gets the proper code
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError("internal", "An unexpected error occurred while redeeming coins.");
    }
});
//# sourceMappingURL=redeemCoins.js.map