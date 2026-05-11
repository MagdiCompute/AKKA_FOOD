import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:akka_food/features/auth/data/datasources/token_store.dart';
import 'package:akka_food/features/auth/data/repositories/auth_repository.dart';
import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/domain/entities/auth_token.dart';
import 'package:akka_food/features/auth/domain/entities/otp_request.dart';

// =============================================================================
// Test fixtures
// =============================================================================

AppUser _fakeUser({
  String uid = 'uid-123',
  String email = 'test@example.com',
  String displayName = 'Test User',
}) {
  return AppUser(
    uid: uid,
    email: email,
    displayName: displayName,
    isVerified: false,
    isDeactivated: false,
    createdAt: DateTime(2024, 1, 1),
    linkedProviders: const ['password'],
  );
}

AuthToken _fakeToken({String accessToken = 'fake-id-token'}) {
  return AuthToken(
    accessToken: accessToken,
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
// Fake FirebaseAuthDataSource
// =============================================================================

/// Configurable fake that records calls and returns preset values.
class FakeFirebaseAuthDataSource extends Fake
    implements FirebaseAuthDataSource {
  // --- Preset return values ---
  AppUser returnUser = _fakeUser();
  AuthToken returnToken = _fakeToken();
  OtpRequest returnOtpRequest = _fakeOtpRequest();

  // --- Call tracking ---
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpDisplayName;

  String? lastSignInEmail;
  String? lastSignInPassword;

  bool signInWithGoogleCalled = false;
  bool signInWithFacebookCalled = false;

  String? lastSendPhoneOtpNumber;

  OtpRequest? lastVerifyOtpRequest;
  String? lastVerifySmsCode;

  bool signOutCalled = false;

  String? lastPasswordResetEmail;

  // --- Helpers to build the record-type return value ---
  ({UserCredential credential, String idToken}) _makeResult() {
    return (
      credential: _FakeUserCredential(returnUser, returnToken),
      idToken: returnToken.accessToken,
    );
  }

  @override
  Future<({UserCredential credential, String idToken})> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpDisplayName = displayName;
    return _makeResult();
  }

  @override
  Future<({UserCredential credential, String idToken})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    lastSignInEmail = email;
    lastSignInPassword = password;
    return _makeResult();
  }

  @override
  Future<({UserCredential credential, String idToken})>
      signInWithGoogle() async {
    signInWithGoogleCalled = true;
    return _makeResult();
  }

  @override
  Future<({UserCredential credential, String idToken})>
      signInWithFacebook() async {
    signInWithFacebookCalled = true;
    return _makeResult();
  }

  @override
  Future<OtpRequest> sendPhoneOtp({required String phoneNumber}) async {
    lastSendPhoneOtpNumber = phoneNumber;
    return returnOtpRequest;
  }

  @override
  Future<({UserCredential credential, String idToken})> verifyPhoneOtp({
    required OtpRequest otpRequest,
    required String smsCode,
  }) async {
    lastVerifyOtpRequest = otpRequest;
    lastVerifySmsCode = smsCode;
    return _makeResult();
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    lastPasswordResetEmail = email;
  }

  @override
  AppUser mapFirebaseUser(User user) => returnUser;

  @override
  AuthToken makeAuthToken(String idToken, String? refreshToken) =>
      returnToken;
}

// =============================================================================
// Fake TokenStore
// =============================================================================

class FakeTokenStore extends Fake implements TokenStore {
  AuthToken? savedToken;
  bool clearCalled = false;

  @override
  Future<void> save(AuthToken token) async {
    savedToken = token;
  }

  @override
  Future<void> clear() async {
    clearCalled = true;
    savedToken = null;
  }

  @override
  Future<AuthToken?> load() async => savedToken;

  @override
  Future<bool> isValid() async {
    if (savedToken == null) return false;
    return !savedToken!.isExpired;
  }
}

// =============================================================================
// Fake FirebaseAuth
// =============================================================================

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? fakeCurrentUser;

  @override
  User? get currentUser => fakeCurrentUser;
}

// =============================================================================
// Fake Firebase User / UserCredential helpers
// =============================================================================

/// Minimal fake [User] that exposes the fields [AuthRepository] reads.
class _FakeFirebaseUser extends Fake implements User {
  final AppUser _appUser;
  final AuthToken _token;

  _FakeFirebaseUser(this._appUser, this._token);

  @override
  String get uid => _appUser.uid;

  @override
  String? get email => _appUser.email;

  @override
  String? get phoneNumber => _appUser.phoneNumber;

  @override
  String? get displayName => _appUser.displayName;

  @override
  bool get emailVerified => _appUser.isVerified;

  @override
  String? get refreshToken => _token.refreshToken;

  @override
  UserMetadata get metadata =>
      _FakeUserMetadata(DateTime(2024, 1, 1));

  @override
  List<UserInfo> get providerData => const [];

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      _token.accessToken;
}

class _FakeUserMetadata extends Fake implements UserMetadata {
  final DateTime _creationTime;
  _FakeUserMetadata(this._creationTime);

  @override
  DateTime? get creationTime => _creationTime;
}

class _FakeUserCredential extends Fake implements UserCredential {
  final AppUser _appUser;
  final AuthToken _token;

  _FakeUserCredential(this._appUser, this._token);

  @override
  User? get user => _FakeFirebaseUser(_appUser, _token);
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepository repository;
  late FakeFirebaseAuthDataSource fakeDataSource;
  late FakeTokenStore fakeTokenStore;
  late FakeFirebaseAuth fakeFirebaseAuth;

  setUp(() {
    fakeDataSource = FakeFirebaseAuthDataSource();
    fakeTokenStore = FakeTokenStore();
    fakeFirebaseAuth = FakeFirebaseAuth();
    repository = AuthRepository(
      dataSource: fakeDataSource,
      tokenStore: fakeTokenStore,
      firebaseAuth: fakeFirebaseAuth,
    );
  });

  group('AuthRepository', () {
    // -------------------------------------------------------------------------
    // 1. signUpWithEmail — success
    // -------------------------------------------------------------------------

    group('signUpWithEmail', () {
      test('returns correct user and token on success', () async {
        final result = await repository.signUpWithEmail(
          email: 'alice@example.com',
          password: 'P@ssw0rd!',
          displayName: 'Alice',
        );

        expect(result.user.uid, equals(fakeDataSource.returnUser.uid));
        expect(result.user.email, equals(fakeDataSource.returnUser.email));
        expect(result.token.accessToken,
            equals(fakeDataSource.returnToken.accessToken));
      });

      test('saves token to TokenStore', () async {
        await repository.signUpWithEmail(
          email: 'alice@example.com',
          password: 'P@ssw0rd!',
          displayName: 'Alice',
        );

        expect(fakeTokenStore.savedToken, isNotNull);
        expect(fakeTokenStore.savedToken!.accessToken,
            equals(fakeDataSource.returnToken.accessToken));
      });

      test('delegates to dataSource with correct arguments', () async {
        await repository.signUpWithEmail(
          email: 'alice@example.com',
          password: 'P@ssw0rd!',
          displayName: 'Alice',
        );

        expect(fakeDataSource.lastSignUpEmail, equals('alice@example.com'));
        expect(fakeDataSource.lastSignUpPassword, equals('P@ssw0rd!'));
        expect(fakeDataSource.lastSignUpDisplayName, equals('Alice'));
      });
    });

    // -------------------------------------------------------------------------
    // 2. signInWithEmail — success
    // -------------------------------------------------------------------------

    group('signInWithEmail', () {
      test('returns correct user and token on success', () async {
        final result = await repository.signInWithEmail(
          email: 'bob@example.com',
          password: 'S3cur3!',
        );

        expect(result.user.uid, equals(fakeDataSource.returnUser.uid));
        expect(result.token.accessToken,
            equals(fakeDataSource.returnToken.accessToken));
      });

      test('saves token to TokenStore', () async {
        await repository.signInWithEmail(
          email: 'bob@example.com',
          password: 'S3cur3!',
        );

        expect(fakeTokenStore.savedToken, isNotNull);
      });

      test('delegates to dataSource with correct arguments', () async {
        await repository.signInWithEmail(
          email: 'bob@example.com',
          password: 'S3cur3!',
        );

        expect(fakeDataSource.lastSignInEmail, equals('bob@example.com'));
        expect(fakeDataSource.lastSignInPassword, equals('S3cur3!'));
      });
    });

    // -------------------------------------------------------------------------
    // 3. signInWithGoogle — success
    // -------------------------------------------------------------------------

    group('signInWithGoogle', () {
      test('returns correct user and token on success', () async {
        final result = await repository.signInWithGoogle();

        expect(result.user.uid, equals(fakeDataSource.returnUser.uid));
        expect(result.token.accessToken,
            equals(fakeDataSource.returnToken.accessToken));
      });

      test('saves token to TokenStore', () async {
        await repository.signInWithGoogle();

        expect(fakeTokenStore.savedToken, isNotNull);
      });

      test('delegates to dataSource.signInWithGoogle', () async {
        await repository.signInWithGoogle();

        expect(fakeDataSource.signInWithGoogleCalled, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 4. signInWithFacebook — success
    // -------------------------------------------------------------------------

    group('signInWithFacebook', () {
      test('returns correct user and token on success', () async {
        final result = await repository.signInWithFacebook();

        expect(result.user.uid, equals(fakeDataSource.returnUser.uid));
        expect(result.token.accessToken,
            equals(fakeDataSource.returnToken.accessToken));
      });

      test('saves token to TokenStore', () async {
        await repository.signInWithFacebook();

        expect(fakeTokenStore.savedToken, isNotNull);
      });

      test('delegates to dataSource.signInWithFacebook', () async {
        await repository.signInWithFacebook();

        expect(fakeDataSource.signInWithFacebookCalled, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 5. sendPhoneOtp — delegates to dataSource
    // -------------------------------------------------------------------------

    group('sendPhoneOtp', () {
      test('delegates to dataSource with correct phone number', () async {
        const phone = '+22670000000';
        await repository.sendPhoneOtp(phoneNumber: phone);

        expect(fakeDataSource.lastSendPhoneOtpNumber, equals(phone));
      });

      test('returns the OtpRequest from dataSource', () async {
        final result =
            await repository.sendPhoneOtp(phoneNumber: '+22670000000');

        expect(result.verificationId,
            equals(fakeDataSource.returnOtpRequest.verificationId));
        expect(result.channel, equals('sms'));
      });
    });

    // -------------------------------------------------------------------------
    // 6. verifyPhoneOtp — success
    // -------------------------------------------------------------------------

    group('verifyPhoneOtp', () {
      test('returns correct user and token on success', () async {
        final otpRequest = _fakeOtpRequest();
        final result = await repository.verifyPhoneOtp(
          otpRequest: otpRequest,
          otp: '123456',
        );

        expect(result.user.uid, equals(fakeDataSource.returnUser.uid));
        expect(result.token.accessToken,
            equals(fakeDataSource.returnToken.accessToken));
      });

      test('saves token to TokenStore', () async {
        await repository.verifyPhoneOtp(
          otpRequest: _fakeOtpRequest(),
          otp: '123456',
        );

        expect(fakeTokenStore.savedToken, isNotNull);
      });

      test('delegates to dataSource with correct otpRequest and smsCode',
          () async {
        final otpRequest = _fakeOtpRequest();
        await repository.verifyPhoneOtp(
          otpRequest: otpRequest,
          otp: '654321',
        );

        expect(fakeDataSource.lastVerifyOtpRequest, equals(otpRequest));
        expect(fakeDataSource.lastVerifySmsCode, equals('654321'));
      });
    });

    // -------------------------------------------------------------------------
    // 7. signOut — clears token store
    // -------------------------------------------------------------------------

    group('signOut', () {
      test('calls dataSource.signOut', () async {
        await repository.signOut();

        expect(fakeDataSource.signOutCalled, isTrue);
      });

      test('calls tokenStore.clear', () async {
        // Pre-populate the store so we can verify it gets cleared.
        await fakeTokenStore.save(_fakeToken());

        await repository.signOut();

        expect(fakeTokenStore.clearCalled, isTrue);
        expect(fakeTokenStore.savedToken, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // 8. getCurrentUser — returns null when no Firebase user
    // -------------------------------------------------------------------------

    group('getCurrentUser', () {
      test('returns null when FirebaseAuth.currentUser is null', () async {
        fakeFirebaseAuth.fakeCurrentUser = null;

        final result = await repository.getCurrentUser();

        expect(result, isNull);
      });

      // -----------------------------------------------------------------------
      // 9. getCurrentUser — returns AppUser when Firebase user exists
      // -----------------------------------------------------------------------

      test('returns AppUser when FirebaseAuth.currentUser is set', () async {
        final fakeUser = _fakeUser();
        final fakeToken = _fakeToken();
        fakeFirebaseAuth.fakeCurrentUser =
            _FakeFirebaseUser(fakeUser, fakeToken);

        final result = await repository.getCurrentUser();

        expect(result, isNotNull);
        expect(result!.uid, equals(fakeUser.uid));
        expect(result.email, equals(fakeUser.email));
      });
    });

    // -------------------------------------------------------------------------
    // 10. sendPasswordResetEmail — delegates to dataSource
    // -------------------------------------------------------------------------

    group('sendPasswordResetEmail', () {
      test('delegates to dataSource with correct email', () async {
        const email = 'reset@example.com';
        await repository.sendPasswordResetEmail(email: email);

        expect(fakeDataSource.lastPasswordResetEmail, equals(email));
      });
    });

    // -------------------------------------------------------------------------
    // 11. changePassword — throws when no current user
    // -------------------------------------------------------------------------

    group('changePassword', () {
      test('throws FirebaseAuthException when no current user', () async {
        fakeFirebaseAuth.fakeCurrentUser = null;

        expect(
          () => repository.changePassword(
            currentPassword: 'OldPass1!',
            newPassword: 'NewPass1!',
          ),
          throwsA(
            isA<FirebaseAuthException>().having(
              (e) => e.code,
              'code',
              'no-current-user',
            ),
          ),
        );
      });
    });
  });
}
