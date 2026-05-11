import 'package:freezed_annotation/freezed_annotation.dart';

part 'coin_transaction.freezed.dart';

/// Domain entity representing a single coin transaction for a user.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// [amount] is positive for credits (e.g. "Purchase reward") and negative
/// for debits (e.g. "Redemption").
///
/// Firestore serialization is handled manually via [fromMap] / [toMap]
/// so the domain layer stays free of Firebase dependencies.
@freezed
abstract class CoinTransaction with _$CoinTransaction {
  const CoinTransaction._();

  const factory CoinTransaction({
    required String id,
    required String uid,
    required int amount,
    required String reason,
    String? orderId,
    required DateTime timestamp,
  }) = _CoinTransaction;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory CoinTransaction.fromMap(Map<String, dynamic> map) {
    return CoinTransaction(
      id: map['id'] as String,
      uid: map['uid'] as String,
      amount: map['amount'] as int,
      reason: map['reason'] as String? ?? '',
      orderId: map['orderId'] as String?,
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'amount': amount,
      'reason': reason,
      'orderId': orderId,
      'timestamp': timestamp.toIso8601String(),
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
