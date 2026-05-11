import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/domain/entities/auth_token.dart';
import 'package:akka_food/features/auth/domain/entities/otp_request.dart';
import 'package:akka_food/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_state.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser({
  String uid = 'uid-test',
  String email = 'user@example.com',
  String displayName = 'Test User',
}) {
  return AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    isVerified: true,
    isDeactivated: false,
    createdAt: DateTime(2024, 1, 1),
    linkedProviders: const ['password'],
  );
}

AuthToken _fakeToken() {
  return AuthToken(
    accessToken: 'fake-access-token',
    refreshToken: 'fake-refresh-token',
    expiresAt: DateTime(2099, 1, 1),
  );
}

OtpRequest _fakeOtpRequest() {
  return OtpRequest(
    verificationId: 'verif-id-abc',
    channel: 'sms',
    issuedAt: DateTime(2024, 1, 1),
  );
}

// =============================================================================
// FakeAuthRepository
// =============================================================================

/// Configurable fake [IAuthRepository] for testing [AuthNotifier] in isolation.
///
/// Each method has a corresponding `throw*` flag to simulate failures, and
/// preset return values for success paths.
class FakeAuthRepository implements IAuthRepository {
  // --- Preset return values ---
  AppUser returnUser = _fakeUser();
  AuthToken returnToken = _fakeToken();
  OtpRequest returnOtpRequest = _fakeOtpRequest();

  // --- Error simulation flags ---
  bool throwOnSignIn = false;
  bool throwOnSignUp = false;
  bool throwOnSignInWithGoogle = false;
  bool throwOnSignInWithFacebook = false;
  bool throwOnSendPhoneOtp = false;
  bool throwOnVerifyPhoneOtp = false;
  bool throwOnSignOut = false;
  bool throwOnResetPassword = false;
  bool throwOnChangePassword = false;

  /// When non-null, [getCurrentUser] returns this value.
  /// When null, [getCurrentUser] returns null (unauthenticated).
  AppUser? currentUser;

  // --- Call tracking ---
  bool signOutCalled = false;
  String? lastResetPasswordEmail;
  String? lastChangePasswordCurrent;
  String? lastChangePasswordNew;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  FirebaseAuthException _fakeFirebaseError(String code) =>
      FirebaseAuthException(code: code);

  // ---------------------------------------------------------------------------
  // IAuthRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<({AppUser user, AuthToken token})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (throwOnSignIn) throw _fakeFirebaseError('wrong-password');
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (throwOnSignUp) throw _fakeFirebaseError('email-already-in-use');
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signUpWithPhone({
    required String phoneNumber,
    required String password,
    required String displayName,
  }) async {
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signInWithGoogle() async {
    if (throwOnSignInWithGoogle) throw _fakeFirebaseError('sign-in-cancelled');
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signInWithFacebook() async {
    if (throwOnSignInWithFacebook) {
      throw _fakeFirebaseError('sign-in-cancelled');
    }
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<OtpRequest> sendPhoneOtp({required String phoneNumber}) async {
    if (throwOnSendPhoneOtp) throw _fakeFirebaseError('too-many-requests');
    return returnOtpRequest;
  }

  @override
  Future<({AppUser user, AuthToken token})> verifyPhoneOtp({
    required OtpRequest otpRequest,
    required String otp,
  }) async {
    if (throwOnVerifyPhoneOtp) {
      throw _fakeFirebaseError('invalid-verification-code');
    }
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<AuthToken> refreshToken({required String refreshToken}) async {
    return returnToken;
  }

  @override
  Future<void> signOut() async {
    if (throwOnSignOut) throw _fakeFirebaseError('network-request-failed');
    signOutCalled = true;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (throwOnResetPassword) throw _fakeFirebaseError('network-request-failed');
    lastResetPasswordEmail = email;
  }

  @override
  Future<void> sendPasswordResetSms({required String phoneNumber}) async {}

  @override
  Future<({AppUser user, AuthToken token})> resetPasswordWithOtp({
    required OtpRequest otpRequest,
    required String otp,
    required String newPassword,
  }) async {
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (throwOnChangePassword) throw _fakeFirebaseError('wrong-password');
    lastChangePasswordCurrent = currentPassword;
    lastChangePasswordNew = newPassword;
  }
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  late ProviderContainer container;
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthNotifier', () {
    // -------------------------------------------------------------------------
    // 1. Initial state
    // -------------------------------------------------------------------------

    test('build() returns AuthState.initial() synchronously', () {
      // Reading the provider synchronously — before any microtask runs —
      // must yield the initial state.
      final state = container.read(authNotifierProvider);

      expect(state.status, equals(AuthStatus.initial));
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    // -------------------------------------------------------------------------
    // 2. Session restore — authenticated
    // -------------------------------------------------------------------------

    test('restores session to authenticated when getCurrentUser returns a user',
        () async {
      fakeRepository.currentUser = _fakeUser();

      // Keep a subscription alive so the AutoDisposeNotifier is not disposed
      // between the initial read and the assertion.
      final states = <AuthStatus>[];
      final sub = container.listen(
        authNotifierProvider.select((s) => s.status),
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      // Let _restoreSession complete.
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authNotifierProvider);
      sub.close();

      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.user, equals(fakeRepository.currentUser));
    });

    // -------------------------------------------------------------------------
    // 3. Session restore — unauthenticated
    // -------------------------------------------------------------------------

    test('restores session to unauthenticated when getCurrentUser returns null',
        () async {
      fakeRepository.currentUser = null;

      final states = <AuthStatus>[];
      final sub = container.listen(
        authNotifierProvider.select((s) => s.status),
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);

      final state = container.read(authNotifierProvider);
      sub.close();

      expect(state.status, equals(AuthStatus.unauthenticated));
      expect(state.user, isNull);
    });

    // -------------------------------------------------------------------------
    // 4. signIn — success
    // -------------------------------------------------------------------------

    group('signIn', () {
      test('transitions loading → authenticated on success', () async {
        final notifier = container.read(authNotifierProvider.notifier);

        final states = <AuthStatus>[];
        final sub = container.listen(
          authNotifierProvider.select((s) => s.status),
          (_, next) => states.add(next),
        );

        await notifier.signIn('user@example.com', 'P@ssw0rd!');

        sub.close();

        expect(states, containsAllInOrder([AuthStatus.loading, AuthStatus.authenticated]));
        final finalState = container.read(authNotifierProvider);
        expect(finalState.user, equals(fakeRepository.returnUser));
      });

      // -----------------------------------------------------------------------
      // 5. signIn — failure
      // -----------------------------------------------------------------------

      test('transitions loading → error with mapped message on failure',
          () async {
        fakeRepository.throwOnSignIn = true;
        final notifier = container.read(authNotifierProvider.notifier);

        final states = <AuthStatus>[];
        final sub = container.listen(
          authNotifierProvider.select((s) => s.status),
          (_, next) => states.add(next),
        );

        await notifier.signIn('user@example.com', 'wrong');

        sub.close();

        expect(states, containsAllInOrder([AuthStatus.loading, AuthStatus.error]));
        final finalState = container.read(authNotifierProvider);
        expect(finalState.errorMessage, equals('Incorrect credentials.'));
      });
    });

    // -------------------------------------------------------------------------
    // 6. signUp — success
    // -------------------------------------------------------------------------

    group('signUp', () {
      test('transitions loading → authenticated on success', () async {
        final notifier = container.read(authNotifierProvider.notifier);

        final states = <AuthStatus>[];
        final sub = container.listen(
          authNotifierProvider.select((s) => s.status),
          (_, next) => states.add(next),
        );

        await notifier.signUp('new@example.com', 'P@ssw0rd!', 'New User');

        sub.close();

        expect(states, containsAllInOrder([AuthStatus.loading, AuthStatus.authenticated]));
        final finalState = container.read(authNotifierProvider);
        expect(finalState.user, equals(fakeRepository.returnUser));
      });
    });

    // -------------------------------------------------------------------------
    // 7. signInWithGoogle — success
    // -------------------------------------------------------------------------

    group('signInWithGoogle', () {
      test('transitions loading → authenticated on success', () async {
        final notifier = container.read(authNotifierProvider.notifier);

        final states = <AuthStatus>[];
        final sub = container.listen(
          authNotifierProvider.select((s) => s.status),
          (_, next) => states.add(next),
        );

        await notifier.signInWithGoogle();

        sub.close();

        expect(states, containsAllInOrder([AuthStatus.loading, AuthStatus.authenticated]));
        final finalState = container.read(authNotifierProvider);
        expect(finalState.user, equals(fakeRepository.returnUser));
      });
    });

    // -------------------------------------------------------------------------
    // 8. signInWithFacebook — success
    // -------------------------------------------------------------------------

    group('signInWithFacebook', () {
      test('transitions loading → authenticated on success', () async {
        final notifier = container.read(authNotifierProvider.notifier);

        final states = <AuthStatus>[];
        final sub = container.listen(
          authNotifierProvider.select((s) => s.status),
          (_, next) => states.add(next),
        );

        await notifier.signInWithFacebook();

        sub.close();

        expect(states, containsAllInOrder([AuthStatus.loading, AuthStatus.authenticated]));
        final finalState = container.read(authNotifierProvider);
        expect(finalState.user, equals(fakeRepository.returnUser));
      });
    });

    // -------------------------------------------------------------------------
    // 9. signInWithPhone — success (OTP sent)
    // -------------------------------------------------------------------------

    group('signInWithPhone', () {
      test('state has pendingOtpRequest set after OTP is sent', () async {
        final notifier = container.read(authNotifierProvider.notifier);

        await notifier.signInWithPhone('+22670000000');

        final state = container.read(authNotifierProvider);
        expect(state.pendingOtpRequest, isNotNull);
        expect(
          state.pendingOtpRequest!.verificationId,
          equals(fakeRepository.returnOtpRequest.verificationId),
        );
        expect(state.pendingOtpRequest!.channel, equals('sms'));
      });
    });

    // -------------------------------------------------------------------------
    // 10. verifyOtp — success
    // -------------------------------------------------------------------------

    group('verifyOtp', () {
      test('transitions to authenticated on success', () async {
        // First send OTP to populate pendingOtpRequest.
        // After signInWithPhone, state is loading with pendingOtpRequest set.
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signInWithPhone('+22670000000');

        // Verify the OTP — state goes loading (same status, different
        // pendingOtpRequest field) → authenticated.
        await notifier.verifyOtp('123456');

        final finalState = container.read(authNotifierProvider);
        expect(finalState.status, equals(AuthStatus.authenticated));
        expect(finalState.user, equals(fakeRepository.returnUser));
        expect(finalState.pendingOtpRequest, isNull);
      });

      // -----------------------------------------------------------------------
      // 11. verifyOtp — no pending request
      // -----------------------------------------------------------------------

      test('state becomes error when there is no pending OTP request',
          () async {
        // Do NOT call signInWithPhone first — pendingOtpRequest is null.
        // Keep a subscription alive to prevent auto-disposal.
        final states = <AuthStatus>[];
        final sub = container.listen(
          authNotifierProvider.select((s) => s.status),
          (_, next) => states.add(next),
          fireImmediately: true,
        );

        // Wait for _restoreSession to settle so we start from a clean state.
        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.verifyOtp('123456');

        sub.close();

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.error));
        expect(state.errorMessage, contains('No pending OTP request'));
      });
    });

    // -------------------------------------------------------------------------
    // 12. signOut — success
    // -------------------------------------------------------------------------

    group('signOut', () {
      test('state becomes unauthenticated after sign-out', () async {
        // Simulate an authenticated session first.
        fakeRepository.currentUser = _fakeUser();

        // Keep a subscription alive to prevent auto-disposal during session restore.
        final sub = container.listen(
          authNotifierProvider,
          (_, __) {},
          fireImmediately: true,
        );
        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.signOut();

        sub.close();

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(state.user, isNull);
        expect(fakeRepository.signOutCalled, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 13. resetPassword — success
    // -------------------------------------------------------------------------

    group('resetPassword', () {
      test('state becomes unauthenticated after password reset email is sent',
          () async {
        final notifier = container.read(authNotifierProvider.notifier);

        await notifier.resetPassword('user@example.com');

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(fakeRepository.lastResetPasswordEmail, equals('user@example.com'));
      });
    });

    // -------------------------------------------------------------------------
    // 14. changePassword — success
    // -------------------------------------------------------------------------

    group('changePassword', () {
      test('state remains authenticated after password change', () async {
        // Start from an authenticated state.
        fakeRepository.currentUser = _fakeUser();

        // Keep a subscription alive to prevent auto-disposal during session restore.
        final sub = container.listen(
          authNotifierProvider,
          (_, __) {},
          fireImmediately: true,
        );
        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.changePassword('OldPass1!', 'NewPass1!');

        sub.close();

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.authenticated));
        expect(state.user, isNotNull);
        expect(fakeRepository.lastChangePasswordCurrent, equals('OldPass1!'));
        expect(fakeRepository.lastChangePasswordNew, equals('NewPass1!'));
      });
    });
  });
}
