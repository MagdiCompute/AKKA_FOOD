import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'auth_error_mapper.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

// ---------------------------------------------------------------------------
// Convenience provider — exposes the current AppUser? directly.
// ---------------------------------------------------------------------------

/// A [StateProvider] that mirrors the authenticated user from [AuthNotifier].
///
/// Screens and the router read this provider to get the current [AppUser]
/// without having to unwrap [AuthState] every time.
///
/// The value is kept in sync by [AuthNotifier] via [_syncCurrentUser].
final currentUserProvider = StateProvider<AppUser?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user;
});

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [AuthRepository] bound to [IAuthRepository].
///
/// Override in tests by using `ProviderScope(overrides: [...])`.
@riverpod
IAuthRepository authRepository(Ref ref) {
  return AuthRepository(
    dataSource: FirebaseAuthDataSource(),
    tokenStore: TokenStore(),
  );
}

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

/// Manages the global authentication state for the app.
///
/// Uses a synchronous [Notifier] (not [AsyncNotifier]) because [AuthState]
/// is a plain value object — loading/error states are encoded inside it.
///
/// On first build, [_restoreSession] is triggered asynchronously so the UI
/// can render immediately with [AuthStatus.initial] while the session check
/// runs in the background.
@riverpod
class AuthNotifier extends _$AuthNotifier {
  // ---------------------------------------------------------------------------
  // 6.1 — build
  // ---------------------------------------------------------------------------

  @override
  AuthState build() {
    // Kick off silent session restore without blocking the synchronous build.
    _restoreSession();
    return const AuthState.initial();
  }

  // Convenience accessor for the injected repository.
  IAuthRepository get _repository => ref.read(authRepositoryProvider);

  // ---------------------------------------------------------------------------
  // 6.2 — Silent session restore
  // ---------------------------------------------------------------------------

  /// Checks whether a valid Firebase session already exists and updates state
  /// accordingly.
  ///
  /// Called once during [build]. Emits [AuthState.authenticated] when a
  /// current user is found, or [AuthState.unauthenticated] otherwise.
  ///
  /// Satisfies Requirement 7, Criteria 6 (Silent session restore on app
  /// launch).
  Future<void> _restoreSession() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        final enriched = await _enrichWithFirestoreRole(user);
        state = AuthState.authenticated(enriched);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-in with email/password
  // ---------------------------------------------------------------------------

  /// Authenticates an existing user with [email] and [password].
  ///
  /// Satisfies Requirement 4 (Sign-In with Email and Password).
  Future<void> signIn(String email, String password) async {
    state = const AuthState.loading();
    try {
      final result = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      final enriched = await _enrichWithFirestoreRole(result.user);
      state = AuthState.authenticated(enriched);
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-up with email/password
  // ---------------------------------------------------------------------------

  /// Creates a new account with [email], [password], and [displayName].
  ///
  /// Satisfies Requirement 1 (User Registration with Email and Password).
  Future<void> signUp(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AuthState.loading();
    try {
      final result = await _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      final enriched = await _enrichWithFirestoreRole(result.user);
      state = AuthState.authenticated(enriched);
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Google sign-in
  // ---------------------------------------------------------------------------

  /// Authenticates (or registers) a user via Google Sign-In.
  ///
  /// Satisfies Requirement 6, Criteria 1, 3, 4, 6 (Social Login — Google).
  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      final result = await _repository.signInWithGoogle();
      state = AuthState.authenticated(result.user);
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Facebook sign-in
  // ---------------------------------------------------------------------------

  /// Authenticates (or registers) a user via Facebook Login.
  ///
  /// Satisfies Requirement 6, Criteria 2, 3, 4, 6 (Social Login — Facebook).
  Future<void> signInWithFacebook() async {
    state = const AuthState.loading();
    try {
      final result = await _repository.signInWithFacebook();
      state = AuthState.authenticated(result.user);
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP — step 1: send OTP
  // ---------------------------------------------------------------------------

  /// Sends a 6-digit OTP to [phoneNumber] via SMS.
  ///
  /// On success, stores the [OtpRequest] in state so the UI knows to show
  /// the OTP verification screen.
  ///
  /// Satisfies Requirement 2, Criteria 3 and Requirement 3, Criteria 5.
  Future<void> signInWithPhone(String phoneNumber) async {
    state = const AuthState.loading();
    try {
      final otpRequest = await _repository.sendPhoneOtp(
        phoneNumber: phoneNumber,
      );
      // Emit a loading state that carries the OtpRequest so the UI can
      // navigate to the OTP screen while the notifier awaits the code.
      state = AuthState(
        status: AuthStatus.loading,
        pendingOtpRequest: otpRequest,
      );
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Phone OTP — step 2: verify OTP
  // ---------------------------------------------------------------------------

  /// Verifies the [otp] code against the pending [OtpRequest] stored in state.
  ///
  /// Satisfies Requirement 3, Criteria 1–4 (Account Verification).
  Future<void> verifyOtp(String otp) async {
    final pendingRequest = state.pendingOtpRequest;
    if (pendingRequest == null) {
      state = const AuthState.error(
        'No pending OTP request. Please request a new code.',
      );
      return;
    }

    state = AuthState(
      status: AuthStatus.loading,
      pendingOtpRequest: pendingRequest,
    );

    try {
      final result = await _repository.verifyPhoneOtp(
        otpRequest: pendingRequest,
        otp: otp,
      );
      state = AuthState.authenticated(result.user);
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  /// Signs the current user out and clears all local tokens.
  ///
  /// Satisfies Requirement 8 (Sign-Out).
  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _repository.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Firestore role enrichment
  // ---------------------------------------------------------------------------

  /// Reads the user's `role` field from Firestore `/users/{uid}` and returns
  /// an [AppUser] with the role applied.
  ///
  /// Falls back to the original user (role='user') if the document doesn't
  /// exist or the read fails.
  Future<AppUser> _enrichWithFirestoreRole(AppUser user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final role = doc.data()!['role'] as String? ?? 'user';
        return user.copyWith(role: role);
      }
    } catch (_) {
      // Firestore read failed — use default role.
    }
    return user;
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  /// Sends a password-reset email to [email].
  ///
  /// On success emits [AuthState.unauthenticated] — the UI is responsible for
  /// showing a success message separately.
  ///
  /// Satisfies Requirement 9, Criteria 1 and 3 (Forgot Password — email).
  Future<void> resetPassword(String email) async {
    state = const AuthState.loading();
    try {
      await _repository.sendPasswordResetEmail(email: email);
      // Emit unauthenticated; the UI shows a "check your email" message.
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Change password (authenticated)
  // ---------------------------------------------------------------------------

  /// Changes the password for the currently authenticated user.
  ///
  /// On success re-emits [AuthState.authenticated] with the current user so
  /// the session remains active.
  ///
  /// Satisfies Requirement 10 (Change Password — Authenticated).
  Future<void> changePassword(String current, String newPassword) async {
    final currentUser = state.user;
    state = const AuthState.loading();
    try {
      await _repository.changePassword(
        currentPassword: current,
        newPassword: newPassword,
      );
      if (currentUser != null) {
        state = AuthState.authenticated(currentUser);
      } else {
        // Fallback: re-fetch the current user from the repository.
        final refreshed = await _repository.getCurrentUser();
        state = refreshed != null
            ? AuthState.authenticated(refreshed)
            : const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(mapAuthError(e));
    }
  }
}
