import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { verifyAdmin } from "../helpers/verifyAdmin";

type CategoryAction = "create" | "update" | "deactivate" | "activate";

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
export const adminManageCategory = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { action, categoryId, name, imageUrl, isActive } = request.data as {
    action: CategoryAction;
    categoryId?: string;
    name?: string;
    imageUrl?: string;
    isActive?: boolean;
  };

  if (!action) {
    throw new HttpsError("invalid-argument", "action is required.");
  }

  const db = admin.firestore();

  if (action === "create") {
    if (!name || typeof name !== "string") {
      throw new HttpsError("invalid-argument", "name is required for create.");
    }

    // Check for duplicate name
    const existing = await db
      .collection("categories")
      .where("name", "==", name)
      .limit(1)
      .get();

    if (!existing.empty) {
      throw new HttpsError(
        "already-exists",
        `A category with the name "${name}" already exists.`
      );
    }

    const catRef = db.collection("categories").doc();
    await catRef.set({
      name,
      imageUrl: imageUrl ?? null,
      isActive: isActive ?? true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, categoryId: catRef.id };
  }

  // All other actions require categoryId
  if (!categoryId || typeof categoryId !== "string") {
    throw new HttpsError("invalid-argument", "categoryId is required.");
  }

  const catRef = db.doc(`categories/${categoryId}`);
  const catSnap = await catRef.get();

  if (!catSnap.exists) {
    throw new HttpsError("not-found", `Category ${categoryId} not found.`);
  }

  if (action === "update") {
    const updates: Record<string, unknown> = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (name !== undefined) updates["name"] = name;
    if (imageUrl !== undefined) updates["imageUrl"] = imageUrl;
    if (isActive !== undefined) updates["isActive"] = isActive;

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
      .where("categoryId", "==", categoryId)
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

  throw new HttpsError("invalid-argument", `Unknown action: ${action}`);
});
