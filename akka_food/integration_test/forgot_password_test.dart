// integration_test/forgot_password_test.dart
//
// Task 10.3 — Forgot password → OTP → reset flow
//
// Tests the email password reset and phone OTP reset flows using a
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
import 'package:akka_food/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:akka_food/features/auth/presentation/screens/login_screen.dart';
import 'package:akka_food/features/auth/presentation/screens/otp_verification_screen.dart';

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
// FakeAuthRepository
// =============================================================================

class FakeAuthRepository implements IAuthRepository {
  AppUser returnUser = _fakeUser();
  AuthToken returnToken = _fakeToken();
  OtpRequest returnOtpRequest = _fakeOtpRequest();

  bool throwOnResetPassword = false;
  bool throwOnSendPhoneOtp = false;
  bool throwOnVerifyPhoneOtp = false;

  String? lastResetPasswordEmail;
  AppUser? currentUser;

  FirebaseAuthException _err(String code) => FirebaseAuthException(code: code);

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<({AppUser user, AuthToken token})> signInWithEmail({
    required String email,
    required String password,
  }) async {
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
  Future<OtpRequest> sendPhoneOtp({required String phoneNumber}) async {
    if (throwOnSendPhoneOtp) throw _err('too-many-requests');
    return returnOtpRequest;
  }

  @override
  Future<({AppUser user, AuthToken token})> verifyPhoneOtp({
    required OtpRequest otpRequest,
    required String otp,
  }) async {
    if (throwOnVerifyPhoneOtp) throw _err('invalid-verification-code');
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<AuthToken> refreshToken({required String refreshToken}) async =>
      returnToken;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (throwOnResetPassword) throw _err('network-request-failed');
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
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test 1: Email password reset
  // ---------------------------------------------------------------------------

  testWidgets('Email password reset shows success banner',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(_buildApp(fakeRepo));
    // Let session restore settle (getCurrentUser returns null → unauthenticated)
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Tap "Forgot password?" → ForgotPasswordScreen
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);

    // Email mode is default — enter email address
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.pump();

    // Tap "Send Reset Link"
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Reset Link'));
    await tester.pumpAndSettle();

    // Success banner appears with the expected message
    expect(
      find.text('Reset link sent! Check your email inbox.'),
      findsOneWidget,
    );
  });

  // ---------------------------------------------------------------------------
  // Test 2: Phone OTP reset flow
  // ---------------------------------------------------------------------------

  testWidgets('Phone OTP reset flow navigates to HomeScreen on success',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(_buildApp(fakeRepo));
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Tap "Forgot password?" → ForgotPasswordScreen
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);

    // Toggle to Phone mode via ChoiceChip
    await tester.tap(find.widgetWithText(ChoiceChip, 'Phone'));
    await tester.pumpAndSettle();

    // Enter phone number
    await tester.enterText(find.byType(TextFormField), '+22670000000');
    await tester.pump();

    // Tap "Send Code" → FakeAuthRepository.sendPhoneOtp returns OtpRequest
    // → app navigates to OtpVerificationScreen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send Code'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpVerificationScreen), findsOneWidget);

    // Enter 6-digit OTP
    await tester.enterText(find.byType(TextFormField), '654321');
    await tester.pump();

    // Tap "Verify" → calls verifyPhoneOtp → app navigates to HomeScreen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
