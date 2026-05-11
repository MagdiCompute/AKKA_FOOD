import 'dart:io';

import '../../data/datasources/firebase_storage_data_source.dart';
import '../../data/datasources/firestore_profile_data_source.dart';
import '../../data/datasources/hive_profile_cache.dart';
import '../../data/datasources/image_compression_service.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_profile_repository.dart';

// ---------------------------------------------------------------------------
// Storage abstraction (for testability)
// ---------------------------------------------------------------------------

/// Thin interface over the avatar-related Storage operations used by
/// [ProfileRepository].
///
/// Extracted so tests can supply a pure-Dart fake without needing a live
/// [FirebaseStorage] instance.
abstract class AvatarStorageClient {
  Future<String> uploadAvatar(String uid, File imageFile);
  Future<void> deleteAvatar(String avatarUrl);
}

/// Production adapter that delegates to [FirebaseStorageDataSource].
class FirebaseAvatarStorageClient implements AvatarStorageClient {
  FirebaseAvatarStorageClient(this._source);

  final FirebaseStorageDataSource _source;

  @override
  Future<String> uploadAvatar(String uid, File imageFile) =>
      _source.uploadAvatar(uid, imageFile);

  @override
  Future<void> deleteAvatar(String avatarUrl) =>
      _source.deleteAvatar(avatarUrl);
}

/// Default avatar placeholder URL used when a user removes their avatar.
///
/// Points to a publicly accessible generic silhouette image. Replace with
/// the project's own hosted asset URL before shipping to production.
const String kDefaultAvatarUrl =
    'https://storage.googleapis.com/akka-food.appspot.com/avatars/default/placeholder.png';

/// Concrete implementation of [IProfileRepository].
///
/// Orchestrates:
/// - [FirestoreProfileDataSource] — profile reads/writes in Firestore
/// - [HiveProfileCache] — local 5-minute TTL cache
/// - [AvatarStorageClient] — avatar upload and deletion in Storage
/// - [ImageCompressionService] — compresses images before upload
///
/// Cache strategy (Requirement 1.3):
/// - [getProfile]: return fresh cache if within TTL; otherwise fetch from
///   Firestore, write to cache, and return. On Firestore error, fall back to
///   stale cache; throw [SocketException] if cache is also empty.
///
/// Avatar upload flow (Requirement 3, design §Avatar Upload Flow):
/// 1. Read current profile to capture the existing [avatarUrl].
/// 2. Compress the image (max 800×800 px, JPEG 85 %).
/// 3. Validate and upload the compressed file to Storage.
/// 4. Update `/users/{uid}.avatarUrl` in Firestore.
/// 5. Delete the previous avatar from Storage (if it was a real upload, not
///    a placeholder or null).
/// 6. Delete the temporary compressed file.
///
/// Requirement 3.4 — delete orphaned avatar on update.
/// Requirement 3.5 — set placeholder URL on avatar removal.
class ProfileRepository implements IProfileRepository {
  ProfileRepository({
    required FirestoreProfileDataSource firestoreDataSource,
    required AvatarStorageClient storageClient,
    required ImageCompressionService compressionService,
    required HiveProfileCache cache,
  })  : _firestoreDataSource = firestoreDataSource,
        _storageClient = storageClient,
        _compressionService = compressionService,
        _cache = cache;

  final FirestoreProfileDataSource _firestoreDataSource;
  final AvatarStorageClient _storageClient;
  final ImageCompressionService _compressionService;
  final HiveProfileCache _cache;

  // ---------------------------------------------------------------------------
  // IProfileRepository — profile
  // ---------------------------------------------------------------------------

  /// Returns the [UserProfile] for [uid].
  ///
  /// Cache-first strategy:
  /// 1. If the cache entry is fresh (within [HiveProfileCache.cacheTtl]),
  ///    return it immediately.
  /// 2. Otherwise fetch from Firestore, write to cache, and return.
  /// 3. On Firestore error, fall back to stale cache if available.
  /// 4. If both Firestore and cache are unavailable, rethrow the error.
  @override
  Future<UserProfile> getProfile(String uid) async {
    // 1. Return fresh cache hit.
    final cached = _cache.getProfile(uid);
    if (cached != null) return cached;

    // 2. Fetch from Firestore.
    try {
      final profile = await _firestoreDataSource.getProfile(uid);
      await _cache.saveProfile(profile);
      return profile;
    } catch (e) {
      // 3. Network error — fall back to stale cache.
      final stale = _cache.getProfileStale(uid);
      if (stale != null) return stale;
      // 4. Nothing in cache either — rethrow.
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final updated = await _firestoreDataSource.updateProfile(profile);
    // Invalidate / refresh the cache with the latest data.
    await _cache.saveProfile(updated);
    return updated;
  }

  // ---------------------------------------------------------------------------
  // IProfileRepository — avatar
  // ---------------------------------------------------------------------------

  /// Uploads a new avatar for [uid] and returns the public download URL.
  ///
  /// Steps:
  /// 1. Fetch the current profile to capture the old [avatarUrl].
  /// 2. Compress [imageFile] via [ImageCompressionService].
  /// 3. Upload the compressed file via [FirebaseStorageDataSource].
  /// 4. Persist the new URL to Firestore.
  /// 5. Delete the old avatar from Storage (skipped when the old URL is
  ///    `null`, empty, or equal to [kDefaultAvatarUrl]).
  /// 6. Clean up the temporary compressed file.
  ///
  /// Throws [AvatarFileTooLargeException] if the file exceeds 5 MB.
  /// Throws [AvatarUnsupportedFormatException] if the format is not JPEG/PNG.
  /// Throws [ImageCompressionException] if compression fails.
  /// Throws [FirebaseException] on Storage or Firestore errors.
  @override
  Future<String> uploadAvatar(String uid, dynamic imageFile) async {
    final file = imageFile as File;

    // 1. Capture the existing avatar URL before overwriting it.
    final currentProfile = await _firestoreDataSource.getProfile(uid);
    final oldAvatarUrl = currentProfile.avatarUrl;

    // 2. Compress the image.
    final compressedFile = await _compressionService.compressAvatar(file);

    String newAvatarUrl;
    try {
      // 3. Upload the compressed image and get the download URL.
      newAvatarUrl = await _storageClient.uploadAvatar(uid, compressedFile);

      // 4. Persist the new avatar URL in Firestore.
      final updatedProfile =
          currentProfile.copyWith(avatarUrl: newAvatarUrl);
      await _firestoreDataSource.updateProfile(updatedProfile);

      // Refresh cache with updated profile.
      await _cache.saveProfile(updatedProfile.copyWith(updatedAt: DateTime.now()));

      // 5. Delete the previous avatar from Storage (Requirement 3.4).
      //    Skip if there was no previous avatar or it was the placeholder.
      if (_isDeletableAvatarUrl(oldAvatarUrl)) {
        await _storageClient.deleteAvatar(oldAvatarUrl!);
      }
    } finally {
      // 6. Always clean up the temporary compressed file.
      try {
        if (await compressedFile.exists()) {
          await compressedFile.delete();
        }
      } catch (_) {
        // Temp-file cleanup failure is non-fatal; swallow silently.
      }
    }

    return newAvatarUrl;
  }

  /// Removes the current avatar for [uid] and sets the avatar URL to
  /// [kDefaultAvatarUrl] (Requirement 3.5).
  ///
  /// The existing avatar file in Storage is deleted if it is a real upload
  /// (not null, empty, or already the placeholder URL).
  ///
  /// Throws [FirebaseException] on Storage or Firestore errors.
  @override
  Future<void> removeAvatar(String uid) async {
    final currentProfile = await _firestoreDataSource.getProfile(uid);
    final oldAvatarUrl = currentProfile.avatarUrl;

    // Persist the placeholder URL in Firestore.
    final updatedProfile = currentProfile.copyWith(avatarUrl: kDefaultAvatarUrl);
    await _firestoreDataSource.updateProfile(updatedProfile);

    // Refresh cache.
    await _cache.saveProfile(updatedProfile.copyWith(updatedAt: DateTime.now()));

    // Delete the old avatar from Storage if it was a real upload.
    if (_isDeletableAvatarUrl(oldAvatarUrl)) {
      await _storageClient.deleteAvatar(oldAvatarUrl!);
    }
  }

  // ---------------------------------------------------------------------------
  // IProfileRepository — notification preferences
  // ---------------------------------------------------------------------------

  @override
  Future<NotificationPreference> getNotificationPrefs(String uid) =>
      _firestoreDataSource.getNotificationPrefs(uid);

  @override
  Future<void> updateNotificationPrefs(NotificationPreference prefs) =>
      _firestoreDataSource.updateNotificationPrefs(prefs);

  // ---------------------------------------------------------------------------
  // IProfileRepository — SWR stream
  // ---------------------------------------------------------------------------

  /// Returns a stale-while-revalidate stream of [UserProfile] for [uid].
  ///
  /// 1. If a cached entry exists (even stale), it is emitted immediately.
  /// 2. Fresh data is fetched from Firestore in the background and emitted
  ///    once available; the cache is updated with the fresh data.
  /// 3. On network error:
  ///    - If stale data was emitted, the stream completes silently (the caller
  ///      should display a connectivity banner).
  ///    - If no cached data was available, the error is rethrown so the caller
  ///      can surface an appropriate error state.
  @override
  Stream<UserProfile> watchProfile(String uid) async* {
    // 1. Emit stale cache immediately if available.
    final stale = _cache.getProfileStale(uid);
    if (stale != null) yield stale;

    // 2. Fetch fresh data from Firestore.
    try {
      final fresh = await _firestoreDataSource.getProfile(uid);
      await _cache.saveProfile(fresh);
      yield fresh;
    } catch (e) {
      // 3. If we already emitted stale data, complete silently so the caller
      //    can show a connectivity banner. Otherwise rethrow.
      if (stale == null) rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when [url] refers to a real previously-uploaded avatar
  /// that should be deleted from Storage.
  ///
  /// Returns `false` when [url] is:
  /// - `null` — no avatar was ever set.
  /// - empty — treated the same as null.
  /// - equal to [kDefaultAvatarUrl] — already the placeholder; nothing to
  ///   delete.
  bool _isDeletableAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url == kDefaultAvatarUrl) return false;
    return true;
  }
}
