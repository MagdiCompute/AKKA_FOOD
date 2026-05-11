import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

/**
 * onCategoryDeactivated
 *
 * Triggered when a category document is updated in /categories/{categoryId}.
 * When `isActive` transitions from true → false, batch-sets `isAvailable=false`
 * on every meal that belongs to that category.
 *
 * Implements Requirement 10.3 / 11.3: deactivating a category hides all its meals.
 */
export const onCategoryDeactivated = onDocumentUpdated(
  "categories/{categoryId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    // Guard: missing snapshots
    if (!before || !after) return;

    // Only act when isActive changes from true → false
    if (before.isActive === after.isActive) return;
    if (after.isActive !== false) return;

    const categoryId = event.params.categoryId;
    const db = admin.firestore();

    // Fetch all meals belonging to this category
    const mealsQuery = await db
      .collection("meals")
      .where("categoryId", "==", categoryId)
      .get();

    if (mealsQuery.empty) return;

    // Firestore batches support up to 500 operations each
    const batches: admin.firestore.WriteBatch[] = [];
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

    console.log(
      `[onCategoryDeactivated] Set isAvailable=false on ${mealsQuery.size} meal(s) for category ${categoryId}.`
    );
  }
);
