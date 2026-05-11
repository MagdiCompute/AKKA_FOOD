import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../../domain/entities/notification_preference.dart';
import 'profile_notifier.dart';

part 'notification_prefs_notifier.g.dart';

// ---------------------------------------------------------------------------
// NotificationPrefsNotifier
// ---------------------------------------------------------------------------

/// Manages the [NotificationPreference] state for the UI layer.
///
/// Loads notification preferences for the current user on build, and exposes
/// mutation methods for each individual toggle as well as a bulk update.
///
/// Uses [profileRepositoryProvider] for all Firestore reads/writes and
/// [currentUserProvider] to identify the authenticated user.
///
/// Returns `null` when no user is signed in.
///
/// Satisfies Requirements 7.1, 7.2, 7.3, 7.4.
@riverpod
class NotificationPrefsNotifier extends _$NotificationPrefsNotifier {
  // ---------------------------------------------------------------------------
  // build — load preferences
  // ---------------------------------------------------------------------------

  /// Loads the notification preferences for the current user.
  ///
  /// Returns `null` when no user is signed in.
  @override
  Future<NotificationPreference?> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return null;

    final repository = await ref.watch(profileRepositoryProvider.future);
    return repository.getNotificationPrefs(currentUser.uid);
  }

  // ---------------------------------------------------------------------------
  // updateOrderUpdates
  // ---------------------------------------------------------------------------

  /// Toggles the [NotificationPreference.orderUpdates] preference to [value].
  ///
  /// Preserves the previous state on error.
  ///
  /// Satisfies Requirement 7.2.
  Future<void> updateOrderUpdates(bool value) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError(
          'Cannot update notification prefs: no authenticated user.');
    }

    final repository = await ref.read(profileRepositoryProvider.future);
    final previous = state;

    final currentPrefs = state.valueOrNull ??
        NotificationPreference(uid: currentUser.uid);
    final updated = currentPrefs.copyWith(orderUpdates: value);

    state =
        const AsyncLoading<NotificationPreference?>().copyWithPrevious(previous);

    try {
      await repository.updateNotificationPrefs(updated);
      state = AsyncData(updated);
    } catch (e, st) {
      state =
          AsyncError<NotificationPreference?>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // updatePromotions
  // ---------------------------------------------------------------------------

  /// Toggles the [NotificationPreference.promotions] preference to [value].
  ///
  /// Preserves the previous state on error.
  ///
  /// Satisfies Requirement 7.2.
  Future<void> updatePromotions(bool value) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError(
          'Cannot update notification prefs: no authenticated user.');
    }

    final repository = await ref.read(profileRepositoryProvider.future);
    final previous = state;

    final currentPrefs = state.valueOrNull ??
        NotificationPreference(uid: currentUser.uid);
    final updated = currentPrefs.copyWith(promotions: value);

    state =
        const AsyncLoading<NotificationPreference?>().copyWithPrevious(previous);

    try {
      await repository.updateNotificationPrefs(updated);
      state = AsyncData(updated);
    } catch (e, st) {
      state =
          AsyncError<NotificationPreference?>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // updateCoinEvents
  // ---------------------------------------------------------------------------

  /// Toggles the [NotificationPreference.coinEvents] preference to [value].
  ///
  /// Preserves the previous state on error.
  ///
  /// Satisfies Requirement 7.2.
  Future<void> updateCoinEvents(bool value) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError(
          'Cannot update notification prefs: no authenticated user.');
    }

    final repository = await ref.read(profileRepositoryProvider.future);
    final previous = state;

    final currentPrefs = state.valueOrNull ??
        NotificationPreference(uid: currentUser.uid);
    final updated = currentPrefs.copyWith(coinEvents: value);

    state =
        const AsyncLoading<NotificationPreference?>().copyWithPrevious(previous);

    try {
      await repository.updateNotificationPrefs(updated);
      state = AsyncData(updated);
    } catch (e, st) {
      state =
          AsyncError<NotificationPreference?>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // updatePrefs
  // ---------------------------------------------------------------------------

  /// Persists all notification preferences at once from the supplied [prefs].
  ///
  /// Preserves the previous state on error.
  ///
  /// Satisfies Requirements 7.1, 7.2, 7.3.
  Future<void> updatePrefs(NotificationPreference prefs) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError(
          'Cannot update notification prefs: no authenticated user.');
    }

    final repository = await ref.read(profileRepositoryProvider.future);
    final previous = state;

    state =
        const AsyncLoading<NotificationPreference?>().copyWithPrevious(previous);

    try {
      await repository.updateNotificationPrefs(prefs);
      state = AsyncData(prefs);
    } catch (e, st) {
      state =
          AsyncError<NotificationPreference?>(e, st).copyWithPrevious(previous);
    }
  }
}
