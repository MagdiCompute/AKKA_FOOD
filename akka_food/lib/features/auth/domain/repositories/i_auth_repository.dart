import '../entities/app_user.dart';
import '../entities/auth_token.dart';
import '../entities/otp_request.dart';

/// Abstract repository interface for all authentication operations.
///
/// Pure Dart — zero Flutter or Firebase imports.
/// Implementations live in the data layer (`data/repositories/`).
abstract class IAuthRepository {
  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Creates a new account with [email], [password], and [displayName].
  ///
  /// On success returns the newly created [AppUser] (unverified) together with
  /// an initial [AuthToken] so the caller can navigate the app while
  /// verification is pending.
  ///
  /// Satisfies Requirement 1 (User Registration with Email and Password).
  Future<({AppUser user, AuthToken token})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Creates a new account with [phoneNumber], [password], and [displayName].
  ///
  /// On success returns the newly created [AppUser] (unverified) together with
  /// an initial [AuthToken] so the caller can navigate the app while
  /// verification is pending.
  ///
  /// Satisfies Requirement 2 (User Registration with Phone Number).
  Future<({AppUser user, AuthToken token})> signUpWithPhone({
    required String phoneNumber,
    required String password,
    required String displayName,
  });

  // ---------------------------------------------------------------------------
  // Sign-in
  // ---------------------------------------------------------------------------

  /// Authenticates an existing user with [email] and [password].
  ///
  /// Returns the authenticated [AppUser] and a fresh [AuthToken] pair.
  ///
  /// Satisfies Requirement 4 (Sign-In with Email and Password).
  Future<({AppUser user, AuthToken token})> signInWithEmail({
    required String email,
    required String password,
  });

  /// Authenticates an existing user with [phoneNumber] and [password].
  ///
  /// Returns the authenticated [AppUser] and a fresh [AuthToken] pair.
  ///
  /// Satisfies Requirement 5 (Sign-In with Phone Number and Password).
  Future<({AppUser user, AuthToken token})> signInWithPhone({
    required String phoneNumber,
    required String password,
  });

  /// Authenticates (or registers) a user via Google Sign-In.
  ///
  /// If the Google account is new to AKKA Food a verified account is created
  /// automatically. If the email already exists the social identity is linked
  /// to the existing account.
  ///
  /// Returns the [AppUser] and a fresh [AuthToken] pair.
  ///
  /// Satisfies Requirement 6, Criteria 1, 3, 4, 6 (Social Login — Google).
  Future<({AppUser user, AuthToken token})> signInWithGoogle();

  /// Authenticates (or registers) a user via Facebook Login.
  ///
  /// If the Facebook account is new to AKKA Food a verified account is created
  /// automatically. If the email already exists the social identity is linked
  /// to the existing account.
  ///
  /// Returns the [AppUser] and a fresh [AuthToken] pair.
  ///
  /// Satisfies Requirement 6, Criteria 2, 3, 4, 6 (Social Login — Facebook).
  Future<({AppUser user, AuthToken token})> signInWithFacebook();

  // ---------------------------------------------------------------------------
  // Phone OTP
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit OTP to [phoneNumber] via SMS and returns an [OtpRequest]
  /// that encapsulates the verification session.
  ///
  /// The returned [OtpRequest] must be passed back to [verifyPhoneOtp] to
  /// complete verification.
  ///
  /// Satisfies Requirement 2, Criteria 3 and Requirement 3, Criteria 5
  /// (OTP delivery and resend).
  Future<OtpRequest> sendPhoneOtp({required String phoneNumber});

  /// Verifies the [otp] code against the pending [otpRequest].
  ///
  /// On success marks the account as verified and returns the updated
  /// [AppUser] together with a verified [AuthToken].
  ///
  /// Satisfies Requirement 3, Criteria 1–4 (Account Verification).
  Future<({AppUser user, AuthToken token})> verifyPhoneOtp({
    required OtpRequest otpRequest,
    required String otp,
  });

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Exchanges a valid [refreshToken] for a new [AuthToken] (access token +
  /// rotated refresh token).
  ///
  /// The previous refresh token is invalidated after this call.
  ///
  /// Satisfies Requirement 7, Criteria 3 (Token Refresh and Rotation).
  Future<AuthToken> refreshToken({required String refreshToken});

  /// Signs the current user out.
  ///
  /// Invalidates the server-side refresh token and clears all locally stored
  /// tokens from the Token_Store.
  ///
  /// Satisfies Requirement 8 (Sign-Out).
  Future<void> signOut();

  /// Returns the currently authenticated [AppUser], or `null` when no valid
  /// session exists.
  ///
  /// Satisfies Requirement 7, Criteria 6 (Silent session restore on app
  /// launch).
  Future<AppUser?> getCurrentUser();

  // ---------------------------------------------------------------------------
  // Password management
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit password-reset OTP to [email].
  ///
  /// Always returns successfully even when [email] is not registered, to avoid
  /// leaking account existence.
  ///
  /// Satisfies Requirement 9, Criteria 1 and 3 (Forgot Password — email
  /// channel).
  Future<void> sendPasswordResetEmail({required String email});

  /// Sends a 6-digit password-reset OTP to [phoneNumber] via SMS.
  ///
  /// Always returns successfully even when [phoneNumber] is not registered, to
  /// avoid leaking account existence.
  ///
  /// Satisfies Requirement 9, Criteria 2 and 3 (Forgot Password — SMS
  /// channel).
  Future<void> sendPasswordResetSms({required String phoneNumber});

  /// Resets the account password using a valid [otp] from [otpRequest] and
  /// sets [newPassword] as the new credential.
  ///
  /// All existing refresh tokens for the account are invalidated. Returns the
  /// updated [AppUser] and a fresh [AuthToken] so the user is immediately
  /// signed in.
  ///
  /// Satisfies Requirement 9, Criteria 4–6 (Password Reset with OTP).
  Future<({AppUser user, AuthToken token})> resetPasswordWithOtp({
    required OtpRequest otpRequest,
    required String otp,
    required String newPassword,
  });

  /// Changes the password for the currently authenticated user.
  ///
  /// Requires the [currentPassword] for re-authentication before applying
  /// [newPassword]. All other active sessions are invalidated; the current
  /// session remains valid.
  ///
  /// Satisfies Requirement 10 (Change Password — Authenticated).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
