// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_prefs_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationPrefsNotifierHash() =>
    r'd5c58b5ac362f54a8a5c5eb4e4182c4553955753';

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
///
/// Copied from [NotificationPrefsNotifier].
@ProviderFor(NotificationPrefsNotifier)
final notificationPrefsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      NotificationPrefsNotifier,
      NotificationPreference?
    >.internal(
      NotificationPrefsNotifier.new,
      name: r'notificationPrefsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationPrefsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationPrefsNotifier =
    AutoDisposeAsyncNotifier<NotificationPreference?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
