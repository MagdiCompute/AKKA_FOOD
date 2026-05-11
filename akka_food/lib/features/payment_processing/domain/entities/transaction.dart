import 'package:freezed_annotation/freezed_annotation.dart';

import 'payment_status.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

// ---------------------------------------------------------------------------
// JsonConverters
// ---------------------------------------------------------------------------

/// Converts [PaymentStatus] to/from its string name for JSON serialization.
class _PaymentStatusConverter
    implements JsonConverter<PaymentStatus, String> {
  const _PaymentStatusConverter();

  @override
  PaymentStatus fromJson(String json) => PaymentStatus.fromString(json);

  @override
  String toJson(PaymentStatus status) => status.name;
}

/// Converts [DateTime] to/from dynamic values for Firestore compatibility.
///
/// Accepts:
/// - A [DateTime] directly
/// - An ISO-8601 [String]
/// - Any object with a `.toDate()` method (e.g. Firestore `Timestamp`) —
///   handled via duck-typing so the domain layer stays free of Firebase imports
/// - `null` — falls back to [DateTime.now]
class _FirestoreDateTimeConverter
    implements JsonConverter<DateTime, dynamic> {
  const _FirestoreDateTimeConverter();

  @override
  DateTime fromJson(dynamic json) => _parseDateTime(json);

  @override
  dynamic toJson(DateTime dateTime) => dateTime.toIso8601String();
}

// ---------------------------------------------------------------------------
// Transaction entity
// ---------------------------------------------------------------------------

/// Domain entity representing a single payment transaction.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Firestore serialization is provided via [fromMap]/[toMap] convenience
/// methods that delegate to the generated JSON factories, plus custom
/// converters for [PaymentStatus] and [DateTime] (Firestore Timestamp).
@freezed
abstract class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    /// Firestore document ID.
    required String id,

    /// Unique non-guessable UUID reference for this payment.
    required String reference,

    /// User ID of the payer.
    required String uid,

    /// Payment amount in XOF.
    required double amount,

    /// Current status of the payment.
    @_PaymentStatusConverter() required PaymentStatus status,

    /// Order ID — set when payment succeeds, null otherwise.
    String? orderId,

    /// Timestamp when the transaction was created.
    @_FirestoreDateTimeConverter() required DateTime createdAt,

    /// Timestamp when the transaction was last updated.
    @_FirestoreDateTimeConverter() required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  // ---------------------------------------------------------------------------
  // Firestore serialization helpers
  // ---------------------------------------------------------------------------

  /// Creates a [Transaction] from a Firestore document map.
  ///
  /// Handles Firestore `Timestamp` objects via duck-typing (no Firebase import).
  factory Transaction.fromMap(Map<String, dynamic> map) =>
      Transaction.fromJson(map);

  /// Converts this [Transaction] to a map suitable for Firestore writes.
  Map<String, dynamic> toMap() => toJson();
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
