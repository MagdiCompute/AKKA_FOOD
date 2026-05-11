import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * onUserDeleted
 *
 * Triggered when a Firebase Auth user is deleted (1st-gen auth trigger).
 * Anonymizes the /users/{uid} Firestore document to comply with data
 * retention and privacy requirements (Requirement 12.3).
 *
 * Fields anonymized:
 *   - email: null
 *   - phoneNumber: null
 *   - displayName: '[deleted]'
 *   - isDeactivated: true
 *   - deletedAt: server timestamp
 */
export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  await admin.firestore().collection("users").doc(user.uid).update({
    email: null,
    phoneNumber: null,
    displayName: "[deleted]",
    isDeactivated: true,
    linkedProviders: [],
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
