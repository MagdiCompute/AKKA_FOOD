/// Domain entity representing an authenticated application user.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [==], [hashCode], [toString], and [copyWith] manually
/// per project conventions (not yet using freezed).
class AppUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String displayName;
  final bool isVerified;
  final bool isDeactivated;
  final DateTime createdAt;
  final List<String> linkedProviders; // e.g. ['password', 'google.com', 'facebook.com']
  final String role; // 'user' | 'admin'

  const AppUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    required this.displayName,
    required this.isVerified,
    required this.isDeactivated,
    required this.createdAt,
    required this.linkedProviders,
    this.role = 'user',
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Returns `true` when this user has the admin role.
  /// Always use this getter — never compare [role] directly.
  bool get isAdmin => role == 'admin';

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      displayName: map['displayName'] as String? ?? '',
      isVerified: map['isVerified'] as bool? ?? false,
      isDeactivated: map['isDeactivated'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      linkedProviders: List<String>.from(
        (map['linkedProviders'] as List<dynamic>?) ?? <dynamic>[],
      ),
      role: map['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'isVerified': isVerified,
      'isDeactivated': isDeactivated,
      'createdAt': createdAt.toIso8601String(),
      'linkedProviders': linkedProviders,
      'role': role,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  AppUser copyWith({
    String? uid,
    Object? email = _sentinel,
    Object? phoneNumber = _sentinel,
    String? displayName,
    bool? isVerified,
    bool? isDeactivated,
    DateTime? createdAt,
    List<String>? linkedProviders,
    String? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email == _sentinel ? this.email : email as String?,
      phoneNumber:
          phoneNumber == _sentinel ? this.phoneNumber : phoneNumber as String?,
      displayName: displayName ?? this.displayName,
      isVerified: isVerified ?? this.isVerified,
      isDeactivated: isDeactivated ?? this.isDeactivated,
      createdAt: createdAt ?? this.createdAt,
      linkedProviders: linkedProviders ?? this.linkedProviders,
      role: role ?? this.role,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppUser) return false;
    if (uid != other.uid) return false;
    if (email != other.email) return false;
    if (phoneNumber != other.phoneNumber) return false;
    if (displayName != other.displayName) return false;
    if (isVerified != other.isVerified) return false;
    if (isDeactivated != other.isDeactivated) return false;
    if (createdAt != other.createdAt) return false;
    if (role != other.role) return false;
    if (linkedProviders.length != other.linkedProviders.length) return false;
    for (var i = 0; i < linkedProviders.length; i++) {
      if (linkedProviders[i] != other.linkedProviders[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        email,
        phoneNumber,
        displayName,
        isVerified,
        isDeactivated,
        createdAt,
        role,
        Object.hashAll(linkedProviders),
      );

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'AppUser('
        'uid: $uid, '
        'email: $email, '
        'phoneNumber: $phoneNumber, '
        'displayName: $displayName, '
        'isVerified: $isVerified, '
        'isDeactivated: $isDeactivated, '
        'createdAt: $createdAt, '
        'linkedProviders: $linkedProviders, '
        'role: $role'
        ')';
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Sentinel object used by [AppUser.copyWith] to distinguish between
/// "caller passed null explicitly" and "caller omitted the argument".
const Object _sentinel = Object();

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
