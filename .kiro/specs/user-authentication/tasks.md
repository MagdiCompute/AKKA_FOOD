# Tasks — User Authentication

## Task List

- [x] 1. Project setup and dependencies
  - [x] 1.1 Initialize Flutter project `akka_food` with null safety
  - [x] 1.2 Add dependencies: `firebase_core`, `firebase_auth`, `cloud_firestore`, `flutter_secure_storage`, `google_sign_in`, `flutter_facebook_auth`, `riverpod`, `go_router`, `freezed`, `json_serializable`
  - [x] 1.3 Configure Firebase project (Android `google-services.json`, iOS `GoogleService-Info.plist`)
  - [x] 1.4 Set up project folder structure: `lib/features/auth/`, `lib/core/`, `lib/shared/`

- [ ] 2. Domain layer — Auth entities and interfaces
  - [ ] 2.1 Create `AppUser` entity with `uid`, `email`, `phoneNumber`, `displayName`, `isVerified`, `isDeactivated`, `linkedProviders`
  - [ ] 2.2 Create `AuthToken` entity with `accessToken`, `refreshToken`, `expiresAt`
  - [ ] 2.3 Create `OtpRequest` entity
  - [ ] 2.4 Define `IAuthRepository` interface with all auth method signatures

- [ ] 3. Data layer — TokenStore
  - [ ] 3.1 Implement `TokenStore` using `flutter_secure_storage` with Android Keystore / iOS Keychain options
  - [ ] 3.2 Implement `save`, `load`, `clear`, `isValid` methods
  - [ ] 3.3 Write unit tests for TokenStore

- [ ] 4. Data layer — AuthRepository
  - [ ] 4.1 Implement `FirebaseAuthDataSource` wrapping Firebase Auth SDK
  - [ ] 4.2 Implement email/password sign-up calling `createUserWithEmailAndPassword`
  - [ ] 4.3 Implement email/password sign-in calling `signInWithEmailAndPassword`
  - [ ] 4.4 Implement phone OTP flow using `verifyPhoneNumber` + `PhoneAuthCredential`
  - [ ] 4.5 Implement Google sign-in using `GoogleSignIn` + `GoogleAuthProvider`
  - [ ] 4.6 Implement Facebook sign-in using `FacebookAuth` + `FacebookAuthProvider`
  - [ ] 4.7 Implement sign-out (Firebase + TokenStore clear)
  - [ ] 4.8 Implement password reset via `sendPasswordResetEmail`
  - [ ] 4.9 Implement `AuthRepository` composing `FirebaseAuthDataSource` and `TokenStore`
  - [ ] 4.10 Write unit tests for AuthRepository (mock Firebase)

- [ ] 5. Cloud Functions — Account lifecycle
  - [ ] 5.1 Create `onUserCreated` Cloud Function: initialize `/users/{uid}` Firestore document with `coinBalance: 0`, `role: 'user'`, `isDeactivated: false`
  - [ ] 5.2 Create `onUserDeleted` Cloud Function: anonymize `/users/{uid}` profile data
  - [ ] 5.3 Implement account lockout logic in Firestore: track `failedLoginAttempts` and `lockedUntil`
  - [ ] 5.4 Create `checkAccountLock` Cloud Function called before sign-in

- [ ] 6. State management — AuthNotifier
  - [ ] 6.1 Implement `AuthNotifier` (Riverpod `AsyncNotifier<AuthState>`) with all auth methods
  - [ ] 6.2 Implement silent session restore on app launch (check TokenStore → refresh Firebase token)
  - [ ] 6.3 Implement `AuthState` with `status`, `user`, `errorMessage`
  - [ ] 6.4 Map Firebase error codes to user-friendly messages
  - [ ] 6.5 Write unit tests for AuthNotifier

- [ ] 7. Presentation layer — Auth screens
  - [ ] 7.1 Implement `LoginScreen` with email/password fields, Google button, Facebook button, "Forgot password" link
  - [ ] 7.2 Implement `SignUpScreen` with name, email/phone, password fields and validation
  - [ ] 7.3 Implement `OtpVerificationScreen` with 6-digit OTP input, resend button, countdown timer
  - [ ] 7.4 Implement `ForgotPasswordScreen` with email/phone input
  - [ ] 7.5 Implement `ChangePasswordScreen` (authenticated) with current + new password fields
  - [ ] 7.6 Add form validation (password complexity, E.164 phone format, email format)

- [ ] 8. Navigation and route guards
  - [ ] 8.1 Configure GoRouter with `/login`, `/signup`, `/otp`, `/forgot-password`, `/home` routes
  - [ ] 8.2 Implement route guard: redirect unauthenticated users to `/login`
  - [ ] 8.3 Implement redirect: authenticated users skip auth screens

- [ ] 9. Security hardening
  - [ ] 9.1 Configure certificate pinning for Firebase API calls
  - [ ] 9.2 Set Firestore Security Rules: `/users/{uid}` readable/writable only by matching `request.auth.uid`
  - [ ] 9.3 Verify OTP rate limiting (5 per hour) in Cloud Function

- [ ] 10. Integration testing
  - [ ] 10.1 Write integration test: full sign-up → OTP verify → sign-in flow
  - [ ] 10.2 Write integration test: Google sign-in flow
  - [ ] 10.3 Write integration test: forgot password → OTP → reset flow
  - [ ] 10.4 Write integration test: account lockout after 5 failed attempts
