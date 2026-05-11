// integration_test/account_lockout_test.dart
//
// Task 10.4 — Account lockout after 5 failed attempts
//
// Tests that the UI shows the lockout SnackBar after 5 failed sign-in attempts
// and that a successful sign-in navigates to HomeScreen. Uses a
// FakeAuthRepository injected via ProviderScope overrides. No real Firebase
// connection is made.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:akka_food/core/router/app_router.dart';
import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/domain/entities/auth_token.dart';
import 'package:akka_food/features/auth/domain/entities/otp_request.dart';
import 'package:akka_food/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/auth/presentation/screens/login_screen.dart';

// =============================================================================
// Shared test fixtures
// =============================================================================

AppUser _fakeUser() => AppUser(
      uid: 'uid-test',
      email: 'user@example.com',
      displayName: 'Test User',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['password'],
    );

AuthToken _fakeToken() => AuthToken(
      accessToken: 'fake-access-token',
      refreshToken: 'fake-refresh-token',
      expiresAt: DateTime(2099, 1, 1),
    );

OtpRequest _fakeOtpRequest() => OtpRequest(
      verificationId: 'verif-id-abc',
      channel: 'sms',
      issuedAt: DateTime(2024, 1, 1),
    );

// =============================================================================
// FakeAuthRepository — configurable to throw on the Nth attempt
// =============================================================================

/// A fake repository that throws [FirebaseAuthException] with code
/// `too-many-requests` on the [lockoutOnAttempt]-th call to [signInWithEmail].
///
/// Before that attempt it throws `wrong-password` to simulate failed attempts.
/// After the lockout attempt it continues to throw `too-many-requests`.
class FakeAuthRepository implements IAuthRepository {
  AppUser returnUser = _fakeUser();
  AuthToken returnToken = _fakeToken();
  OtpRequest returnOtpRequest = _fakeOtpRequest();

  /// The attempt number (1-based) on which to throw `too-many-requests`.
  /// Set to 0 to never lock out (always succeed).
  int lockoutOnAttempt = 0;

  int _signInCallCount = 0;
  AppUser? currentUser;

  FirebaseAuthException _err(String code) => FirebaseAuthException(code: code);

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<({AppUser user, AuthToken token})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (lockoutOnAttempt > 0) {
      _signInCallCount++;
      if (_signInCallCount < lockoutOnAttempt) {
        // Simulate wrong-password for attempts before the lockout
        throw _err('wrong-password');
      }
      if (_signInCallCount >= lockoutOnAttempt) {
        // Simulate account lockout on and after the lockout attempt
        throw _err('too-many-requests');
      }
    }
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
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
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signInWithFacebook() async {
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<OtpRequest> sendPhoneOtp({required String phoneNumber}) async =>
      returnOtpRequest;

  @override
  Future<({AppUser user, AuthToken token})> verifyPhoneOtp({
    required OtpRequest otpRequest,
    required String otp,
  }) async {
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<AuthToken> refreshToken({required String refreshToken}) async =>
      returnToken;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

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
  }) async {}
}

// =============================================================================
// Helper — builds the full app with a fake repository
// =============================================================================

Widget _buildApp(FakeAuthRepository fakeRepo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeRepo),
    ],
    child: const _AppUnderTest(),
  );
}

class _AppUnderTest extends ConsumerWidget {
  const _AppUnderTest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'AKKA Food Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      routerConfig: router,
    );
  }
}

// =============================================================================
// Helper — fills and submits the login form once
// =============================================================================

Future<void> _attemptSignIn(WidgetTester tester) async {
  final textFields = find.byType(TextFormField);
  // Clear and re-enter to ensure the form is populated on each attempt
  await tester.enterText(textFields.at(0), 'user@example.com');
  await tester.pump();
  await tester.enterText(textFields.at(1), 'wrongpassword');
  await tester.pump();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
  await tester.pumpAndSettle();
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test 1: Account lockout after 5 failed sign-in attempts
  // ---------------------------------------------------------------------------

  testWidgets(
      'Account lockout SnackBar appears on 5th failed attempt and app stays on LoginScreen',
      (WidgetTester tester) async {
    // Configure fake to throw too-many-requests on the 5th attempt
    final fakeRepo = FakeAuthRepository()..lockoutOnAttempt = 5;

    await tester.pumpWidget(_buildApp(fakeRepo));
    // Let session restore settle (getCurrentUser returns null → unauthenticated)
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Attempt sign-in 4 times — each shows "Incorrect credentials." SnackBar
    for (int i = 1; i <= 4; i++) {
      await _attemptSignIn(tester);
      // Dismiss any SnackBar before the next attempt
      await tester.pump(const Duration(seconds: 5));
    }

    // 5th attempt — FakeAuthRepository throws too-many-requests
    await _attemptSignIn(tester);

    // SnackBar shows the lockout message
    expect(
      find.text('Account locked. Try again in 15 minutes.'),
      findsOneWidget,
    );

    // App stays on LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Successful sign-in resets lockout (no lockout configured)
  // ---------------------------------------------------------------------------

  testWidgets('Successful sign-in navigates to HomeScreen',
      (WidgetTester tester) async {
    // No lockout — all sign-in attempts succeed
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(_buildApp(fakeRepo));
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Fill email and password
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'user@example.com');
    await tester.pump();
    await tester.enterText(textFields.at(1), 'P@ssw0rd1');
    await tester.pump();

    // Tap "Sign In" — FakeAuthRepository returns success
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    // App navigates to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
