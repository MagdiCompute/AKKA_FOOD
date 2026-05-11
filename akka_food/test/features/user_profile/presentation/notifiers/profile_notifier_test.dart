import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/data/repositories/profile_repository.dart'
    show kDefaultAvatarUrl;
import 'package:akka_food/features/user_profile/domain/entities/notification_preference.dart';
import 'package:akka_food/features/user_profile/domain/entities/user_profile.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_profile_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/profile_notifier.dart';

// =============================================================================
// Test fixtures
// =============================================================================

final _fakeUser = AppUser(
  uid: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
  isVerified: true,
  isDeactivated: false,
  createdAt: DateTime(2024, 1, 1),
  linkedProviders: const ['password'],
);

UserProfile _fakeProfile({String? displayName, String? avatarUrl}) {
  return UserProfile(
    uid: 'test-uid',
    displayName: displayName ?? 'Test User',
    email: 'test@example.com',
    phoneNumber: '+22670000000',
    avatarUrl: avatarUrl,
    updatedAt: DateTime(2024, 6, 1),
  );
}

// =============================================================================
// FakeProfileRepository
// =============================================================================

class FakeProfileRepository implements IProfileRepository {
  UserProfile? returnProfile;
  NotificationPreference? returnPrefs;

  bool throwOnGetProfile = false;
  bool throwOnUpdateProfile = false;
  bool throwOnUploadAvatar = false;
  bool throwOnRemoveAvatar = false;
  bool throwOnGetNotificationPrefs = false;
  bool throwOnUpdateNotificationPrefs = false;

  String? lastUploadedAvatarUid;
  String? lastRemovedAvatarUid;
  UserProfile? lastUpdatedProfile;
  NotificationPreference? lastUpdatedPrefs;

  @override
  Future<UserProfile> getProfile(String uid) async {
    if (throwOnGetProfile) throw Exception('getProfile failed');
    return returnProfile ?? _fakeProfile();
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    if (throwOnUpdateProfile) throw Exception('updateProfile failed');
    lastUpdatedProfile = profile;
    return profile;
  }

  @override
  Future<String> uploadAvatar(String uid, dynamic imageFile) async {
    if (throwOnUploadAvatar) throw Exception('uploadAvatar failed');
    lastUploadedAvatarUid = uid;
    return 'https://example.com/avatar.jpg';
  }

  @override
  Future<void> removeAvatar(String uid) async {
    if (throwOnRemoveAvatar) throw Exception('removeAvatar failed');
    lastRemovedAvatarUid = uid;
  }

  @override
  Future<NotificationPreference> getNotificationPrefs(String uid) async {
    if (throwOnGetNotificationPrefs) throw Exception('getNotificationPrefs failed');
    return returnPrefs ?? NotificationPreference(uid: uid);
  }

  @override
  Future<void> updateNotificationPrefs(NotificationPreference prefs) async {
    if (throwOnUpdateNotificationPrefs) throw Exception('updateNotificationPrefs failed');
    lastUpdatedPrefs = prefs;
  }

  @override
  Stream<UserProfile> watchProfile(String uid) {
    if (throwOnGetProfile) throw Exception('watchProfile failed');
    return Stream.value(returnProfile ?? _fakeProfile());
  }
}

// =============================================================================
// Helpers
// =============================================================================

ProviderContainer _makeContainer({
  AppUser? user,
  FakeProfileRepository? repo,
}) {
  final fakeRepo = repo ?? FakeProfileRepository();
  return ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith((ref) => user ?? _fakeUser),
      profileRepositoryProvider.overrideWith((_) async => fakeRepo),
    ],
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('ProfileNotifier', () {
    // -------------------------------------------------------------------------
    // build()
    // -------------------------------------------------------------------------

    group('build()', () {
      test('returns profile from repository when user is signed in', () async {
        final profile = _fakeProfile(displayName: 'Alice');
        final repo = FakeProfileRepository()..returnProfile = profile;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(profileNotifierProvider.future);

        expect(result, isNotNull);
        expect(result!.displayName, equals('Alice'));
        expect(result.uid, equals('test-uid'));
      });

      test('returns null when no user is signed in', () async {
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            profileRepositoryProvider.overrideWith(
              (_) async => FakeProfileRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(profileNotifierProvider.future);

        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // updateProfile()
    // -------------------------------------------------------------------------

    group('updateProfile()', () {
      test('updates state with new profile on success', () async {
        final repo = FakeProfileRepository()
          ..returnProfile = _fakeProfile(displayName: 'Original');
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);

        await container
            .read(profileNotifierProvider.notifier)
            .updateProfile('Updated Name', email: 'new@example.com');

        final state = container.read(profileNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!.displayName, equals('Updated Name'));
        expect(state.value!.email, equals('new@example.com'));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final repo = FakeProfileRepository()
          ..returnProfile = _fakeProfile(displayName: 'Original')
          ..throwOnUpdateProfile = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);

        await container
            .read(profileNotifierProvider.notifier)
            .updateProfile('New Name');

        final state = container.read(profileNotifierProvider);
        expect(state.hasError, isTrue);
        // Previous value is preserved via copyWithPrevious
        expect(state.valueOrNull, isNotNull);
        expect(state.valueOrNull!.displayName, equals('Original'));
      });

      test('state goes through loading before settling', () async {
        final repo = FakeProfileRepository()
          ..returnProfile = _fakeProfile();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);

        final states = <AsyncValue<UserProfile?>>[];
        final sub = container.listen(
          profileNotifierProvider,
          (_, next) => states.add(next),
        );

        await container
            .read(profileNotifierProvider.notifier)
            .updateProfile('New Name');

        sub.close();

        expect(states.any((s) => s.isLoading), isTrue);
        expect(states.last.hasValue, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // uploadAvatar()
    // -------------------------------------------------------------------------

    group('uploadAvatar()', () {
      test('updates avatarUrl in state on success', () async {
        final repo = FakeProfileRepository()
          ..returnProfile = _fakeProfile(avatarUrl: null);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);

        // Use a temp file path — the fake repo doesn't actually read it
        final fakeFile = File('fake_avatar.jpg');
        await container
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(fakeFile);

        final state = container.read(profileNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(repo.lastUploadedAvatarUid, equals('test-uid'));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final repo = FakeProfileRepository()
          ..returnProfile = _fakeProfile(avatarUrl: 'https://old.com/avatar.jpg')
          ..throwOnUploadAvatar = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);

        final fakeFile = File('fake_avatar.jpg');
        await container
            .read(profileNotifierProvider.notifier)
            .uploadAvatar(fakeFile);

        final state = container.read(profileNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!.avatarUrl, equals('https://old.com/avatar.jpg'));
      });
    });

    // -------------------------------------------------------------------------
    // removeAvatar()
    // -------------------------------------------------------------------------

    group('removeAvatar()', () {
      test('resets avatarUrl to default placeholder on success', () async {
        final repo = FakeProfileRepository()
          ..returnProfile =
              _fakeProfile(avatarUrl: 'https://example.com/old.jpg');
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);

        await container
            .read(profileNotifierProvider.notifier)
            .removeAvatar();

        final state = container.read(profileNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!.avatarUrl, equals(kDefaultAvatarUrl));
        expect(repo.lastRemovedAvatarUid, equals('test-uid'));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final repo = FakeProfileRepository()
          ..returnProfile =
              _fakeProfile(avatarUrl: 'https://example.com/old.jpg')
          ..throwOnRemoveAvatar = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(profileNotifierProvider.future);

        await container
            .read(profileNotifierProvider.notifier)
            .removeAvatar();

        final state = container.read(profileNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!.avatarUrl,
            equals('https://example.com/old.jpg'));
      });
    });
  });
}
