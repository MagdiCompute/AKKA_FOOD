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
exports.resetLoginAttempts = exports.recordFailedLoginAttempt = exports.checkAccountLock = void 0;
const functions = __importStar(require("firebase-functions"));
const accountLockout_1 = require("./accountLockout");
/**
 * checkAccountLock
 *
 * HTTPS callable function that checks whether a user account is locked
 * before allowing a sign-in attempt (Requirement 4.5).
 *
 * Request data:
 *   - uid: string — the Firebase Auth user UID to check
 *
 * Returns:
 *   - { isLocked, lockedUntil, failedAttempts }
 */
exports.checkAccountLock = functions.https.onCall(async (data, _context) => {
    var _a, _b;
    const uid = data.uid;
    if (!uid) {
        throw new functions.https.HttpsError("invalid-argument", "uid is required");
    }
    const status = await (0, accountLockout_1.checkLockStatus)(uid);
    return {
        isLocked: status.isLocked,
        lockedUntil: (_b = (_a = status.lockedUntil) === null || _a === void 0 ? void 0 : _a.toISOString()) !== null && _b !== void 0 ? _b : null,
        failedAttempts: status.failedAttempts,
    };
});
/**
 * recordFailedLoginAttempt
 *
 * HTTPS callable function that records a failed login attempt for a uid.
 * Locks the account after MAX_ATTEMPTS consecutive failures (Requirement 4.4).
 *
 * Request data:
 *   - uid: string — the Firebase Auth user UID
 */
exports.recordFailedLoginAttempt = functions.https.onCall(async (data, _context) => {
    const uid = data.uid;
    if (!uid) {
        throw new functions.https.HttpsError("invalid-argument", "uid is required");
    }
    await (0, accountLockout_1.recordFailedAttempt)(uid);
    return { success: true };
});
/**
 * resetLoginAttempts
 *
 * HTTPS callable function that resets failed login attempts after a
 * successful sign-in (Requirement 4.1).
 *
 * Request data:
 *   - uid: string — the Firebase Auth user UID
 */
exports.resetLoginAttempts = functions.https.onCall(async (data, _context) => {
    const uid = data.uid;
    if (!uid) {
        throw new functions.https.HttpsError("invalid-argument", "uid is required");
    }
    await (0, accountLockout_1.resetFailedAttempts)(uid);
    return { success: true };
});
//# sourceMappingURL=checkAccountLock.js.map