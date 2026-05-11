import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

/**
 * onUserCreated
 *
 * Triggered when a new Firebase Auth user is created (1st-gen auth trigger).
 * Initializes the /users/{uid} Firestore document with default values including:
 *   - coinBalance: 0
 *   - role: 'user'
 *   - isDeactivated: false
 *   - failedLoginAttempts: 0
 *   - lockedUntil: null
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection("users").doc(user.uid).set({
    uid: user.uid,
    email: user.email ?? null,
    phoneNumber: user.phoneNumber ?? null,
    displayName: user.displayName ?? "",
    isVerified: user.emailVerified,
    isDeactivated: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    linkedProviders: user.providerData.map((p) => p.providerId),
    failedLoginAttempts: 0,
    lockedUntil: null,
    coinBalance: 0,
    role: "user",
  });
});
