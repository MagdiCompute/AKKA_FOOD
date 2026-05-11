/// A single item within an order.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [==], [hashCode], [toString], and [copyWith] manually.
class OrderItem {
  final String mealId;
  final String mealName;
  final int quantity;

  /// Unit price in XOF.
  final double unitPrice;

  const OrderItem({
    required this.mealId,
    required this.mealName,
    required this.quantity,
    required this.unitPrice,
  });

  /// Total price for this line item (quantity × unitPrice).
  double get lineTotal => quantity * unitPrice;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      mealId: map['mealId'] as String? ?? '',
      mealName: map['mealName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mealId': mealId,
      'mealName': mealName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OrderItem) return false;
    return mealId == other.mealId &&
        mealName == other.mealName &&
        quantity == other.quantity &&
        unitPrice == other.unitPrice;
  }

  @override
  int get hashCode => Object.hash(mealId, mealName, quantity, unitPrice);

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() =>
      'OrderItem(mealId: $mealId, mealName: $mealName, '
      'qty: $quantity, unitPrice: $unitPrice)';
}
