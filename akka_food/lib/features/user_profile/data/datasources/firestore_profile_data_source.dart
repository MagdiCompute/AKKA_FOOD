import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_preference.dart';
import '../../domain/entities/user_profile.dart';

/// Handles all Firestore read/write operations for the user profile feature.
///
/// Reads and writes:
/// - `/users/{uid}` — the main profile document ([UserProfile])
/// - `/users/{uid}/notificationPrefs` — notification preference sub-document
///   ([NotificationPreference])
///
/// Accepts an optional [FirebaseFirestore] instance for testability;
/// defaults to [FirebaseFirestore.instance] in production.
class FirestoreProfileDataSource {
  FirestoreProfileDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  DocumentReference<Map<String, dynamic>> _notificationPrefsDoc(String uid) =>
      _userDoc(uid).collection('notificationPrefs').doc('prefs');

  // ---------------------------------------------------------------------------
  // Profile
  // ---------------------------------------------------------------------------

  /// Reads `/users/{uid}` and returns a [UserProfile].
  ///
  /// If the document does not exist, creates a default profile from the
  /// provided [uid] and returns it. This handles the case where a user
  /// signs in via Firebase Auth but has no Firestore profile document yet.
  Future<UserProfile> getProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      // Auto-create a minimal profile document for new users.
      final now = DateTime.now();
      final defaultProfile = UserProfile(
        uid: uid,
        displayName: 'User',
        updatedAt: now,
      );
      await _userDoc(uid).set({
        'displayName': 'User',
        'email': null,
        'phoneNumber': null,
        'avatarUrl': null,
        'role': 'user',
        'coinBalance': 0,
        'isDeactivated': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return defaultProfile;
    }

    return UserProfile.fromMap({'uid': uid, ...snapshot.data()!});
  }

  /// Writes updated fields to `/users/{uid}` and returns the updated
  /// [UserProfile].
  ///
  /// Always sets `updatedAt` to [FieldValue.serverTimestamp()] so the server
  /// timestamp is authoritative. The returned [UserProfile] reflects the
  /// local write; the `updatedAt` field is set to [DateTime.now()] as a
  /// client-side approximation until the next [getProfile] call.
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final data = profile.toMap()
      ..remove('uid') // uid is the document id, not a field
      ..remove('updatedAt'); // replaced by server timestamp below

    await _userDoc(profile.uid).set(
      <String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Return the profile with a local DateTime.now() approximation for
    // updatedAt; callers that need the exact server timestamp should call
    // getProfile() after this method.
    return profile.copyWith(updatedAt: DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // Notification preferences
  // ---------------------------------------------------------------------------

  /// Reads `/users/{uid}/notificationPrefs/prefs`.
  ///
  /// Returns a [NotificationPreference] with all toggles set to `true`
  /// (the default) if the sub-document does not yet exist.
  Future<NotificationPreference> getNotificationPrefs(String uid) async {
    final snapshot = await _notificationPrefsDoc(uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      // No record yet — return defaults (all notifications enabled).
      return NotificationPreference(uid: uid);
    }

    return NotificationPreference.fromMap({'uid': uid, ...snapshot.data()!});
  }

  /// Writes `/users/{uid}/notificationPrefs/prefs`.
  ///
  /// Uses [SetOptions.merge] so any future fields added to the document are
  /// not accidentally deleted.
  Future<void> updateNotificationPrefs(NotificationPreference prefs) async {
    final data = prefs.toMap()..remove('uid'); // uid is not stored as a field

    await _notificationPrefsDoc(prefs.uid).set(
      data,
      SetOptions(merge: true),
    );
  }
}
