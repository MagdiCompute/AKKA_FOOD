// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartSummary _$CartSummaryFromJson(Map<String, dynamic> json) => _CartSummary(
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotal: (json['subtotal'] as num).toDouble(),
  deliveryFee: (json['deliveryFee'] as num).toDouble(),
  discount: (json['discount'] as num).toDouble(),
  total: (json['total'] as num).toDouble(),
  redeemedCoins: (json['redeemedCoins'] as num).toInt(),
  deliveryOption: $enumDecode(_$DeliveryOptionEnumMap, json['deliveryOption']),
  deliveryAddress:
      _$JsonConverterFromJson<Map<String, dynamic>, DeliveryAddress>(
        json['deliveryAddress'],
        const _DeliveryAddressConverter().fromJson,
      ),
);

Map<String, dynamic> _$CartSummaryToJson(_CartSummary instance) =>
    <String, dynamic>{
      'items': instance.items,
      'subtotal': instance.subtotal,
      'deliveryFee': instance.deliveryFee,
      'discount': instance.discount,
      'total': instance.total,
      'redeemedCoins': instance.redeemedCoins,
      'deliveryOption': instance.deliveryOption,
      'deliveryAddress':
          _$JsonConverterToJson<Map<String, dynamic>, DeliveryAddress>(
            instance.deliveryAddress,
            const _DeliveryAddressConverter().toJson,
          ),
    };

const _$DeliveryOptionEnumMap = {
  DeliveryOption.delivery: 'delivery',
  DeliveryOption.pickup: 'pickup',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
