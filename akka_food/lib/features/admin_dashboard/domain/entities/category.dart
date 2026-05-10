import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a meal category in the AKKA Food catalog.
///
/// Used by the admin dashboard to display and manage categories.
/// Firestore collection: `/categories/{categoryId}`
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// URL of the category image stored in Firebase Storage.
  final String? imageUrl;

  /// Whether the category is currently active (visible to users).
  final bool isActive;

  final DateTime createdAt;

  /// Creates a [Category] from a Firestore document map.
  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Serializes this [Category] to a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  /// Returns a copy of this [Category] with the given fields replaced.
  Category copyWith({
    String? id,
    String? name,
    Object? imageUrl = _sentinel,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          imageUrl == other.imageUrl &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ imageUrl.hashCode ^ isActive.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, isActive: $isActive)';
}

// Sentinel value to distinguish "not provided" from explicit null.
const _sentinel = Object();

/// Converts a Firestore [Timestamp] or a plain [DateTime] to [DateTime].
DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return DateTime.now();
}
