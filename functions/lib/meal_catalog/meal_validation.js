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
exports.onNutritionalInfoValidationUpdated = exports.onNutritionalInfoValidationCreated = exports.onMealWriteValidationUpdated = exports.onMealWriteValidationCreated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
/**
 * Mark a meal as unavailable and attach a validation error message.
 */
async function invalidateMeal(ref, errorMessage) {
    await ref.update({
        isAvailable: false,
        _validationError: errorMessage,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
// ---------------------------------------------------------------------------
// Task 8.2 — Price > 0 and unique name validation
// ---------------------------------------------------------------------------
/**
 * onMealWriteValidation
 *
 * Triggered on meal create and update.
 * Validates:
 *   1. price > 0  (Requirement 11.1)
 *   2. name is unique across the catalog  (Requirement 11.4)
 *
 * On violation: sets isAvailable=false and records _validationError.
 */
exports.onMealWriteValidationCreated = (0, firestore_1.onDocumentCreated)("meals/{mealId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    await validateMeal(snap.ref, snap.data(), event.params.mealId);
});
exports.onMealWriteValidationUpdated = (0, firestore_1.onDocumentUpdated)("meals/{mealId}", async (event) => {
    var _a;
    const afterSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after;
    if (!afterSnap)
        return;
    await validateMeal(afterSnap.ref, afterSnap.data(), event.params.mealId);
});
async function validateMeal(ref, data, mealId) {
    var _a;
    // 1. Price validation
    const price = data["price"];
    if (typeof price !== "number" || price <= 0) {
        console.error(`[onMealWriteValidation] Meal ${mealId} has invalid price: ${price}`);
        await invalidateMeal(ref, `Invalid price: price must be a positive number greater than 0 XOF (got ${price}).`);
        return;
    }
    // 2. Name uniqueness validation
    const name = data["name"];
    if (typeof name === "string" && name.trim().length > 0) {
        const db = admin.firestore();
        const duplicates = await db
            .collection("meals")
            .where("name", "==", name.trim())
            .get();
        // Filter out the current document itself
        const others = duplicates.docs.filter((d) => d.id !== mealId);
        if (others.length > 0) {
            console.error(`[onMealWriteValidation] Meal ${mealId} has duplicate name: "${name}"`);
            await invalidateMeal(ref, `Duplicate meal name: a meal named "${name}" already exists. Meal names must be unique.`);
            return;
        }
    }
    // All validations passed — clear any previous validation error if present
    const currentData = (_a = (await ref.get()).data()) !== null && _a !== void 0 ? _a : {};
    if (currentData["_validationError"]) {
        await ref.update({
            _validationError: admin.firestore.FieldValue.delete(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
}
// ---------------------------------------------------------------------------
// Task 8.3 — Nutritional info non-negative validation
// ---------------------------------------------------------------------------
/**
 * onNutritionalInfoValidation
 *
 * Triggered on meal create and update.
 * If `nutritionalInfo` is present, validates that calories, proteins,
 * carbohydrates, and fats are all >= 0.  (Requirement 9.8 / 11)
 *
 * On violation: sets isAvailable=false and records _validationError.
 */
exports.onNutritionalInfoValidationCreated = (0, firestore_1.onDocumentCreated)("meals/{mealId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    await validateNutritionalInfo(snap.ref, snap.data(), event.params.mealId);
});
exports.onNutritionalInfoValidationUpdated = (0, firestore_1.onDocumentUpdated)("meals/{mealId}", async (event) => {
    var _a;
    const afterSnap = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after;
    if (!afterSnap)
        return;
    await validateNutritionalInfo(afterSnap.ref, afterSnap.data(), event.params.mealId);
});
async function validateNutritionalInfo(ref, data, mealId) {
    const nutritionalInfo = data["nutritionalInfo"];
    // Skip validation when nutritionalInfo is absent
    if (!nutritionalInfo || typeof nutritionalInfo !== "object")
        return;
    const info = nutritionalInfo;
    const fields = [
        "calories",
        "proteins",
        "carbohydrates",
        "fats",
    ];
    for (const field of fields) {
        const value = info[field];
        if (typeof value !== "number" || value < 0) {
            console.error(`[onNutritionalInfoValidation] Meal ${mealId} has invalid nutritionalInfo.${field}: ${value}`);
            await invalidateMeal(ref, `Invalid nutritional info: "${field}" must be a non-negative number (got ${value}).`);
            return;
        }
    }
}
//# sourceMappingURL=meal_validation.js.map