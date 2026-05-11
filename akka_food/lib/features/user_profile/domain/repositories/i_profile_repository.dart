import '../entities/notification_preference.dart';
import '../entities/user_profile.dart';

/// Abstract repository interface for user profile operations.
///
/// Pure Dart — zero Flutter or Firebase imports.
/// Implementations live in the data layer.
abstract class IProfileRepository {
  /// Fetches the [UserProfile] for the given [uid].
  ///
  /// Returns cached data when the network is unavailable.
  /// Throws if the profile cannot be found or the caller is unauthorised.
  Future<UserProfile> getProfile(String uid);

  /// Persists the supplied [profile] and returns the updated [UserProfile].
  ///
  /// Throws on validation failure or network error.
  Future<UserProfile> updateProfile(UserProfile profile);

  /// Uploads an avatar image for [uid] and returns the public download URL.
  ///
  /// [imageFile] is typed as [dynamic] so the domain layer stays free of
  /// Flutter's `dart:io` / `File` dependency; the data layer casts it
  /// to the concrete type it expects (e.g. `File` or `XFile`).
  ///
  /// Throws if the file exceeds 5 MB, is not JPEG/PNG, or the upload fails.
  Future<String> uploadAvatar(String uid, dynamic imageFile);

  /// Removes the current avatar for [uid] and resets the avatar URL to the
  /// default placeholder.
  ///
  /// Throws on network error.
  Future<void> removeAvatar(String uid);

  /// Fetches the [NotificationPreference] record for [uid].
  ///
  /// Returns default preferences (all enabled) if no record exists yet.
  Future<NotificationPreference> getNotificationPrefs(String uid);

  /// Persists the supplied [prefs] for the user identified by [prefs.uid].
  ///
  /// Throws on network error.
  Future<void> updateNotificationPrefs(NotificationPreference prefs);

  /// Returns a stale-while-revalidate stream of [UserProfile] for [uid].
  ///
  /// Emits the cached profile immediately (if available), then fetches fresh
  /// data from Firestore in the background and emits the updated profile.
  ///
  /// On network error:
  /// - If cached data was emitted, the stream completes silently (caller
  ///   should display a connectivity banner).
  /// - If no cached data was available, the stream emits an error.
  Stream<UserProfile> watchProfile(String uid);
}
