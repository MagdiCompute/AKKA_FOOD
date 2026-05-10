import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a meal in the AKKA Food catalog.
///
/// Used by the admin dashboard to display and manage meals.
/// Firestore collection: `/meals/{mealId}`
class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.isAvailable,
    required this.isFeatured,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;

  /// Price in XOF (West African CFA franc).
  final double price;

  /// Category name or ID this meal belongs to.
  final String category;

  /// List of image URLs stored in Firebase Storage.
  final List<String> imageUrls;

  /// Whether the meal is currently available for ordering.
  final bool isAvailable;

  /// Whether the meal appears in the Featured section.
  final bool isFeatured;

  final DateTime createdAt;

  /// Creates a [Meal] from a Firestore document map.
  factory Meal.fromMap(String id, Map<String, dynamic> map) {
    return Meal(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? '',
      imageUrls: List<String>.from(
        (map['imageUrls'] as List<dynamic>?) ?? [],
      ),
      isAvailable: map['isAvailable'] as bool? ?? false,
      isFeatured: map['isFeatured'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// Serializes this [Meal] to a Firestore document map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'createdAt': createdAt,
    };
  }

  /// Returns a copy of this [Meal] with the given fields replaced.
  Meal copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? imageUrls,
    bool? isAvailable,
    bool? isFeatured,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price &&
          category == other.category &&
          isAvailable == other.isAvailable &&
          isFeatured == other.isFeatured;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      price.hashCode ^
      category.hashCode ^
      isAvailable.hashCode ^
      isFeatured.hashCode;

  @override
  String toString() =>
      'Meal(id: $id, name: $name, price: $price, category: $category, '
      'isAvailable: $isAvailable, isFeatured: $isFeatured)';
}

/// Converts a Firestore [Timestamp] or a plain [DateTime] to [DateTime].
DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return DateTime.now();
}
