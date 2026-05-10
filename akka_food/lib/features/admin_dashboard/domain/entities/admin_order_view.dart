import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Supporting enums
// ---------------------------------------------------------------------------

/// Represents the delivery method chosen by the customer.
enum DeliveryOption {
  delivery,
  pickup;

  /// Parses a Firestore string value into a [DeliveryOption].
  static DeliveryOption fromString(String? value) {
    switch (value) {
      case 'pickup':
        return DeliveryOption.pickup;
      case 'delivery':
      default:
        return DeliveryOption.delivery;
    }
  }

  /// Converts this enum to its Firestore string representation.
  String toFirestoreString() {
    switch (this) {
      case DeliveryOption.delivery:
        return 'delivery';
      case DeliveryOption.pickup:
        return 'pickup';
    }
  }

  /// Human-readable label for display in the UI.
  String get label {
    switch (this) {
      case DeliveryOption.delivery:
        return 'Delivery';
      case DeliveryOption.pickup:
        return 'Pickup';
    }
  }
}

/// Represents the current status of an order in the delivery pipeline.
enum DeliveryStatus {
  pending,
  confirmed,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  cancelled;

  /// Parses a Firestore string value into a [DeliveryStatus].
  static DeliveryStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return DeliveryStatus.confirmed;
      case 'preparing':
        return DeliveryStatus.preparing;
      case 'ready_for_pickup':
        return DeliveryStatus.readyForPickup;
      case 'out_for_delivery':
        return DeliveryStatus.outForDelivery;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      case 'pending':
      default:
        return DeliveryStatus.pending;
    }
  }

  /// Converts this enum to its Firestore string representation.
  String toFirestoreString() {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.confirmed:
        return 'confirmed';
      case DeliveryStatus.preparing:
        return 'preparing';
      case DeliveryStatus.readyForPickup:
        return 'ready_for_pickup';
      case DeliveryStatus.outForDelivery:
        return 'out_for_delivery';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Human-readable label for display in the UI.
  String get label {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.confirmed:
        return 'Confirmed';
      case DeliveryStatus.preparing:
        return 'Preparing';
      case DeliveryStatus.readyForPickup:
        return 'Ready for Pickup';
      case DeliveryStatus.outForDelivery:
        return 'Out for Delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Whether this status is considered "active" (not terminal).
  bool get isActive =>
      this != DeliveryStatus.delivered && this != DeliveryStatus.cancelled;
}

// ---------------------------------------------------------------------------
// Supporting entities
// ---------------------------------------------------------------------------

/// A single item within an order.
class OrderItem {
  const OrderItem({
    required this.mealId,
    required this.mealName,
    required this.quantity,
    required this.unitPrice,
  });

  final String mealId;
  final String mealName;
  final int quantity;

  /// Unit price in XOF.
  final double unitPrice;

  /// Total price for this line item (quantity × unitPrice).
  double get lineTotal => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      mealId: map['mealId'] as String? ?? '',
      mealName: map['mealName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mealId': mealId,
      'mealName': mealName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  OrderItem copyWith({
    String? mealId,
    String? mealName,
    int? quantity,
    double? unitPrice,
  }) {
    return OrderItem(
      mealId: mealId ?? this.mealId,
      mealName: mealName ?? this.mealName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          mealId == other.mealId &&
          mealName == other.mealName &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice;

  @override
  int get hashCode =>
      mealId.hashCode ^ mealName.hashCode ^ quantity.hashCode ^ unitPrice.hashCode;

  @override
  String toString() =>
      'OrderItem(mealId: $mealId, mealName: $mealName, qty: $quantity, unitPrice: $unitPrice)';
}

/// The delivery address provided by the customer.
class DeliveryAddress {
  const DeliveryAddress({
    required this.street,
    required this.city,
    this.additionalInfo,
  });

  final String street;
  final String city;
  final String? additionalInfo;

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      additionalInfo: map['additionalInfo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }

  DeliveryAddress copyWith({
    String? street,
    String? city,
    Object? additionalInfo = _sentinel,
  }) {
    return DeliveryAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      additionalInfo: additionalInfo == _sentinel
          ? this.additionalInfo
          : additionalInfo as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAddress &&
          runtimeType == other.runtimeType &&
          street == other.street &&
          city == other.city &&
          additionalInfo == other.additionalInfo;

  @override
  int get hashCode =>
      street.hashCode ^ city.hashCode ^ additionalInfo.hashCode;

  @override
  String toString() =>
      'DeliveryAddress(street: $street, city: $city)';
}

// Sentinel value to distinguish "not provided" from explicit null.
const _sentinel = Object();

// ---------------------------------------------------------------------------
// AdminOrderView
// ---------------------------------------------------------------------------

/// A read-only view of an order as seen by the admin dashboard.
///
/// Firestore collection: `/orders/{orderId}`
/// Active orders: status not in ['delivered', 'cancelled'], sorted by createdAt asc.
class AdminOrderView {
  const AdminOrderView({
    required this.orderId,
    required this.uid,
    required this.userDisplayName,
    this.userPhone,
    required this.items,
    required this.total,
    required this.deliveryOption,
    this.deliveryAddress,
    required this.status,
    this.etaMinutes,
    required this.createdAt,
  });

  final String orderId;
  final String uid;
  final String userDisplayName;
  final String? userPhone;
  final List<OrderItem> items;

  /// Order total in XOF.
  final double total;
  final DeliveryOption deliveryOption;
  final DeliveryAddress? deliveryAddress;
  final DeliveryStatus status;

  /// ETA in minutes, set when status is [DeliveryStatus.outForDelivery].
  final int? etaMinutes;
  final DateTime createdAt;

  /// Creates an [AdminOrderView] from a Firestore document map.
  factory AdminOrderView.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(OrderItem.fromMap)
        .toList();

    final rawAddress = map['deliveryAddress'] as Map<String, dynamic>?;

    return AdminOrderView(
      orderId: id,
      uid: map['uid'] as String? ?? '',
      userDisplayName: map['userDisplayName'] as String? ?? 'Unknown',
      userPhone: map['userPhone'] as String?,
      items: items,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      deliveryOption: DeliveryOption.fromString(map['deliveryOption'] as String?),
      deliveryAddress:
          rawAddress != null ? DeliveryAddress.fromMap(rawAddress) : null,
      status: DeliveryStatus.fromString(map['status'] as String?),
      etaMinutes: (map['etaMinutes'] as num?)?.toInt(),
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Serializes this [AdminOrderView] to a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userDisplayName': userDisplayName,
      if (userPhone != null) 'userPhone': userPhone,
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'deliveryOption': deliveryOption.toFirestoreString(),
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress!.toMap(),
      'status': status.toFirestoreString(),
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
      'createdAt': createdAt,
    };
  }

  /// Returns a copy of this [AdminOrderView] with the given fields replaced.
  AdminOrderView copyWith({
    String? orderId,
    String? uid,
    String? userDisplayName,
    Object? userPhone = _sentinel,
    List<OrderItem>? items,
    double? total,
    DeliveryOption? deliveryOption,
    Object? deliveryAddress = _sentinel,
    DeliveryStatus? status,
    Object? etaMinutes = _sentinel,
    DateTime? createdAt,
  }) {
    return AdminOrderView(
      orderId: orderId ?? this.orderId,
      uid: uid ?? this.uid,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhone:
          userPhone == _sentinel ? this.userPhone : userPhone as String?,
      items: items ?? this.items,
      total: total ?? this.total,
      deliveryOption: deliveryOption ?? this.deliveryOption,
      deliveryAddress: deliveryAddress == _sentinel
          ? this.deliveryAddress
          : deliveryAddress as DeliveryAddress?,
      status: status ?? this.status,
      etaMinutes:
          etaMinutes == _sentinel ? this.etaMinutes : etaMinutes as int?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminOrderView &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          uid == other.uid &&
          status == other.status &&
          total == other.total &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      orderId.hashCode ^
      uid.hashCode ^
      status.hashCode ^
      total.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'AdminOrderView(orderId: $orderId, uid: $uid, status: $status, '
      'total: $total, createdAt: $createdAt)';
}

/// Converts a Firestore [Timestamp] or a plain [DateTime] to [DateTime].
DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return DateTime.now();
}
