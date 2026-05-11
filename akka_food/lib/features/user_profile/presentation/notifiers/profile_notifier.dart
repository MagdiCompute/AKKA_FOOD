import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../../data/datasources/firebase_storage_data_source.dart';
import '../../data/datasources/firestore_profile_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../data/datasources/image_compression_service.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_profile_repository.dart';

part 'profile_notifier.g.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the concrete [ProfileRepository] bound to [IProfileRepository].
///
/// Wires up all data-layer dependencies:
/// - [FirestoreProfileDataSource] — Firestore reads/writes
/// - [FirebaseAvatarStorageClient] wrapping [FirebaseStorageDataSource] — Storage
/// - [ImageCompressionService] — avatar compression
/// - [HiveProfileCache] — local 5-minute TTL cache
///
/// Override in tests via `ProviderScope(overrides: [...])`.
@riverpod
Future<IProfileRepository> profileRepository(Ref ref) async {
  final cache = await HiveProfileCache.open();
  return ProfileRepository(
    firestoreDataSource: FirestoreProfileDataSource(),
    storageClient: FirebaseAvatarStorageClient(FirebaseStorageDataSource()),
    compressionService: ImageCompressionService(),
    cache: cache,
  );
}

// ---------------------------------------------------------------------------
// ProfileNotifier
// ---------------------------------------------------------------------------

/// Manages the [UserProfile] state for the UI layer.
///
/// Uses the stale-while-revalidate (SWR) pattern via
/// [IProfileRepository.watchProfile]: the cached profile is emitted
/// immediately, then fresh Firestore data is fetched in the background.
///
/// Exposes mutation methods:
/// - [updateProfile] — persists display name, email, and phone changes
/// - [uploadAvatar] — compresses, uploads, and links a new avatar image
/// - [removeAvatar] — resets the avatar URL to the default placeholder
///
/// The notifier throws [StateError] when called without an authenticated user.
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  // ---------------------------------------------------------------------------
  // build — SWR stream
  // ---------------------------------------------------------------------------

  /// Initialises the notifier by subscribing to the SWR profile stream.
  ///
  /// Returns `null` when no user is signed in.
  @override
  Future<UserProfile?> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return null;

    final repository = await ref.watch(profileRepositoryProvider.future);

    // Collect the SWR stream into a single Future that resolves to the
    // latest emitted value (fresh data after stale-while-revalidate).
    UserProfile? latest;
    await for (final profile in repository.watchProfile(currentUser.uid)) {
      latest = profile;
      // Update state with each emission so the UI reflects stale data
      // immediately while fresh data loads.
      state = AsyncData(profile);
    }
    return latest;
  }

  // ---------------------------------------------------------------------------
  // updateProfile
  // ---------------------------------------------------------------------------

  /// Persists a profile update with the given [displayName], [email], and
  /// [phone] values.
  ///
  /// Updates the notifier state optimistically on success.
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirements 2.1, 2.2, 2.8.
  Future<void> updateProfile(
    String displayName, {
    String? email,
    String? phone,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError('Cannot update profile: no authenticated user.');
    }

    final repository = await ref.read(profileRepositoryProvider.future);

    // Capture the previous value for error recovery.
    final previous = state;

    // Build the updated profile from the current state.
    final currentProfile = state.valueOrNull;
    final profileToUpdate = (currentProfile ??
            UserProfile(
              uid: currentUser.uid,
              displayName: displayName,
              updatedAt: DateTime.now(),
            ))
        .copyWith(
      displayName: displayName,
      email: email ?? currentProfile?.email,
      phoneNumber: phone ?? currentProfile?.phoneNumber,
    );

    state = const AsyncLoading<UserProfile?>().copyWithPrevious(previous);

    try {
      final updated = await repository.updateProfile(profileToUpdate);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError<UserProfile?>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // uploadAvatar
  // ---------------------------------------------------------------------------

  /// Compresses [imageFile], uploads it to Firebase Storage, and updates the
  /// profile's [UserProfile.avatarUrl].
  ///
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirements 3.1, 3.2, 3.3, 3.4.
  Future<void> uploadAvatar(File imageFile) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError('Cannot upload avatar: no authenticated user.');
    }

    final repository = await ref.read(profileRepositoryProvider.future);

    final previous = state;
    state = const AsyncLoading<UserProfile?>().copyWithPrevious(previous);

    try {
      final newAvatarUrl =
          await repository.uploadAvatar(currentUser.uid, imageFile);

      // Reflect the new avatar URL in the current state.
      final currentProfile = previous.valueOrNull;
      if (currentProfile != null) {
        state = AsyncData(currentProfile.copyWith(avatarUrl: newAvatarUrl));
      } else {
        // Re-fetch the full profile if we had no prior state.
        final refreshed = await repository.getProfile(currentUser.uid);
        state = AsyncData(refreshed);
      }
    } catch (e, st) {
      state = AsyncError<UserProfile?>(e, st).copyWithPrevious(previous);
    }
  }

  // ---------------------------------------------------------------------------
  // removeAvatar
  // ---------------------------------------------------------------------------

  /// Removes the current avatar and resets the avatar URL to the default
  /// placeholder.
  ///
  /// Sets an [AsyncError] state on failure while preserving the previous value.
  ///
  /// Satisfies Requirement 3.5.
  Future<void> removeAvatar() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      throw StateError('Cannot remove avatar: no authenticated user.');
    }

    final repository = await ref.read(profileRepositoryProvider.future);

    final previous = state;
    state = const AsyncLoading<UserProfile?>().copyWithPrevious(previous);

    try {
      await repository.removeAvatar(currentUser.uid);

      // Reflect the placeholder URL in the current state.
      final currentProfile = previous.valueOrNull;
      if (currentProfile != null) {
        state = AsyncData(
          currentProfile.copyWith(avatarUrl: kDefaultAvatarUrl),
        );
      } else {
        final refreshed = await repository.getProfile(currentUser.uid);
        state = AsyncData(refreshed);
      }
    } catch (e, st) {
      state = AsyncError<UserProfile?>(e, st).copyWithPrevious(previous);
    }
  }
}
