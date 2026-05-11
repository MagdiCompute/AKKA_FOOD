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
exports.onUserCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions"));
/**
 * onUserCreated
 *
 * Triggered when a new Firebase Auth user is created (1st-gen auth trigger).
 * Initializes the /users/{uid} Firestore document with default values including:
 *   - coinBalance: 0
 *   - role: 'user'
 *   - isDeactivated: false
 *   - failedLoginAttempts: 0
 *   - lockedUntil: null
 */
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    var _a, _b, _c;
    await admin.firestore().collection("users").doc(user.uid).set({
        uid: user.uid,
        email: (_a = user.email) !== null && _a !== void 0 ? _a : null,
        phoneNumber: (_b = user.phoneNumber) !== null && _b !== void 0 ? _b : null,
        displayName: (_c = user.displayName) !== null && _c !== void 0 ? _c : "",
        isVerified: user.emailVerified,
        isDeactivated: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        linkedProviders: user.providerData.map((p) => p.providerId),
        failedLoginAttempts: 0,
        lockedUntil: null,
        coinBalance: 0,
        role: "user",
    });
});
//# sourceMappingURL=onUserCreated.js.map