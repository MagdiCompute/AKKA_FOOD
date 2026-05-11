/// Domain entity representing a pair of Firebase authentication tokens.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [==], [hashCode], [toString], and [copyWith] manually
/// per project conventions (not yet using freezed).
class AuthToken {
  final String accessToken; // Firebase ID token (1 hour expiry)
  final String refreshToken; // Firebase refresh token (long-lived)
  final DateTime expiresAt;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Returns `true` when the access token has passed its expiry time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // ---------------------------------------------------------------------------
  // Secure storage serialization
  // ---------------------------------------------------------------------------

  factory AuthToken.fromMap(Map<String, dynamic> map) {
    return AuthToken(
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  AuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return AuthToken(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthToken) return false;
    if (accessToken != other.accessToken) return false;
    if (refreshToken != other.refreshToken) return false;
    if (expiresAt != other.expiresAt) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresAt);

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'AuthToken('
        'accessToken: $accessToken, '
        'refreshToken: $refreshToken, '
        'expiresAt: $expiresAt'
        ')';
  }
}
