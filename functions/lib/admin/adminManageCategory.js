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
exports.adminManageCategory = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const verifyAdmin_1 = require("../helpers/verifyAdmin");
/**
 * adminManageCategory
 *
 * Creates, updates, activates, or deactivates a meal category.
 * On deactivation, batch-sets all meals in the category to isAvailable=false.
 * Requires the caller to have the 'admin' role.
 *
 * Request data:
 *   - action: 'create' | 'update' | 'deactivate' | 'activate'
 *   - categoryId?: string  (required for update/deactivate/activate)
 *   - name?: string        (required for create)
 *   - imageUrl?: string
 *   - isActive?: boolean
 */
exports.adminManageCategory = (0, https_1.onCall)(async (request) => {
    await (0, verifyAdmin_1.verifyAdmin)(request.auth);
    const { action, categoryId, name, imageUrl, isActive } = request.data;
    if (!action) {
        throw new https_1.HttpsError("invalid-argument", "action is required.");
    }
    const db = admin.firestore();
    if (action === "create") {
        if (!name || typeof name !== "string") {
            throw new https_1.HttpsError("invalid-argument", "name is required for create.");
        }
        // Check for duplicate name
        const existing = await db
            .collection("categories")
            .where("name", "==", name)
            .limit(1)
            .get();
        if (!existing.empty) {
            throw new https_1.HttpsError("already-exists", `A category with the name "${name}" already exists.`);
        }
        const catRef = db.collection("categories").doc();
        await catRef.set({
            name,
            imageUrl: imageUrl !== null && imageUrl !== void 0 ? imageUrl : null,
            isActive: isActive !== null && isActive !== void 0 ? isActive : true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true, categoryId: catRef.id };
    }
    // All other actions require categoryId
    if (!categoryId || typeof categoryId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "categoryId is required.");
    }
    const catRef = db.doc(`categories/${categoryId}`);
    const catSnap = await catRef.get();
    if (!catSnap.exists) {
        throw new https_1.HttpsError("not-found", `Category ${categoryId} not found.`);
    }
    if (action === "update") {
        const updates = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        // Check for duplicate name when name is being changed
        if (name !== undefined) {
            const existing = await db
                .collection("categories")
                .where("name", "==", name)
                .limit(1)
                .get();
            // Allow if the only match is the category being updated itself
            if (!existing.empty && existing.docs[0].id !== categoryId) {
                throw new https_1.HttpsError("already-exists", `A category with the name "${name}" already exists.`);
            }
            updates["name"] = name;
        }
        if (imageUrl !== undefined)
            updates["imageUrl"] = imageUrl;
        if (isActive !== undefined)
            updates["isActive"] = isActive;
        await catRef.update(updates);
        return { success: true };
    }
    if (action === "deactivate") {
        // Batch: deactivate category + set all its meals to unavailable
        const batch = db.batch();
        batch.update(catRef, {
            isActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const mealsSnap = await db
            .collection("meals")
            .where("category", "==", categoryId)
            .get();
        mealsSnap.docs.forEach((mealDoc) => {
            batch.update(mealDoc.ref, {
                isAvailable: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        await batch.commit();
        return { success: true };
    }
    if (action === "activate") {
        await catRef.update({
            isActive: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    throw new https_1.HttpsError("invalid-argument", `Unknown action: ${action}`);
});
//# sourceMappingURL=adminManageCategory.js.map