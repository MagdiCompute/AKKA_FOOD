import 'delivery_status.dart';

/// Domain entity representing a single status update in an order's tracking
/// history.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [==], [hashCode], [toString], and [copyWith] manually
/// per project conventions.
class TrackingUpdate {
  /// The ID of the order this update belongs to.
  final String orderId;

  /// The delivery status at the time of this update.
  final DeliveryStatus status;

  /// When this status change occurred.
  final DateTime timestamp;

  /// Optional note providing additional context (e.g. "Driver en route").
  final String? note;

  const TrackingUpdate({
    required this.orderId,
    required this.status,
    required this.timestamp,
    this.note,
  });

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory TrackingUpdate.fromMap(String orderId, Map<String, dynamic> map) {
    return TrackingUpdate(
      orderId: orderId,
      status: DeliveryStatus.fromString(map['status'] as String?),
      timestamp: _parseDateTime(map['timestamp']),
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status.toFirestoreString(),
      'timestamp': timestamp.toIso8601String(),
      if (note != null) 'note': note,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  TrackingUpdate copyWith({
    String? orderId,
    DeliveryStatus? status,
    DateTime? timestamp,
    Object? note = _sentinel,
  }) {
    return TrackingUpdate(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      note: note == _sentinel ? this.note : note as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TrackingUpdate) return false;
    return orderId == other.orderId &&
        status == other.status &&
        timestamp == other.timestamp &&
        note == other.note;
  }

  @override
  int get hashCode => Object.hash(orderId, status, timestamp, note);

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'TrackingUpdate('
        'orderId: $orderId, '
        'status: $status, '
        'timestamp: $timestamp, '
        'note: $note'
        ')';
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Sentinel object used by [TrackingUpdate.copyWith] to distinguish between
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
