// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartItem _$CartItemFromJson(Map<String, dynamic> json) => _CartItem(
  mealId: json['mealId'] as String,
  mealName: json['mealName'] as String,
  mealImageUrl: json['mealImageUrl'] as String,
  unitPrice: (json['unitPrice'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  isAvailable: json['isAvailable'] as bool,
);

Map<String, dynamic> _$CartItemToJson(_CartItem instance) => <String, dynamic>{
  'mealId': instance.mealId,
  'mealName': instance.mealName,
  'mealImageUrl': instance.mealImageUrl,
  'unitPrice': instance.unitPrice,
  'quantity': instance.quantity,
  'isAvailable': instance.isAvailable,
};
