import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { verifyAdmin } from "../helpers/verifyAdmin";

/**
 * adminCreateMeal
 *
 * Creates a new meal document in /meals.
 * Requires the caller to have the 'admin' role.
 */
export const adminCreateMeal = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const data = request.data as {
    name: string;
    description?: string;
    price: number;
    categoryId: string;
    imageUrls?: string[];
    dietaryTags?: string[];
    nutritionalInfo?: Record<string, unknown>;
    isAvailable?: boolean;
    isFeatured?: boolean;
    featuredOrder?: number;
  };

  if (!data.name || typeof data.name !== "string") {
    throw new HttpsError("invalid-argument", "name is required.");
  }
  if (typeof data.price !== "number" || data.price < 0) {
    throw new HttpsError("invalid-argument", "price must be a non-negative number.");
  }
  if (!data.categoryId || typeof data.categoryId !== "string") {
    throw new HttpsError("invalid-argument", "categoryId is required.");
  }

  const db = admin.firestore();
  const mealRef = db.collection("meals").doc();

  await mealRef.set({
    ...data,
    isAvailable: data.isAvailable ?? true,
    isFeatured: data.isFeatured ?? false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, mealId: mealRef.id };
});

/**
 * adminUpdateMeal
 *
 * Updates an existing meal document in /meals.
 * Requires the caller to have the 'admin' role.
 */
export const adminUpdateMeal = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { mealId, ...updates } = request.data as {
    mealId: string;
    [key: string]: unknown;
  };

  if (!mealId || typeof mealId !== "string") {
    throw new HttpsError("invalid-argument", "mealId is required.");
  }

  const db = admin.firestore();
  const mealRef = db.doc(`meals/${mealId}`);
  const mealSnap = await mealRef.get();

  if (!mealSnap.exists) {
    throw new HttpsError("not-found", `Meal ${mealId} not found.`);
  }

  await mealRef.update({
    ...updates,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

/**
 * adminDeleteMeal
 *
 * Deletes a meal document from /meals.
 * Requires the caller to have the 'admin' role.
 */
export const adminDeleteMeal = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { mealId } = request.data as { mealId: string };

  if (!mealId || typeof mealId !== "string") {
    throw new HttpsError("invalid-argument", "mealId is required.");
  }

  const db = admin.firestore();
  const mealRef = db.doc(`meals/${mealId}`);
  const mealSnap = await mealRef.get();

  if (!mealSnap.exists) {
    throw new HttpsError("not-found", `Meal ${mealId} not found.`);
  }

  await mealRef.delete();

  return { success: true };
});
