import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akka_food/features/auth/domain/entities/app_user.dart';
import 'package:akka_food/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:akka_food/features/user_profile/domain/entities/notification_preference.dart';
import 'package:akka_food/features/user_profile/domain/entities/user_profile.dart';
import 'package:akka_food/features/user_profile/domain/repositories/i_profile_repository.dart';
import 'package:akka_food/features/user_profile/presentation/notifiers/notification_prefs_notifier.dart';
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

NotificationPreference _fakePrefs({
  bool orderUpdates = true,
  bool promotions = true,
  bool coinEvents = true,
}) {
  return NotificationPreference(
    uid: 'test-uid',
    orderUpdates: orderUpdates,
    promotions: promotions,
    coinEvents: coinEvents,
  );
}

// =============================================================================
// FakeProfileRepository (minimal — only prefs methods needed)
// =============================================================================

class FakeProfileRepository implements IProfileRepository {
  NotificationPreference? returnPrefs;

  bool throwOnGetNotificationPrefs = false;
  bool throwOnUpdateNotificationPrefs = false;

  NotificationPreference? lastUpdatedPrefs;

  @override
  Future<NotificationPreference> getNotificationPrefs(String uid) async {
    if (throwOnGetNotificationPrefs) {
      throw Exception('getNotificationPrefs failed');
    }
    return returnPrefs ?? NotificationPreference(uid: uid);
  }

  @override
  Future<void> updateNotificationPrefs(NotificationPreference prefs) async {
    if (throwOnUpdateNotificationPrefs) {
      throw Exception('updateNotificationPrefs failed');
    }
    lastUpdatedPrefs = prefs;
  }

  // Unused by NotificationPrefsNotifier — minimal stubs below
  @override
  Future<UserProfile> getProfile(String uid) async =>
      throw UnimplementedError();

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async =>
      throw UnimplementedError();

  @override
  Future<String> uploadAvatar(String uid, dynamic imageFile) async =>
      throw UnimplementedError();

  @override
  Future<void> removeAvatar(String uid) async => throw UnimplementedError();

  @override
  Stream<UserProfile> watchProfile(String uid) => throw UnimplementedError();
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  group('NotificationPrefsNotifier', () {
    // -------------------------------------------------------------------------
    // build()
    // -------------------------------------------------------------------------

    group('build()', () {
      test('returns prefs from repository when user is signed in', () async {
        final prefs = _fakePrefs(orderUpdates: true, promotions: false);
        final repo = FakeProfileRepository()..returnPrefs = prefs;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        final result =
            await container.read(notificationPrefsNotifierProvider.future);

        expect(result, isNotNull);
        expect(result!.orderUpdates, isTrue);
        expect(result.promotions, isFalse);
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

        final result =
            await container.read(notificationPrefsNotifierProvider.future);

        expect(result, isNull);
      });

      test('returns default prefs (all true) when no record exists', () async {
        // FakeProfileRepository returns default NotificationPreference when
        // returnPrefs is null — all toggles default to true per Requirement 7.4
        final repo = FakeProfileRepository(); // returnPrefs = null
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        final result =
            await container.read(notificationPrefsNotifierProvider.future);

        expect(result, isNotNull);
        expect(result!.orderUpdates, isTrue);
        expect(result.promotions, isTrue);
        expect(result.coinEvents, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // updateOrderUpdates()
    // -------------------------------------------------------------------------

    group('updateOrderUpdates()', () {
      test('updates orderUpdates toggle in state on success', () async {
        final prefs = _fakePrefs(orderUpdates: true);
        final repo = FakeProfileRepository()..returnPrefs = prefs;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updateOrderUpdates(false);

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!.orderUpdates, isFalse);
        expect(repo.lastUpdatedPrefs!.orderUpdates, isFalse);
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final prefs = _fakePrefs(orderUpdates: true);
        final repo = FakeProfileRepository()
          ..returnPrefs = prefs
          ..throwOnUpdateNotificationPrefs = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updateOrderUpdates(false);

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!.orderUpdates, isTrue); // preserved
      });

      test('state goes through loading before settling', () async {
        final repo = FakeProfileRepository()..returnPrefs = _fakePrefs();
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        final states = <AsyncValue<NotificationPreference?>>[];
        final sub = container.listen(
          notificationPrefsNotifierProvider,
          (_, next) => states.add(next),
        );

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updateOrderUpdates(false);

        sub.close();

        expect(states.any((s) => s.isLoading), isTrue);
        expect(states.last.hasValue, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // updatePromotions()
    // -------------------------------------------------------------------------

    group('updatePromotions()', () {
      test('updates promotions toggle in state on success', () async {
        final prefs = _fakePrefs(promotions: true);
        final repo = FakeProfileRepository()..returnPrefs = prefs;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updatePromotions(false);

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!.promotions, isFalse);
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final prefs = _fakePrefs(promotions: true);
        final repo = FakeProfileRepository()
          ..returnPrefs = prefs
          ..throwOnUpdateNotificationPrefs = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updatePromotions(false);

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!.promotions, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // updateCoinEvents()
    // -------------------------------------------------------------------------

    group('updateCoinEvents()', () {
      test('updates coinEvents toggle in state on success', () async {
        final prefs = _fakePrefs(coinEvents: true);
        final repo = FakeProfileRepository()..returnPrefs = prefs;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updateCoinEvents(false);

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!.coinEvents, isFalse);
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final prefs = _fakePrefs(coinEvents: true);
        final repo = FakeProfileRepository()
          ..returnPrefs = prefs
          ..throwOnUpdateNotificationPrefs = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updateCoinEvents(false);

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.valueOrNull!.coinEvents, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // updatePrefs()
    // -------------------------------------------------------------------------

    group('updatePrefs()', () {
      test('replaces all prefs in state on success', () async {
        final initial = _fakePrefs(orderUpdates: true, promotions: true, coinEvents: true);
        final repo = FakeProfileRepository()..returnPrefs = initial;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        final newPrefs = NotificationPreference(
          uid: 'test-uid',
          orderUpdates: false,
          promotions: false,
          coinEvents: false,
        );

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updatePrefs(newPrefs);

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value!.orderUpdates, isFalse);
        expect(state.value!.promotions, isFalse);
        expect(state.value!.coinEvents, isFalse);
        expect(repo.lastUpdatedPrefs, equals(newPrefs));
      });

      test('sets AsyncError state on failure while preserving previous value',
          () async {
        final initial = _fakePrefs(orderUpdates: true, promotions: true);
        final repo = FakeProfileRepository()
          ..returnPrefs = initial
          ..throwOnUpdateNotificationPrefs = true;
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _fakeUser),
            profileRepositoryProvider.overrideWith((_) async => repo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(notificationPrefsNotifierProvider.future);

        await container
            .read(notificationPrefsNotifierProvider.notifier)
            .updatePrefs(
              NotificationPreference(
                uid: 'test-uid',
                orderUpdates: false,
                promotions: false,
                coinEvents: false,
              ),
            );

        final state = container.read(notificationPrefsNotifierProvider);
        expect(state.hasError, isTrue);
        // Previous values preserved
        expect(state.valueOrNull!.orderUpdates, isTrue);
        expect(state.valueOrNull!.promotions, isTrue);
      });
    });
  });
}
