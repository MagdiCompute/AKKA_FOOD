import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { verifyAdmin } from "../helpers/verifyAdmin";

type UserAction = "deactivate" | "reactivate";

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
export const adminManageUser = onCall(async (request) => {
  await verifyAdmin(request.auth);

  const { action, targetUid } = request.data as {
    action: UserAction;
    targetUid: string;
  };

  if (!action || (action !== "deactivate" && action !== "reactivate")) {
    throw new HttpsError(
      "invalid-argument",
      "action must be 'deactivate' or 'reactivate'."
    );
  }
  if (!targetUid || typeof targetUid !== "string") {
    throw new HttpsError("invalid-argument", "targetUid is required.");
  }

  const db = admin.firestore();
  const userRef = db.doc(`users/${targetUid}`);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    throw new HttpsError("not-found", `User ${targetUid} not found.`);
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
