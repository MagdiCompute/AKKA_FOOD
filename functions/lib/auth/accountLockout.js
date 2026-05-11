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
exports.recordFailedAttempt = recordFailedAttempt;
exports.resetFailedAttempts = resetFailedAttempts;
exports.checkLockStatus = checkLockStatus;
const admin = __importStar(require("firebase-admin"));
const MAX_ATTEMPTS = 5;
const LOCKOUT_DURATION_MS = 15 * 60 * 1000; // 15 minutes
/**
 * recordFailedAttempt
 *
 * Records a failed login attempt for the given uid.
 * If attempts reach MAX_ATTEMPTS within the window, locks the account
 * for 15 minutes and resets the counter (Requirement 4.4).
 *
 * @param uid - The Firebase Auth user UID
 */
async function recordFailedAttempt(uid) {
    const ref = admin.firestore().collection("users").doc(uid);
    await admin.firestore().runTransaction(async (tx) => {
        var _a;
        const doc = await tx.get(ref);
        if (!doc.exists)
            return;
        const data = doc.data();
        const attempts = ((_a = data["failedLoginAttempts"]) !== null && _a !== void 0 ? _a : 0) + 1;
        const update = { failedLoginAttempts: attempts };
        if (attempts >= MAX_ATTEMPTS) {
            update["lockedUntil"] = new Date(Date.now() + LOCKOUT_DURATION_MS);
            update["failedLoginAttempts"] = 0; // reset after locking
        }
        tx.update(ref, update);
    });
}
/**
 * resetFailedAttempts
 *
 * Resets failed login attempts after a successful sign-in (Requirement 4.1).
 *
 * @param uid - The Firebase Auth user UID
 */
async function resetFailedAttempts(uid) {
    await admin.firestore().collection("users").doc(uid).update({
        failedLoginAttempts: 0,
        lockedUntil: null,
    });
}
/**
 * checkLockStatus
 *
 * Checks whether the account is currently locked (Requirement 4.5).
 *
 * @param uid - The Firebase Auth user UID
 * @returns LockStatus with isLocked, lockedUntil, and failedAttempts
 */
async function checkLockStatus(uid) {
    var _a, _b, _c;
    const doc = await admin.firestore().collection("users").doc(uid).get();
    if (!doc.exists) {
        return { isLocked: false, lockedUntil: null, failedAttempts: 0 };
    }
    const data = doc.data();
    const lockedUntil = (_b = (_a = data["lockedUntil"]) === null || _a === void 0 ? void 0 : _a.toDate()) !== null && _b !== void 0 ? _b : null;
    const isLocked = lockedUntil !== null && lockedUntil > new Date();
    return {
        isLocked,
        lockedUntil: isLocked ? lockedUntil : null,
        failedAttempts: (_c = data["failedLoginAttempts"]) !== null && _c !== void 0 ? _c : 0,
    };
}
//# sourceMappingURL=accountLockout.js.map