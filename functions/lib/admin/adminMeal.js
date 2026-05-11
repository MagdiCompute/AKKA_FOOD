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
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminDeleteMeal = exports.adminUpdateMeal = exports.adminCreateMeal = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const verifyAdmin_1 = require("../helpers/verifyAdmin");
/**
 * adminCreateMeal
 *
 * Creates a new meal document in /meals.
 * Requires the caller to have the 'admin' role.
 */
exports.adminCreateMeal = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    await (0, verifyAdmin_1.verifyAdmin)(request.auth);
    const data = request.data;
    if (!data.name || typeof data.name !== "string") {
        throw new https_1.HttpsError("invalid-argument", "name is required.");
    }
    if (typeof data.price !== "number" || data.price < 0) {
        throw new https_1.HttpsError("invalid-argument", "price must be a non-negative number.");
    }
    if (!data.categoryId || typeof data.categoryId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "categoryId is required.");
    }
    const db = admin.firestore();
    const mealRef = db.collection("meals").doc();
    await mealRef.set(Object.assign(Object.assign({}, data), { isAvailable: (_a = data.isAvailable) !== null && _a !== void 0 ? _a : true, isFeatured: (_b = data.isFeatured) !== null && _b !== void 0 ? _b : false, createdAt: admin.firestore.FieldValue.serverTimestamp(), updatedAt: admin.firestore.FieldValue.serverTimestamp() }));
    return { success: true, mealId: mealRef.id };
});
/**
 * adminUpdateMeal
 *
 * Updates an existing meal document in /meals.
 * Requires the caller to have the 'admin' role.
 */
exports.adminUpdateMeal = (0, https_1.onCall)(async (request) => {
    await (0, verifyAdmin_1.verifyAdmin)(request.auth);
    const _a = request.data, { mealId } = _a, updates = __rest(_a, ["mealId"]);
    if (!mealId || typeof mealId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "mealId is required.");
    }
    const db = admin.firestore();
    const mealRef = db.doc(`meals/${mealId}`);
    const mealSnap = await mealRef.get();
    if (!mealSnap.exists) {
        throw new https_1.HttpsError("not-found", `Meal ${mealId} not found.`);
    }
    await mealRef.update(Object.assign(Object.assign({}, updates), { updatedAt: admin.firestore.FieldValue.serverTimestamp() }));
    return { success: true };
});
/**
 * adminDeleteMeal
 *
 * Deletes a meal document from /meals.
 * Requires the caller to have the 'admin' role.
 */
exports.adminDeleteMeal = (0, https_1.onCall)(async (request) => {
    await (0, verifyAdmin_1.verifyAdmin)(request.auth);
    const { mealId } = request.data;
    if (!mealId || typeof mealId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "mealId is required.");
    }
    const db = admin.firestore();
    const mealRef = db.doc(`meals/${mealId}`);
    const mealSnap = await mealRef.get();
    if (!mealSnap.exists) {
        throw new https_1.HttpsError("not-found", `Meal ${mealId} not found.`);
    }
    await mealRef.delete();
    return { success: true };
});
//# sourceMappingURL=adminMeal.js.map