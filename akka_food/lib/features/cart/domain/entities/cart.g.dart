// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Cart _$CartFromJson(Map<String, dynamic> json) => _Cart(
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  deliveryOption: $enumDecode(_$DeliveryOptionEnumMap, json['deliveryOption']),
  selectedAddress:
      _$JsonConverterFromJson<Map<String, dynamic>, DeliveryAddress>(
        json['selectedAddress'],
        const _DeliveryAddressConverter().fromJson,
      ),
  redeemedCoins: (json['redeemedCoins'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CartToJson(_Cart instance) => <String, dynamic>{
  'items': instance.items,
  'deliveryOption': instance.deliveryOption,
  'selectedAddress':
      _$JsonConverterToJson<Map<String, dynamic>, DeliveryAddress>(
        instance.selectedAddress,
        const _DeliveryAddressConverter().toJson,
      ),
  'redeemedCoins': instance.redeemedCoins,
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
