import 'package:json_annotation/json_annotation.dart';

/// Delivery method chosen by the user for their order.
///
/// Pure Dart — no Flutter or Firebase imports.
/// [JsonEnum] ensures json_serializable serializes this as its name string
/// (e.g. `"delivery"`, `"pickup"`).
@JsonEnum()
enum DeliveryOption {
  delivery,
  pickup;

  /// Parses a string value (e.g. from JSON / Hive) into a [DeliveryOption].
  static DeliveryOption fromString(String? value) {
    switch (value) {
      case 'pickup':
        return DeliveryOption.pickup;
      case 'delivery':
      default:
        return DeliveryOption.delivery;
    }
  }

  /// Converts this enum to its string representation for serialization.
  String toJson() {
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
