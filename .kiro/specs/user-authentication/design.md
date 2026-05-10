# Design Document — User Authentication

## Overview

The User Authentication feature follows a clean architecture with three layers: **Presentation**, **Domain**, and **Data**. Firebase Authentication handles identity management, with Firestore storing extended user metadata. Flutter Secure Storage persists tokens on-device using the platform's hardware-backed keystore.

---

## Architecture

```
Presentation Layer
  └── Screens: LoginScreen, SignUpScreen, OtpVerificationScreen, ForgotPasswordScreen, ChangePasswordScreen
  └── State: AuthNotifier (Riverpod AsyncNotifier)

Domain Layer
  └── Entities: AppUser, AuthToken, OtpRequest
  └── Use Cases: SignInUseCase, SignUpUseCase, VerifyOtpUseCase, SignOutUseCase, ResetPasswordUseCase, ChangePasswordUseCase, RefreshTokenUseCase
  └── Repository Interface: IAuthRepository

Data Layer
  └── AuthRepository (implements IAuthRepository)
  └── FirebaseAuthDataSource
  └── TokenStore (flutter_secure_storage wrapper)
  └── ProfileServiceClient (emits account-created events to Firestore)
```

---

## Data Models

### AppUser
```dart
class AppUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String displayName;
  final bool isVerified;
  final bool isDeactivated;
  final DateTime createdAt;
  final List<String> linkedProviders; // ['password', 'google.com', 'facebook.com']
}
```

### AuthToken
```dart
class AuthToken {
  final String accessToken;   // Firebase ID token (1 hour expiry)
  final String refreshToken;  // Firebase refresh token (long-lived)
  final DateTime expiresAt;
}
```

### OtpRequest
```dart
class OtpRequest {
  final String verificationId; // Firebase phone auth verification ID
  final String channel;        // 'email' | 'sms'
  final DateTime issuedAt;
  final int attemptCount;
}
```

---

## Firebase Integration

### Authentication Providers
- **Email/Password**: `FirebaseAuth.createUserWithEmailAndPassword` / `signInWithEmailAndPassword`
- **Phone/OTP**: `FirebaseAuth.verifyPhoneNumber` → `PhoneAuthCredential`
- **Google**: `GoogleSignIn().signIn()` → `GoogleAuthProvider.credential`
- **Facebook**: `FacebookAuth.login()` → `FacebookAuthProvider.credential`

### Firestore Collections
```
/users/{uid}
  - uid: string
  - email: string?
  - phoneNumber: string?
  - displayName: string
  - isVerified: bool
  - isDeactivated: bool
  - createdAt: timestamp
  - linkedProviders: string[]
  - failedLoginAttempts: number
  - lockedUntil: timestamp?
  - coinBalance: number (initialized to 0)
```

### Cloud Functions
- `onUserCreated`: Triggered on Firebase Auth user creation → initializes Firestore `/users/{uid}` document with coinBalance: 0
- `onUserDeleted`: Triggered on Firebase Auth user deletion → anonymizes Firestore user data

---

## Token Storage

```dart
// TokenStore wraps flutter_secure_storage
class TokenStore {
  static const _accessTokenKey = 'akka_access_token';
  static const _refreshTokenKey = 'akka_refresh_token';
  static const _expiresAtKey = 'akka_token_expires_at';

  Future<void> save(AuthToken token);
  Future<AuthToken?> load();
  Future<void> clear();
  Future<bool> isValid(); // checks expiry
}
```

Storage backend: `AndroidOptions(encryptedSharedPreferences: true)` on Android, Keychain on iOS. Never uses plain SharedPreferences.

---

## State Management (Riverpod)

```dart
// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, unverified, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
}

// Notifier
class AuthNotifier extends AsyncNotifier<AuthState> {
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, String displayName);
  Future<void> signInWithGoogle();
  Future<void> signInWithFacebook();
  Future<void> signInWithPhone(String phoneNumber);
  Future<void> verifyOtp(String otp);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> changePassword(String current, String newPassword);
}
```

---

## Navigation Flow

```
App Launch
  ├── Valid token found → HomeScreen
  └── No token → LoginScreen
        ├── Sign Up → SignUpScreen → OtpVerificationScreen → HomeScreen
        ├── Forgot Password → ForgotPasswordScreen → OtpVerificationScreen → LoginScreen
        ├── Google/Facebook → HomeScreen (or OtpVerificationScreen if new)
        └── Sign In success → HomeScreen
```

GoRouter guards check `AuthState` on every route change. Unauthenticated users are redirected to `/login`.

---

## Account Lockout

Implemented in Firestore + Cloud Function:
- On failed sign-in: increment `failedLoginAttempts` in `/users/{uid}`
- At 5 failures within 15 min: set `lockedUntil = now + 15min`
- On sign-in attempt: Cloud Function checks `lockedUntil` before issuing token

---

## Security Design

| Concern | Approach |
|---|---|
| Password hashing | Firebase Auth handles bcrypt internally |
| Token storage | flutter_secure_storage (AES-256, hardware-backed) |
| Transport security | HTTPS enforced by Firebase; certificate pinning via `http_certificate_pinning` package |
| OTP rate limiting | Cloud Function: max 5 OTP requests/hour per identifier |
| Replay attack | Firebase refresh token rotation; old tokens invalidated on use |
| PII in logs | Cloud Functions log only UIDs, never passwords or tokens |

---

## Error Handling

All auth errors are mapped to user-friendly messages in the presentation layer:

| Firebase Error Code | User Message |
|---|---|
| `email-already-in-use` | "This email is already registered." |
| `wrong-password` | "Incorrect credentials." |
| `user-not-found` | "Incorrect credentials." (generic) |
| `too-many-requests` | "Account locked. Try again in 15 minutes." |
| `invalid-verification-code` | "Invalid OTP. Please try again." |
| `network-request-failed` | "No internet connection." |

---

## Integration with Profile Service

On successful account creation, `AuthRepository` writes the initial user document to Firestore `/users/{uid}` with `coinBalance: 0`. The `onUserCreated` Cloud Function also notifies the Profile_Service to initialize delivery addresses and notification preferences.

On account deletion, `onUserDeleted` Cloud Function emits a deletion event consumed by Profile_Service, Order_Service, and Coin_Service.
