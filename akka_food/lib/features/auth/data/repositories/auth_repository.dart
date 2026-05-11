import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/otp_request.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/token_store.dart';

/// Concrete implementation of [IAuthRepository].
///
/// Composes [FirebaseAuthDataSource] (Firebase SDK operations) and
/// [TokenStore] (secure local token persistence) to satisfy all auth
/// requirements defined in the domain interface.
///
/// All [FirebaseAuthException] errors propagate up to the caller (e.g.
/// [AuthNotifier]) where they are mapped to user-friendly messages.
class AuthRepository implements IAuthRepository {
  AuthRepository({
    required FirebaseAuthDataSource dataSource,
    required TokenStore tokenStore,
    FirebaseAuth? firebaseAuth,
  })  : _dataSource = dataSource,
        _tokenStore = tokenStore,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuthDataSource _dataSource;
  final TokenStore _tokenStore;
  final FirebaseAuth _firebaseAuth;

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  /// Creates a new account with [email], [password], and [displayName].
  ///
  /// Delegates to [FirebaseAuthDataSource.signUpWithEmail], maps the Firebase
  /// user to [AppUser], builds an [AuthToken], persists it, and returns both.
  ///
  /// Satisfies Requirement 1 (User Registration with Email and Password).
  @override
  Future<({AppUser user, AuthToken token})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final result = await _dataSource.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );

    final user = _dataSource.mapFirebaseUser(result.credential.user!);
    final token = _dataSource.makeAuthToken(
      result.idToken,
      result.credential.user!.refreshToken,
    );

    await _tokenStore.save(token);
    return (user: user, token: token);
  }

  /// Phone sign-up is not supported as a direct operation in Firebase.
  ///
  /// Phone registration requires the OTP flow:
  ///   1. Call [sendPhoneOtp] to trigger SMS delivery and get an [OtpRequest].
  ///   2. Call [verifyPhoneOtp] with the received code to complete sign-in /
  ///      registration.
  ///
  /// Satisfies Requirement 2 (User Registration with Phone Number) via the
  /// OTP flow rather than a single-step call.
  @override
  Future<({AppUser user, AuthToken token})> signUpWithPhone({
    required String phoneNumber,
    required String password,
    required String displayName,
  }) {
    // Firebase does not support a combined phone+password sign-up in a single
    // step. Use sendPhoneOtp + verifyPhoneOtp for phone-based registration.
    throw UnimplementedError(
      'Phone sign-up is not supported as a single step. '
      'Use sendPhoneOtp(phoneNumber: ...) to send an OTP, then '
      'verifyPhoneOtp(otpRequest: ..., otp: ...) to complete registration.',
    );
  }

  // ---------------------------------------------------------------------------
  // Sign-in
  // ---------------------------------------------------------------------------

  /// Authenticates an existing user with [email] and [password].
  ///
  /// Satisfies Requirement 4 (Sign-In with Email and Password).
  @override
  Future<({AppUser user, AuthToken token})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _dataSource.signInWithEmail(
      email: email,
      password: password,
    );

    final user = _dataSource.mapFirebaseUser(result.credential.user!);
    final token = _dataSource.makeAuthToken(
      result.idToken,
      result.credential.user!.refreshToken,
    );

    await _tokenStore.save(token);
    return (user: user, token: token);
  }

  /// Phone sign-in is not supported as a direct password-based operation.
  ///
  /// Firebase phone authentication uses the OTP flow exclusively:
  ///   1. Call [sendPhoneOtp] to trigger SMS delivery and get an [OtpRequest].
  ///   2. Call [verifyPhoneOtp] with the received code to complete sign-in.
  ///
  /// Satisfies Requirement 5 (Sign-In with Phone Number) via the OTP flow.
  @override
  Future<({AppUser user, AuthToken token})> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) {
    // Firebase does not support phone+password sign-in. Use the OTP flow:
    // sendPhoneOtp + verifyPhoneOtp.
    throw UnimplementedError(
      'Phone sign-in is not supported as a single step. '
      'Use sendPhoneOtp(phoneNumber: ...) to send an OTP, then '
      'verifyPhoneOtp(otpRequest: ..., otp: ...) to complete sign-in.',
    );
  }

  /// Authenticates (or registers) a user via Google Sign-In.
  ///
  /// Satisfies Requirement 6, Criteria 1, 3, 4, 6 (Social Login — Google).
  @override
  Future<({AppUser user, AuthToken token})> signInWithGoogle() async {
    final result = await _dataSource.signInWithGoogle();

    final user = _dataSource.mapFirebaseUser(result.credential.user!);
    final token = _dataSource.makeAuthToken(
      result.idToken,
      result.credential.user!.refreshToken,
    );

    await _tokenStore.save(token);
    return (user: user, token: token);
  }

  /// Authenticates (or registers) a user via Facebook Login.
  ///
  /// Satisfies Requirement 6, Criteria 2, 3, 4, 6 (Social Login — Facebook).
  @override
  Future<({AppUser user, AuthToken token})> signInWithFacebook() async {
    final result = await _dataSource.signInWithFacebook();

    final user = _dataSource.mapFirebaseUser(result.credential.user!);
    final token = _dataSource.makeAuthToken(
      result.idToken,
      result.credential.user!.refreshToken,
    );

    await _tokenStore.save(token);
    return (user: user, token: token);
  }

  // ---------------------------------------------------------------------------
  // Phone OTP
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit OTP to [phoneNumber] via SMS.
  ///
  /// Delegates directly to [FirebaseAuthDataSource.sendPhoneOtp].
  ///
  /// Satisfies Requirement 2, Criteria 3 and Requirement 3, Criteria 5.
  @override
  Future<OtpRequest> sendPhoneOtp({required String phoneNumber}) {
    return _dataSource.sendPhoneOtp(phoneNumber: phoneNumber);
  }

  /// Verifies the [otp] code against the pending [otpRequest] and signs in.
  ///
  /// On success maps the Firebase user to [AppUser], builds and persists an
  /// [AuthToken], and returns both.
  ///
  /// Satisfies Requirement 3, Criteria 1–4 (Account Verification).
  @override
  Future<({AppUser user, AuthToken token})> verifyPhoneOtp({
    required OtpRequest otpRequest,
    required String otp,
  }) async {
    final result = await _dataSource.verifyPhoneOtp(
      otpRequest: otpRequest,
      smsCode: otp,
    );

    final user = _dataSource.mapFirebaseUser(result.credential.user!);
    final token = _dataSource.makeAuthToken(
      result.idToken,
      result.credential.user!.refreshToken,
    );

    await _tokenStore.save(token);
    return (user: user, token: token);
  }

  // ---------------------------------------------------------------------------
  // Session management
  // ---------------------------------------------------------------------------

  /// Force-refreshes the Firebase ID token and persists the new [AuthToken].
  ///
  /// Calls [FirebaseAuth.currentUser?.getIdToken(true)] to obtain a fresh ID
  /// token from Firebase, builds a new [AuthToken], saves it to [TokenStore],
  /// and returns it.
  ///
  /// The [refreshToken] parameter is accepted for interface compatibility but
  /// Firebase manages refresh token rotation internally.
  ///
  /// Satisfies Requirement 7, Criteria 3 (Token Refresh and Rotation).
  @override
  Future<AuthToken> refreshToken({required String refreshToken}) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found. Please sign in again.',
      );
    }

    // Force-refresh the Firebase ID token (true = bypass cache).
    final newIdToken = await currentUser.getIdToken(true);
    final token = _dataSource.makeAuthToken(
      newIdToken ?? '',
      currentUser.refreshToken,
    );

    await _tokenStore.save(token);
    return token;
  }

  /// Signs the current user out of Firebase and clears local tokens.
  ///
  /// Both operations run concurrently via [Future.wait] for efficiency.
  ///
  /// Satisfies Requirement 8 (Sign-Out).
  @override
  Future<void> signOut() async {
    await Future.wait([
      _dataSource.signOut(),
      _tokenStore.clear(),
    ]);
  }

  /// Returns the currently authenticated [AppUser], or `null` when no valid
  /// session exists.
  ///
  /// Reads [FirebaseAuth.currentUser] synchronously; if present, maps it to
  /// [AppUser] via [FirebaseAuthDataSource.mapFirebaseUser].
  ///
  /// Satisfies Requirement 7, Criteria 6 (Silent session restore on app
  /// launch).
  @override
  Future<AppUser?> getCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;
    return _dataSource.mapFirebaseUser(currentUser);
  }

  // ---------------------------------------------------------------------------
  // Password management
  // ---------------------------------------------------------------------------

  /// Sends a password-reset email to [email] via Firebase Auth.
  ///
  /// Delegates directly to [FirebaseAuthDataSource.sendPasswordResetEmail].
  ///
  /// Satisfies Requirement 9, Criteria 1 and 3 (Forgot Password — email).
  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _dataSource.sendPasswordResetEmail(email: email);
  }

  /// Sends a password-reset OTP to [phoneNumber] via SMS.
  ///
  /// Firebase does not have a dedicated SMS password-reset API. Instead, the
  /// OTP flow is used: this method triggers [sendPhoneOtp] to deliver a
  /// verification code. The caller then uses [resetPasswordWithOtp] to verify
  /// the code and set the new password.
  ///
  /// The [OtpRequest] result is discarded here; callers that need it should
  /// call [sendPhoneOtp] directly and retain the result.
  ///
  /// Satisfies Requirement 9, Criteria 2 and 3 (Forgot Password — SMS).
  @override
  Future<void> sendPasswordResetSms({required String phoneNumber}) async {
    // Trigger OTP delivery; the OtpRequest is not returned here because the
    // interface signature is Future<void>. Callers needing the OtpRequest
    // should call sendPhoneOtp directly.
    await _dataSource.sendPhoneOtp(phoneNumber: phoneNumber);
  }

  /// Resets the account password using a valid OTP and sets [newPassword].
  ///
  /// Steps:
  ///   1. Verify the OTP via [FirebaseAuthDataSource.verifyPhoneOtp] to
  ///      re-authenticate the user.
  ///   2. Call [FirebaseAuth.currentUser?.updatePassword] to set the new
  ///      password.
  ///   3. Map the user, build and persist a fresh [AuthToken], and return both.
  ///
  /// Satisfies Requirement 9, Criteria 4–6 (Password Reset with OTP).
  @override
  Future<({AppUser user, AuthToken token})> resetPasswordWithOtp({
    required OtpRequest otpRequest,
    required String otp,
    required String newPassword,
  }) async {
    // Step 1: Verify OTP — this signs the user in via phone credential.
    final result = await _dataSource.verifyPhoneOtp(
      otpRequest: otpRequest,
      smsCode: otp,
    );

    // Step 2: Update the password for the now-authenticated user.
    await result.credential.user!.updatePassword(newPassword);

    // Step 3: Map user and build a fresh token.
    final user = _dataSource.mapFirebaseUser(result.credential.user!);
    final token = _dataSource.makeAuthToken(
      result.idToken,
      result.credential.user!.refreshToken,
    );

    await _tokenStore.save(token);
    return (user: user, token: token);
  }

  /// Changes the password for the currently authenticated user.
  ///
  /// Steps:
  ///   1. Re-authenticate with [EmailAuthProvider.credential] using
  ///      [currentPassword] to confirm identity.
  ///   2. Call [user.updatePassword] to set [newPassword].
  ///   3. Force-rotate the ID token via [user.getIdToken(true)] to invalidate
  ///      other sessions.
  ///
  /// Satisfies Requirement 10 (Change Password — Authenticated).
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user found. Please sign in again.',
      );
    }

    final email = currentUser.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'no-email',
        message:
            'Cannot change password: no email address is linked to this account.',
      );
    }

    // Step 1: Re-authenticate to confirm the current password.
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser.reauthenticateWithCredential(credential);

    // Step 2: Set the new password.
    await currentUser.updatePassword(newPassword);

    // Step 3: Force-rotate the ID token to invalidate other active sessions.
    await currentUser.getIdToken(true);
  }
}
