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
exports.verifyAdmin = verifyAdmin;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
/**
 * Verifies that the caller of an HTTPS Callable Cloud Function is an admin.
 *
 * Steps:
 *  1. Ensures a Firebase Auth ID token was provided in the call context.
 *  2. Looks up the caller's Firestore document at /users/{uid}.
 *  3. Checks that `role == 'admin'`.
 *
 * Throws `HttpsError('permission-denied', 'Admins only')` if any check fails.
 *
 * @param auth - The `auth` object from a Firebase Functions v2 CallableRequest,
 *               or `undefined` / `null` when the caller is unauthenticated.
 */
async function verifyAdmin(auth) {
    // 1. Require authentication
    if (!auth || !auth.uid) {
        throw new https_1.HttpsError("unauthenticated", "The function must be called while authenticated.");
    }
    // 2. Look up the user document in Firestore
    const db = admin.firestore();
    const userDoc = await db.doc(`users/${auth.uid}`).get();
    if (!userDoc.exists) {
        throw new https_1.HttpsError("permission-denied", "Admins only");
    }
    // 3. Check the role field
    const data = userDoc.data();
    if (!data || data["role"] !== "admin") {
        throw new https_1.HttpsError("permission-denied", "Admins only");
    }
}
//# sourceMappingURL=verifyAdmin.js.map