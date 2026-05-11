import 'package:freezed_annotation/freezed_annotation.dart';

import 'payment_status.dart';

part 'payment_result.freezed.dart';
part 'payment_result.g.dart';

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

// ---------------------------------------------------------------------------
// PaymentResult entity
// ---------------------------------------------------------------------------

/// Domain entity representing the result of a payment operation.
///
/// Returned after a payment is initiated or when checking payment status.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Serialization is provided via [fromMap]/[toMap] convenience methods that
/// delegate to the generated JSON factories, plus a custom converter for
/// [PaymentStatus].
@freezed
abstract class PaymentResult with _$PaymentResult {
  const PaymentResult._();

  const factory PaymentResult({
    /// The Firestore transaction document ID.
    required String transactionId,

    /// The payment status enum value.
    @_PaymentStatusConverter() required PaymentStatus status,

    /// The order ID — set when payment succeeds, nullable.
    String? orderId,
  }) = _PaymentResult;

  factory PaymentResult.fromJson(Map<String, dynamic> json) =>
      _$PaymentResultFromJson(json);

  // ---------------------------------------------------------------------------
  // Firestore serialization helpers
  // ---------------------------------------------------------------------------

  /// Creates a [PaymentResult] from a Firestore document map.
  factory PaymentResult.fromMap(Map<String, dynamic> map) =>
      PaymentResult.fromJson(map);

  /// Converts this [PaymentResult] to a map suitable for Firestore writes.
  Map<String, dynamic> toMap() => toJson();
}
