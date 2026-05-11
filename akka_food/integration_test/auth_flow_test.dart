// integration_test/auth_flow_test.dart
//
// Task 10.1 — Full sign-up → OTP verify → sign-in flow
//
// Tests the complete email sign-up, phone OTP, and email sign-in flows using
// a FakeAuthRepository injected via ProviderScope overrides. No real Firebase
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
import 'package:akka_food/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:akka_food/features/auth/presentation/screens/sign_up_screen.dart';

// =============================================================================
// Shared test fixtures
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

  bool throwOnSignIn = false;
  bool throwOnSignUp = false;
  bool throwOnSendPhoneOtp = false;
  bool throwOnVerifyPhoneOtp = false;

  AppUser? currentUser;

  FirebaseAuthException _err(String code) => FirebaseAuthException(code: code);

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<({AppUser user, AuthToken token})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (throwOnSignIn) throw _err('wrong-password');
    return (user: returnUser, token: returnToken);
  }

  @override
  Future<({AppUser user, AuthToken token})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (throwOnSignUp) throw _err('email-already-in-use');
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
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test 1: Email sign-up flow
  // ---------------------------------------------------------------------------

  testWidgets('Email sign-up flow navigates to HomeScreen on success',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(_buildApp(fakeRepo));
    // Let session restore settle (getCurrentUser returns null → unauthenticated)
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Tap "Sign Up" to navigate to SignUpScreen
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);

    // Email mode is default — fill in the form fields
    final textFields = find.byType(TextFormField);

    // Display Name field (first)
    await tester.enterText(textFields.at(0), 'Test User');
    await tester.pump();

    // Email field (second)
    await tester.enterText(textFields.at(1), 'test@example.com');
    await tester.pump();

    // Password field (third)
    await tester.enterText(textFields.at(2), 'P@ssw0rd1');
    await tester.pump();

    // Confirm Password field (fourth)
    await tester.enterText(textFields.at(3), 'P@ssw0rd1');
    await tester.pump();

    // Tap "Sign Up" button — FakeAuthRepository.signUpWithEmail returns success
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    // App navigates to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Phone sign-up → OTP flow
  // ---------------------------------------------------------------------------

  testWidgets('Phone sign-up → OTP flow navigates to HomeScreen on success',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(_buildApp(fakeRepo));
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Tap "Sign Up" → SignUpScreen
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpScreen), findsOneWidget);

    // Toggle to Phone mode via SegmentedButton
    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    // Fill Display Name (first field)
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Phone User');
    await tester.pump();

    // Fill Phone Number (second field — email/password fields are hidden)
    await tester.enterText(textFields.at(1), '+22670000000');
    await tester.pump();

    // Tap "Sign Up" → calls signInWithPhone → FakeAuthRepository.sendPhoneOtp
    // returns OtpRequest → app navigates to OtpVerificationScreen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpVerificationScreen), findsOneWidget);

    // Enter 6-digit OTP
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pump();

    // Tap "Verify" → calls verifyPhoneOtp → app navigates to HomeScreen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 3: Email sign-in flow
  // ---------------------------------------------------------------------------

  testWidgets('Email sign-in flow navigates to HomeScreen on success',
      (WidgetTester tester) async {
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

    // Tap "Sign In" — FakeAuthRepository.signInWithEmail returns success
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    // App navigates to HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
