// integration_test/google_sign_in_test.dart
//
// Task 10.2 — Google sign-in flow
//
// Tests Google sign-in success and cancellation using a FakeAuthRepository
// injected via ProviderScope overrides. No real Firebase connection is made.

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
      uid: 'uid-google',
      email: 'google@example.com',
      displayName: 'Google User',
      isVerified: true,
      isDeactivated: false,
      createdAt: DateTime(2024, 1, 1),
      linkedProviders: const ['google.com'],
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

  bool throwOnSignInWithGoogle = false;
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
    if (throwOnSignInWithGoogle) throw _err('sign-in-cancelled');
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
// Tests
// =============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test 1: Google sign-in success
  // ---------------------------------------------------------------------------

  testWidgets('Google sign-in success navigates to HomeScreen',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    await tester.pumpWidget(_buildApp(fakeRepo));
    // Let session restore settle (getCurrentUser returns null → unauthenticated)
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Tap "Continue with Google" button
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    // FakeAuthRepository.signInWithGoogle returns success → HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Google sign-in cancelled
  // ---------------------------------------------------------------------------

  testWidgets(
      'Google sign-in cancelled shows SnackBar and stays on LoginScreen',
      (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository()..throwOnSignInWithGoogle = true;

    await tester.pumpWidget(_buildApp(fakeRepo));
    await tester.pumpAndSettle();

    // App starts at LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Tap "Continue with Google" — FakeAuthRepository throws sign-in-cancelled
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    // SnackBar appears with the mapped error message
    expect(find.text('Sign-in was cancelled.'), findsOneWidget);

    // App stays on LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
