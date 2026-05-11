# Tasks — User Authentication

## Task List

- [x] 1. Project setup and dependencies
  - [x] 1.1 Initialize Flutter project `akka_food` with null safety
  - [x] 1.2 Add dependencies: `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_secure_storage`, `google_sign_in`, `flutter_facebook_auth`, `riverpod`, `go_router`, `freezed`, `json_serializable`
  - [x] 1.3 Configure Firebase project (Android `google-services.json`, iOS `GoogleService-Info.plist`)
  - [x] 1.4 Set up project folder structure: `lib/features/auth/`, `lib/core/`, `lib/shared/`

- [x] 2. Domain layer — Auth entities and interfaces
  - [x] 2.1 Create `AppUser` entity with `uid`, `email`, `phoneNumber`, `displayName`, `isVerified`, `isDeactivated`, `linkedProviders`
  - [x] 2.2 Create `AuthToken` entity with `accessToken`, `refreshToken`, `expiresAt`
  - [x] 2.3 Create `OtpRequest` entity
  - [x] 2.4 Define `IAuthRepository` interface with all auth method signatures

- [x] 3. Data layer — TokenStore
  - [x] 3.1 Implement `TokenStore` using `flutter_secure_storage` with Android Keystore / iOS Keychain options
  - [x] 3.2 Implement `save`, `load`, `clear`, `isValid` methods
  - [x] 3.3 Write unit tests for TokenStore

- [x] 4. Data layer — AuthRepository
  - [x] 4.1 Implement `FirebaseAuthDataSource` wrapping Firebase Auth SDK
  - [x] 4.2 Implement email/password sign-up calling `createUserWithEmailAndPassword`
  - [x] 4.3 Implement email/password sign-in calling `signInWithEmailAndPassword`
  - [x] 4.4 Implement phone OTP flow using `verifyPhoneNumber` + `PhoneAuthCredential`
  - [x] 4.5 Implement Google sign-in using `GoogleSignIn` + `GoogleAuthProvider`
  - [x] 4.6 Implement Facebook sign-in using `FacebookAuth` + `FacebookAuthProvider`
  - [x] 4.7 Implement sign-out (Firebase + TokenStore clear)
  - [x] 4.8 Implement password reset via `sendPasswordResetEmail`
  - [x] 4.9 Implement `AuthRepository` composing `FirebaseAuthDataSource` and `TokenStore`
  - [x] 4.10 Write unit tests for AuthRepository (mock Firebase)

- [x] 5. Cloud Functions — Account lifecycle
  - [x] 5.1 Create `onUserCreated` Cloud Function: initialize `/users/{uid}` Firestore document with `coinBalance: 0`, `role: 'user'`, `isDeactivated: false`
  - [x] 5.2 Create `onUserDeleted` Cloud Function: anonymize `/users/{uid}` profile data
  - [x] 5.3 Implement account lockout logic in Firestore: track `failedLoginAttempts` and `lockedUntil`
  - [x] 5.4 Create `checkAccountLock` Cloud Function called before sign-in

- [x] 6. State management — AuthNotifier
  - [x] 6.1 Implement `AuthNotifier` (Riverpod `AsyncNotifier<AuthState>`) with all auth methods
  - [x] 6.2 Implement silent session restore on app launch (check TokenStore → refresh Firebase token)
  - [x] 6.3 Implement `AuthState` with `status`, `user`, `errorMessage`
  - [x] 6.4 Map Firebase error codes to user-friendly messages
  - [x] 6.5 Write unit tests for AuthNotifier

- [x] 7. Presentation layer — Auth screens
  - [x] 7.1 Implement `LoginScreen` with email/password fields, Google button, Facebook button, "Forgot password" link
  - [x] 7.2 Implement `SignUpScreen` with name, email/phone, password fields and validation
  - [x] 7.3 Implement `OtpVerificationScreen` with 6-digit OTP input, resend button, countdown timer
  - [x] 7.4 Implement `ForgotPasswordScreen` with email/phone input
  - [x] 7.5 Implement `ChangePasswordScreen` (authenticated) with current + new password fields
  - [x] 7.6 Add form validation (password complexity, E.164 phone format, email format)

- [x] 8. Navigation and route guards
  - [x] 8.1 Configure GoRouter with `/login`, `/signup`, `/otp`, `/forgot-password`, `/home` routes
  - [x] 8.2 Implement route guard: redirect unauthenticated users to `/login`
  - [x] 8.3 Implement redirect: authenticated users skip auth screens

- [x] 9. Security hardening
  - [x] 9.1 Configure certificate pinning for Firebase API calls
  - [x] 9.2 Set Firestore Security Rules: `/users/{uid}` readable/writable only by matching `request.auth.uid`
  - [x] 9.3 Verify OTP rate limiting (5 per hour) in Cloud Function

- [x] 10. Integration testing
  - [x] 10.1 Write integration test: full sign-up → OTP verify → sign-in flow
  - [x] 10.2 Write integration test: Google sign-in flow
  - [x] 10.3 Write integration test: forgot password → OTP → reset flow
  - [x] 10.4 Write integration test: account lockout after 5 failed attempts
