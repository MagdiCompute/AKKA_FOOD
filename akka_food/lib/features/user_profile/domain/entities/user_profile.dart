import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// Domain entity representing a user's profile.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Firestore serialization is handled manually via [fromMap] / [toMap]
/// so the domain layer stays free of Firebase dependencies.
@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String uid,
    required String displayName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    required DateTime updatedAt,
  }) = _UserProfile;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Converts a Firestore timestamp-like value to [DateTime].
///
/// Accepts:
/// - A [DateTime] directly.
/// - Any object with a `.toDate()` method (e.g. `Timestamp` from
///   `cloud_firestore`) — handled via duck-typing so the domain layer
///   stays free of Firebase imports.
/// - An ISO-8601 [String].
/// - `null` — falls back to [DateTime.now].
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  // Duck-type Firestore Timestamp without importing cloud_firestore.
  try {
    // ignore: avoid_dynamic_calls
    return (value.toDate()) as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}
