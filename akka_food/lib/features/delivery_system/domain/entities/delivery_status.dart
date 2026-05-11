/// Represents the current status of an order in the delivery pipeline.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Statuses per design: pending → confirmed → preparing → outForDelivery → delivered | failed
enum DeliveryStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  failed;

  /// Parses a Firestore string value into a [DeliveryStatus].
  static DeliveryStatus fromString(String? value) {
    switch (value) {
      case 'confirmed':
        return DeliveryStatus.confirmed;
      case 'preparing':
        return DeliveryStatus.preparing;
      case 'out_for_delivery':
        return DeliveryStatus.outForDelivery;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'failed':
        return DeliveryStatus.failed;
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
      case DeliveryStatus.outForDelivery:
        return 'out_for_delivery';
      case DeliveryStatus.delivered:
        return 'delivered';
      case DeliveryStatus.failed:
        return 'failed';
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
      case DeliveryStatus.outForDelivery:
        return 'Out for Delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }

  /// Whether this status is considered "active" (not terminal).
  bool get isActive =>
      this != DeliveryStatus.delivered && this != DeliveryStatus.failed;
}
