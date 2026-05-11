/// The delivery address provided by the customer.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Implements [==], [hashCode], [toString], and [copyWith] manually.
class DeliveryAddress {
  final String street;
  final String city;
  final double latitude;
  final double longitude;
  final String? label;

  const DeliveryAddress({
    required this.street,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'street': street,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      if (label != null) 'label': label,
    };
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  DeliveryAddress copyWith({
    String? street,
    String? city,
    double? latitude,
    double? longitude,
    Object? label = _sentinel,
  }) {
    return DeliveryAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label == _sentinel ? this.label : label as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Equality & hashing
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DeliveryAddress) return false;
    return street == other.street &&
        city == other.city &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        label == other.label;
  }

  @override
  int get hashCode => Object.hash(street, city, latitude, longitude, label);

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  @override
  String toString() =>
      'DeliveryAddress(street: $street, city: $city, '
      'latitude: $latitude, longitude: $longitude, label: $label)';
}

// Sentinel value to distinguish "not provided" from explicit null in copyWith.
const Object _sentinel = Object();
