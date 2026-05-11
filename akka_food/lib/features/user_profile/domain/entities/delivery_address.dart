import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_address.freezed.dart';

/// Domain entity representing a user's saved delivery address.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Firestore serialization is handled manually via [fromMap] / [toMap]
/// so the domain layer stays free of Firebase dependencies.
@freezed
abstract class DeliveryAddress with _$DeliveryAddress {
  const DeliveryAddress._();

  const factory DeliveryAddress({
    required String id,
    required String uid,
    required String label,
    required String streetAddress,
    required String city,
    double? latitude,
    double? longitude,
    required bool isDefault,
    required DateTime createdAt,
  }) = _DeliveryAddress;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      id: map['id'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      label: map['label'] as String? ?? '',
      streetAddress: map['streetAddress'] as String? ?? '',
      city: map['city'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'label': label,
      'streetAddress': streetAddress,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
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
