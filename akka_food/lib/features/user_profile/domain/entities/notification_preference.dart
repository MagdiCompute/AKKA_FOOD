import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preference.freezed.dart';

/// Domain entity representing a user's notification preferences.
///
/// Pure Dart — no Flutter or Firebase imports.
/// Uses [freezed] for immutability, [==], [hashCode], [toString], and [copyWith].
///
/// Firestore serialization is handled manually via [fromMap] / [toMap]
/// so the domain layer stays free of Firebase dependencies.
///
/// All boolean toggles default to `true` per Requirement 7.4:
/// new accounts initialize all notification toggles to enabled.
@freezed
abstract class NotificationPreference with _$NotificationPreference {
  const NotificationPreference._();

  const factory NotificationPreference({
    required String uid,
    @Default(true) bool orderUpdates,
    @Default(true) bool promotions,
    @Default(true) bool coinEvents,
  }) = _NotificationPreference;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      uid: map['uid'] as String,
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? true,
      coinEvents: map['coinEvents'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'coinEvents': coinEvents,
    };
  }
}
