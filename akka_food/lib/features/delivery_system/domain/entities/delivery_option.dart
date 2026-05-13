/// Represents the delivery method chosen by the customer.
///
/// Pure Dart — no Flutter or Firebase imports.
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
        return 'Livraison';
      case DeliveryOption.pickup:
        return 'À emporter';
    }
  }
}
