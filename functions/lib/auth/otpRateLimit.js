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
exports.checkOtpRateLimit = void 0;
exports.checkAndIncrementOtpRateLimit = checkAndIncrementOtpRateLimit;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
/**
 * Maximum number of OTP requests allowed per identifier (phone or email)
 * within a rolling 1-hour window.
 *
 * Satisfies Requirement 11, Criteria 5.
 */
const MAX_OTP_REQUESTS_PER_HOUR = 5;
/**
 * checkAndIncrementOtpRateLimit
 *
 * Checks and atomically increments the OTP request count for an identifier
 * (phone number or email address). Returns whether the request is rate-limited.
 *
 * The rate-limit window is a rolling 1-hour period starting from the first
 * request in the current window. Once the window expires (> 1 hour since
 * windowStart), the counter resets.
 *
 * Documents are stored in /otp_rate_limits/{sanitisedIdentifier}.
 * The collection is write-protected by Firestore Security Rules — only the
 * server SDK (Cloud Functions) may read or write it.
 *
 * Satisfies Requirement 11, Criteria 5.
 *
 * @param identifier - Phone number (E.164) or email address to rate-limit.
 * @returns OtpRateLimitStatus indicating whether the request is allowed.
 */
async function checkAndIncrementOtpRateLimit(identifier) {
    // Sanitise the identifier to produce a valid Firestore document ID.
    // Replace any character that is not alphanumeric with an underscore.
    const docId = identifier.replace(/[^a-zA-Z0-9]/g, "_");
    const ref = admin
        .firestore()
        .collection("otp_rate_limits")
        .doc(docId);
    return admin.firestore().runTransaction(async (tx) => {
        var _a;
        const doc = await tx.get(ref);
        const now = new Date();
        const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
        // First request ever for this identifier — create the document.
        if (!doc.exists) {
            tx.set(ref, {
                identifier,
                requestCount: 1,
                windowStart: now,
                lastRequest: now,
            });
            return { isRateLimited: false, requestCount: 1, resetAt: null };
        }
        const data = doc.data();
        const windowStart = data.windowStart.toDate();
        // The current window has expired — reset the counter and start a new window.
        if (windowStart < oneHourAgo) {
            tx.update(ref, {
                requestCount: 1,
                windowStart: now,
                lastRequest: now,
            });
            return { isRateLimited: false, requestCount: 1, resetAt: null };
        }
        // Still within the current window — check the count.
        const currentCount = (_a = data.requestCount) !== null && _a !== void 0 ? _a : 0;
        const newCount = currentCount + 1;
        if (newCount > MAX_OTP_REQUESTS_PER_HOUR) {
            // Rate limit exceeded — do NOT increment; return the time the window resets.
            const resetAt = new Date(windowStart.getTime() + 60 * 60 * 1000);
            return {
                isRateLimited: true,
                requestCount: currentCount,
                resetAt,
            };
        }
        // Within limit — increment and allow.
        tx.update(ref, { requestCount: newCount, lastRequest: now });
        return { isRateLimited: false, requestCount: newCount, resetAt: null };
    });
}
/**
 * checkOtpRateLimit
 *
 * HTTPS callable Cloud Function that checks the OTP rate limit for a given
 * identifier (phone number or email address) and increments the counter if
 * the request is allowed.
 *
 * Request data:
 *   - identifier: string — phone number (E.164) or email address
 *
 * Returns:
 *   - { isRateLimited, requestCount, resetAt }
 *
 * Satisfies Requirement 11, Criteria 5.
 */
exports.checkOtpRateLimit = functions.https.onCall(async (data, _context) => {
    var _a, _b;
    const identifier = data.identifier;
    if (!identifier || typeof identifier !== "string" || identifier.trim() === "") {
        throw new functions.https.HttpsError("invalid-argument", "identifier is required and must be a non-empty string");
    }
    const status = await checkAndIncrementOtpRateLimit(identifier.trim());
    return {
        isRateLimited: status.isRateLimited,
        requestCount: status.requestCount,
        resetAt: (_b = (_a = status.resetAt) === null || _a === void 0 ? void 0 : _a.toISOString()) !== null && _b !== void 0 ? _b : null,
    };
});
//# sourceMappingURL=otpRateLimit.js.map