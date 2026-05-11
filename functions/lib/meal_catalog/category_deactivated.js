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
exports.onCategoryDeactivated = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
/**
 * onCategoryDeactivated
 *
 * Triggered when a category document is updated in /categories/{categoryId}.
 * When `isActive` transitions from true → false, batch-sets `isAvailable=false`
 * on every meal that belongs to that category.
 *
 * Implements Requirement 10.3 / 11.3: deactivating a category hides all its meals.
 */
exports.onCategoryDeactivated = (0, firestore_1.onDocumentUpdated)("categories/{categoryId}", async (event) => {
    var _a, _b;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    // Guard: missing snapshots
    if (!before || !after)
        return;
    // Only act when isActive changes from true → false
    if (before.isActive === after.isActive)
        return;
    if (after.isActive !== false)
        return;
    const categoryId = event.params.categoryId;
    const db = admin.firestore();
    // Fetch all meals belonging to this category
    const mealsQuery = await db
        .collection("meals")
        .where("categoryId", "==", categoryId)
        .get();
    if (mealsQuery.empty)
        return;
    // Firestore batches support up to 500 operations each
    const batches = [];
    let currentBatch = db.batch();
    let operationCount = 0;
    for (const doc of mealsQuery.docs) {
        if (operationCount === 500) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            operationCount = 0;
        }
        currentBatch.update(doc.ref, {
            isAvailable: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        operationCount++;
    }
    batches.push(currentBatch);
    await Promise.all(batches.map((b) => b.commit()));
    console.log(`[onCategoryDeactivated] Set isAvailable=false on ${mealsQuery.size} meal(s) for category ${categoryId}.`);
});
//# sourceMappingURL=category_deactivated.js.map