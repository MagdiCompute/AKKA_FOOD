import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_summary.freezed.dart';

// ---------------------------------------------------------------------------
// OrderItem — nested entity
// ---------------------------------------------------------------------------

/// A single line-item within an [OrderSummary].
///
/// Pure Dart — no Flutter or Firebase imports.
@freezed
abstract class OrderItem with _$OrderItem {
  const OrderItem._();

  const factory OrderItem({
    required String name,
    required int quantity,
    required double unitPrice,
  }) = _OrderItem;

  // -------------------------------------------------------------------------
  // Firestore serialization
  // -------------------------------------------------------------------------

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

// ---------------------------------------------------------------------------
// OrderSummary — top-level entity
// ---------------------------------------------------------------------------

/// Domain entity representing a summarised view of a customer order.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Firestore serialization is handled manually via [fromMap] / [toMap]
/// so the domain layer stays free of Firebase dependencies.
@freezed
abstract class OrderSummary with _$OrderSummary {
  const OrderSummary._();

  const factory OrderSummary({
    required String orderId,
    required DateTime orderDate,
    required List<OrderItem> items,
    required double totalAmount,
    /// One of: "pending" | "preparing" | "delivered" | "cancelled"
    required String status,
    String? deliveryAddress,
    required String paymentMethod,
  }) = _OrderSummary;

  // -------------------------------------------------------------------------
  // Firestore serialization
  // -------------------------------------------------------------------------

  factory OrderSummary.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final List<OrderItem> items;
    if (rawItems is List) {
      items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromMap)
          .toList();
    } else {
      items = const [];
    }

    return OrderSummary(
      orderId: map['orderId'] as String? ?? '',
      orderDate: _parseDateTime(map['createdAt'] ?? map['orderDate']),
      items: items,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending',
      deliveryAddress: map['deliveryAddress'] as String?,
      paymentMethod: map['paymentMethod'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': orderId,
      'orderDate': orderDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
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
