/// Represents the authenticated user in the AKKA Food app.
///
/// The [role] field controls access to admin features.
/// Values: 'user' (default) | 'admin'
class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    required this.displayName,
    required this.isVerified,
    required this.isDeactivated,
    required this.createdAt,
    required this.linkedProviders,
    required this.role,
  });

  final String uid;
  final String? email;
  final String? phoneNumber;
  final String displayName;
  final bool isVerified;
  final bool isDeactivated;
  final DateTime createdAt;

  /// Authentication providers linked to this account.
  /// e.g. ['password', 'google.com', 'facebook.com']
  final List<String> linkedProviders;

  /// Role controlling access to admin features.
  /// Valid values: 'user' | 'admin'
  final String role;

  /// Returns true when this user has admin privileges.
  bool get isAdmin => role == 'admin';

  /// Creates an [AppUser] from a Firestore document map.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      displayName: map['displayName'] as String? ?? '',
      isVerified: map['isVerified'] as bool? ?? false,
      isDeactivated: map['isDeactivated'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : DateTime.now(),
      linkedProviders: List<String>.from(
        (map['linkedProviders'] as List<dynamic>?) ?? [],
      ),
      // Default to 'user' if the field is missing (backwards compatibility)
      role: map['role'] as String? ?? 'user',
    );
  }

  /// Serializes this [AppUser] to a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'isVerified': isVerified,
      'isDeactivated': isDeactivated,
      'createdAt': createdAt,
      'linkedProviders': linkedProviders,
      'role': role,
    };
  }

  /// Returns a copy of this [AppUser] with the given fields replaced.
  AppUser copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    bool? isVerified,
    bool? isDeactivated,
    DateTime? createdAt,
    List<String>? linkedProviders,
    String? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      isVerified: isVerified ?? this.isVerified,
      isDeactivated: isDeactivated ?? this.isDeactivated,
      createdAt: createdAt ?? this.createdAt,
      linkedProviders: linkedProviders ?? this.linkedProviders,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          phoneNumber == other.phoneNumber &&
          displayName == other.displayName &&
          isVerified == other.isVerified &&
          isDeactivated == other.isDeactivated &&
          createdAt == other.createdAt &&
          role == other.role;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      phoneNumber.hashCode ^
      displayName.hashCode ^
      isVerified.hashCode ^
      isDeactivated.hashCode ^
      createdAt.hashCode ^
      role.hashCode;

  @override
  String toString() =>
      'AppUser(uid: $uid, displayName: $displayName, role: $role, '
      'isVerified: $isVerified, isDeactivated: $isDeactivated)';
}

/// Converts a Firestore [Timestamp] or a plain [DateTime] to [DateTime].
///
/// Firestore returns `Timestamp` objects; plain `DateTime` values appear
/// in unit tests and local serialization.
DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  // Firestore Timestamp has a .toDate() method
  return (value as dynamic).toDate() as DateTime;
}
