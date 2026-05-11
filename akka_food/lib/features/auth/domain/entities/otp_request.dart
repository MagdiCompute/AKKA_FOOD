/// Domain entity representing an in-flight OTP verification request.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [==], [hashCode], [toString], and [copyWith] manually
/// per project conventions (same pattern as [AppUser]).
///
/// The [verificationId] holds the Firebase phone-auth verification ID (or an
/// equivalent opaque token for email OTP flows).
/// The [channel] is either `'email'` or `'sms'`.
class OtpRequest {
  final String verificationId; // Firebase phone auth verification ID
  final String channel; // 'email' | 'sms'
  final DateTime issuedAt;
  final int attemptCount;

  const OtpRequest({
    required this.verificationId,
    required this.channel,
    required this.issuedAt,
    this.attemptCount = 0,
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Returns `true` when the OTP has been issued more than 10 minutes ago.
  ///
  /// Satisfies Requirement 3, Criteria 1 & 3 (OTP expires after 10 minutes).
  bool get isExpired =>
      DateTime.now().difference(issuedAt).inMinutes >= 10;

  /// Returns `true` when the maximum number of consecutive incorrect attempts
  /// (5) has been reached.
  ///
  /// Satisfies Requirement 3, Criteria 4.
  bool get isMaxAttemptsReached => attemptCount >= 5;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory OtpRequest.fromMap(Map<String, dynamic> map) {
    return OtpRequest(
      verificationId: map['verificationId'] as String,
      channel: map['channel'] as String,
      issuedAt: _parseDateTime(map['issuedAt']),
      attemptCount: map['attemptCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'verificationId': verificationId,
      'channel': channel,
      'issuedAt': issuedAt.toIso8601String(),
      'attemptCount': attemptCount,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  OtpRequest copyWith({
    String? verificationId,
    String? channel,
    DateTime? issuedAt,
    int? attemptCount,
  }) {
    return OtpRequest(
      verificationId: verificationId ?? this.verificationId,
      channel: channel ?? this.channel,
      issuedAt: issuedAt ?? this.issuedAt,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OtpRequest) return false;
    if (verificationId != other.verificationId) return false;
    if (channel != other.channel) return false;
    if (issuedAt != other.issuedAt) return false;
    if (attemptCount != other.attemptCount) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
        verificationId,
        channel,
        issuedAt,
        attemptCount,
      );

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'OtpRequest('
        'verificationId: $verificationId, '
        'channel: $channel, '
        'issuedAt: $issuedAt, '
        'attemptCount: $attemptCount'
        ')';
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Converts a stored timestamp-like value to [DateTime].
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
