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
exports.adminManageUser = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const verifyAdmin_1 = require("../helpers/verifyAdmin");
/**
 * adminManageUser
 *
 * Deactivates or reactivates a user account.
 * On deactivation: sets isDeactivated=true in Firestore and disables the Firebase Auth account.
 * On reactivation: sets isDeactivated=false in Firestore and re-enables the Firebase Auth account.
 * Requires the caller to have the 'admin' role.
 *
 * Request data:
 *   - action: 'deactivate' | 'reactivate'
 *   - targetUid: string
 */
exports.adminManageUser = (0, https_1.onCall)(async (request) => {
    await (0, verifyAdmin_1.verifyAdmin)(request.auth);
    const { action, targetUid } = request.data;
    if (!action || (action !== "deactivate" && action !== "reactivate")) {
        throw new https_1.HttpsError("invalid-argument", "action must be 'deactivate' or 'reactivate'.");
    }
    if (!targetUid || typeof targetUid !== "string") {
        throw new https_1.HttpsError("invalid-argument", "targetUid is required.");
    }
    const db = admin.firestore();
    const userRef = db.doc(`users/${targetUid}`);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
        throw new https_1.HttpsError("not-found", `User ${targetUid} not found.`);
    }
    const disabled = action === "deactivate";
    // Update Firebase Auth
    await admin.auth().updateUser(targetUid, { disabled });
    // Update Firestore
    await userRef.update({
        isDeactivated: disabled,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true };
});
//# sourceMappingURL=adminManageUser.js.map