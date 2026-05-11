import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/otp_request.dart';

/// Data source that wraps the Firebase Auth SDK.
///
/// All [FirebaseAuthException] errors are rethrown as-is so the
/// [AuthRepository] layer above can map them to user-friendly messages.
///
/// Inject custom instances via the constructor for testability.
class FirebaseAuthDataSource {
  // ---------------------------------------------------------------------------
  // 4.1 — Constructor / factory
  // ---------------------------------------------------------------------------

  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  // ---------------------------------------------------------------------------
  // 4.2 — Email/password sign-up
  // ---------------------------------------------------------------------------

  /// Creates a new Firebase account with [email] and [password], then sets
  /// [displayName] on the resulting user profile.
  ///
  /// Returns the [UserCredential] and the Firebase ID token string.
  Future<({UserCredential credential, String idToken})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);
    final idToken = await _getIdToken(credential.user!);
    return (credential: credential, idToken: idToken);
  }

  // ---------------------------------------------------------------------------
  // 4.3 — Email/password sign-in
  // ---------------------------------------------------------------------------

  /// Signs in an existing user with [email] and [password].
  ///
  /// Returns the [UserCredential] and the Firebase ID token string.
  Future<({UserCredential credential, String idToken})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await _getIdToken(credential.user!);
    return (credential: credential, idToken: idToken);
  }

  // ---------------------------------------------------------------------------
  // 4.4 — Phone OTP flow
  // ---------------------------------------------------------------------------

  /// Triggers Firebase phone number verification for [phoneNumber].
  ///
  /// Uses a [Completer] to bridge the callback-based Firebase API into a
  /// `Future`. Resolves with an [OtpRequest] once Firebase has sent the SMS
  /// and returned a `verificationId` via `codeSent`.
  ///
  /// If auto-retrieval completes before the user enters the code,
  /// `verificationCompleted` resolves the completer early with a synthetic
  /// [OtpRequest] whose `verificationId` is the credential's `verificationId`.
  Future<OtpRequest> sendPhoneOtp({required String phoneNumber}) async {
    final completer = Completer<OtpRequest>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-retrieval or instant verification on Android.
        if (!completer.isCompleted) {
          completer.complete(
            OtpRequest(
              verificationId: credential.verificationId ?? '',
              channel: 'sms',
              issuedAt: DateTime.now(),
            ),
          );
        }
      },
      verificationFailed: (FirebaseAuthException exception) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            OtpRequest(
              verificationId: verificationId,
              channel: 'sms',
              issuedAt: DateTime.now(),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Timeout reached without auto-retrieval; the user must enter the code
        // manually. Only complete if not already resolved.
        if (!completer.isCompleted) {
          completer.complete(
            OtpRequest(
              verificationId: verificationId,
              channel: 'sms',
              issuedAt: DateTime.now(),
            ),
          );
        }
      },
    );

    return completer.future;
  }

  /// Verifies the [smsCode] against the pending [otpRequest] and signs in.
  ///
  /// Returns the [UserCredential] and the Firebase ID token string.
  Future<({UserCredential credential, String idToken})> verifyPhoneOtp({
    required OtpRequest otpRequest,
    required String smsCode,
  }) async {
    final phoneCredential = PhoneAuthProvider.credential(
      verificationId: otpRequest.verificationId,
      smsCode: smsCode,
    );
    final credential = await _auth.signInWithCredential(phoneCredential);
    final idToken = await _getIdToken(credential.user!);
    return (credential: credential, idToken: idToken);
  }

  // ---------------------------------------------------------------------------
  // 4.5 — Google sign-in
  // ---------------------------------------------------------------------------

  /// Signs in via Google.
  ///
  /// Calls [GoogleSignIn.signIn], exchanges the Google tokens for a Firebase
  /// [OAuthCredential], then calls [FirebaseAuth.signInWithCredential].
  ///
  /// Returns the [UserCredential] and the Firebase ID token string.
  Future<({UserCredential credential, String idToken})>
      signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final oauthCredential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final credential = await _auth.signInWithCredential(oauthCredential);
    final idToken = await _getIdToken(credential.user!);
    return (credential: credential, idToken: idToken);
  }

  // ---------------------------------------------------------------------------
  // 4.6 — Facebook sign-in
  // ---------------------------------------------------------------------------

  /// Signs in via Facebook.
  ///
  /// Calls [FacebookAuth.login], exchanges the Facebook access token for a
  /// Firebase [OAuthCredential], then calls [FirebaseAuth.signInWithCredential].
  ///
  /// Returns the [UserCredential] and the Firebase ID token string.
  Future<({UserCredential credential, String idToken})>
      signInWithFacebook() async {
    final loginResult = await _facebookAuth.login();

    if (loginResult.status != LoginStatus.success ||
        loginResult.accessToken == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Facebook sign-in was cancelled or failed.',
      );
    }

    final oauthCredential = FacebookAuthProvider.credential(
      loginResult.accessToken!.tokenString,
    );

    final credential = await _auth.signInWithCredential(oauthCredential);
    final idToken = await _getIdToken(credential.user!);
    return (credential: credential, idToken: idToken);
  }

  // ---------------------------------------------------------------------------
  // 4.7 — Sign-out
  // ---------------------------------------------------------------------------

  /// Signs the current user out of Firebase, Google, and Facebook.
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
      _facebookAuth.logOut(),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 4.8 — Password reset
  // ---------------------------------------------------------------------------

  /// Sends a password-reset email to [email] via Firebase Auth.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Retrieves the Firebase ID token string for [user].
  Future<String> _getIdToken(User user) async {
    final token = await user.getIdToken();
    return token ?? '';
  }

  /// Converts a Firebase [User] to the domain [AppUser] entity.
  AppUser mapFirebaseUser(User user) {
    final providers = user.providerData
        .map((info) => info.providerId)
        .toList();

    return AppUser(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName ?? '',
      isVerified: user.emailVerified,
      isDeactivated: false,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      linkedProviders: providers,
    );
  }

  /// Builds an [AuthToken] from [idToken] and an optional [refreshToken].
  ///
  /// The [expiresAt] is set to one hour from now, matching Firebase ID token
  /// lifetime.
  AuthToken makeAuthToken(String idToken, String? refreshToken) {
    return AuthToken(
      accessToken: idToken,
      refreshToken: refreshToken ?? '',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }
}
