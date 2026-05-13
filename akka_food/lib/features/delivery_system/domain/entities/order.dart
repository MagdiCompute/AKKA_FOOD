import 'delivery_address.dart';
import 'delivery_option.dart';
import 'delivery_status.dart';
import 'order_item.dart';

/// Domain entity representing a customer order with delivery information.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [==], [hashCode], [toString], and [copyWith] manually
/// per project conventions.
class Order {
  final String id;
  final String uid;
  final List<OrderItem> items;

  /// Subtotal in XOF (sum of item line totals before fees/discounts).
  final double subtotal;

  /// Delivery fee in XOF.
  final double deliveryFee;

  /// Discount applied in XOF.
  final double discount;

  /// Final total in XOF (subtotal + deliveryFee - discount).
  final double total;

  /// Whether the customer chose delivery or pickup.
  final DeliveryOption deliveryOption;

  /// Delivery address; null when [deliveryOption] is [DeliveryOption.pickup].
  final DeliveryAddress? deliveryAddress;

  /// Current delivery status.
  final DeliveryStatus status;

  /// Estimated time of arrival in minutes; set when status is outForDelivery.
  final int? etaMinutes;

  /// Phone number of the delivery person; set when status is outForDelivery.
  final String? deliveryPhone;

  /// Timestamp when the order was created.
  final DateTime createdAt;

  /// Timestamp when the order was delivered; null until delivery is complete.
  final DateTime? deliveredAt;

  /// Reason for delivery failure; null unless status is [DeliveryStatus.failed].
  final String? failureReason;

  const Order({
    required this.id,
    required this.uid,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryOption,
    this.deliveryAddress,
    required this.status,
    this.etaMinutes,
    this.deliveryPhone,
    required this.createdAt,
    this.deliveredAt,
    this.failureReason,
  });

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderItem.fromMap)
        .toList();

    final rawAddress = map['deliveryAddress'] as Map<String, dynamic>?;

    return Order(
      id: id,
      uid: map['uid'] as String? ?? '',
      items: items,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      deliveryOption:
          DeliveryOption.fromString(map['deliveryOption'] as String?),
      deliveryAddress:
          rawAddress != null ? DeliveryAddress.fromMap(rawAddress) : null,
      status: DeliveryStatus.fromString(map['status'] as String?),
      etaMinutes: (map['etaMinutes'] as num?)?.toInt(),
      deliveryPhone: map['deliveryPhone'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      deliveredAt: map['deliveredAt'] != null
          ? _parseDateTime(map['deliveredAt'])
          : null,
      failureReason: map['failureReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'deliveryOption': deliveryOption.toFirestoreString(),
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress!.toMap(),
      'status': status.toFirestoreString(),
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
      if (deliveryPhone != null) 'deliveryPhone': deliveryPhone,
      'createdAt': createdAt.toIso8601String(),
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (failureReason != null) 'failureReason': failureReason,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  Order copyWith({
    String? id,
    String? uid,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    DeliveryOption? deliveryOption,
    Object? deliveryAddress = _sentinel,
    DeliveryStatus? status,
    Object? etaMinutes = _sentinel,
    Object? deliveryPhone = _sentinel,
    DateTime? createdAt,
    Object? deliveredAt = _sentinel,
    Object? failureReason = _sentinel,
  }) {
    return Order(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      deliveryAddress: deliveryAddress == _sentinel
          ? this.deliveryAddress
          : deliveryAddress as DeliveryAddress?,
      status: status ?? this.status,
      etaMinutes:
          etaMinutes == _sentinel ? this.etaMinutes : etaMinutes as int?,
      deliveryPhone:
          deliveryPhone == _sentinel ? this.deliveryPhone : deliveryPhone as String?,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt:
          deliveredAt == _sentinel ? this.deliveredAt : deliveredAt as DateTime?,
      failureReason: failureReason == _sentinel
          ? this.failureReason
          : failureReason as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Order) return false;
    if (id != other.id) return false;
    if (uid != other.uid) return false;
    if (subtotal != other.subtotal) return false;
    if (deliveryFee != other.deliveryFee) return false;
    if (discount != other.discount) return false;
    if (total != other.total) return false;
    if (deliveryOption != other.deliveryOption) return false;
    if (deliveryAddress != other.deliveryAddress) return false;
    if (status != other.status) return false;
    if (etaMinutes != other.etaMinutes) return false;
    if (createdAt != other.createdAt) return false;
    if (deliveredAt != other.deliveredAt) return false;
    if (failureReason != other.failureReason) return false;
    if (items.length != other.items.length) return false;
    for (var i = 0; i < items.length; i++) {
      if (items[i] != other.items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        uid,
        subtotal,
        deliveryFee,
        discount,
        total,
        deliveryOption,
        deliveryAddress,
        status,
        etaMinutes,
        createdAt,
        deliveredAt,
        failureReason,
        Object.hashAll(items),
      );

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'Order('
        'id: $id, '
        'uid: $uid, '
        'items: ${items.length} item(s), '
        'subtotal: $subtotal, '
        'deliveryFee: $deliveryFee, '
        'discount: $discount, '
        'total: $total, '
        'deliveryOption: $deliveryOption, '
        'status: $status, '
        'etaMinutes: $etaMinutes, '
        'createdAt: $createdAt, '
        'deliveredAt: $deliveredAt, '
        'failureReason: $failureReason'
        ')';
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Sentinel object used by [Order.copyWith] to distinguish between
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
