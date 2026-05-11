import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Mark a meal as unavailable and attach a validation error message.
 */
async function invalidateMeal(
  ref: admin.firestore.DocumentReference,
  errorMessage: string
): Promise<void> {
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
export const onMealWriteValidationCreated = onDocumentCreated(
  "meals/{mealId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    await validateMeal(snap.ref, snap.data() as Record<string, unknown>, event.params.mealId);
  }
);

export const onMealWriteValidationUpdated = onDocumentUpdated(
  "meals/{mealId}",
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap) return;
    await validateMeal(
      afterSnap.ref,
      afterSnap.data() as Record<string, unknown>,
      event.params.mealId
    );
  }
);

async function validateMeal(
  ref: admin.firestore.DocumentReference,
  data: Record<string, unknown>,
  mealId: string
): Promise<void> {
  // 1. Price validation
  const price = data["price"];
  if (typeof price !== "number" || price <= 0) {
    console.error(
      `[onMealWriteValidation] Meal ${mealId} has invalid price: ${price}`
    );
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
      console.error(
        `[onMealWriteValidation] Meal ${mealId} has duplicate name: "${name}"`
      );
      await invalidateMeal(
        ref,
        `Duplicate meal name: a meal named "${name}" already exists. Meal names must be unique.`
      );
      return;
    }
  }

  // All validations passed — clear any previous validation error if present
  const currentData = (await ref.get()).data() ?? {};
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
export const onNutritionalInfoValidationCreated = onDocumentCreated(
  "meals/{mealId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    await validateNutritionalInfo(
      snap.ref,
      snap.data() as Record<string, unknown>,
      event.params.mealId
    );
  }
);

export const onNutritionalInfoValidationUpdated = onDocumentUpdated(
  "meals/{mealId}",
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap) return;
    await validateNutritionalInfo(
      afterSnap.ref,
      afterSnap.data() as Record<string, unknown>,
      event.params.mealId
    );
  }
);

async function validateNutritionalInfo(
  ref: admin.firestore.DocumentReference,
  data: Record<string, unknown>,
  mealId: string
): Promise<void> {
  const nutritionalInfo = data["nutritionalInfo"];

  // Skip validation when nutritionalInfo is absent
  if (!nutritionalInfo || typeof nutritionalInfo !== "object") return;

  const info = nutritionalInfo as Record<string, unknown>;
  const fields: Array<keyof typeof info> = [
    "calories",
    "proteins",
    "carbohydrates",
    "fats",
  ];

  for (const field of fields) {
    const value = info[field];
    if (typeof value !== "number" || value < 0) {
      console.error(
        `[onNutritionalInfoValidation] Meal ${mealId} has invalid nutritionalInfo.${field}: ${value}`
      );
      await invalidateMeal(
        ref,
        `Invalid nutritional info: "${field}" must be a non-negative number (got ${value}).`
      );
      return;
    }
  }
}
