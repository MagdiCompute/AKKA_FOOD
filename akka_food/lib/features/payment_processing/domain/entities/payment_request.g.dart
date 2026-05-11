// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentRequest _$PaymentRequestFromJson(Map<String, dynamic> json) =>
    _PaymentRequest(
      cartSummary: CartSummary.fromJson(
        json['cartSummary'] as Map<String, dynamic>,
      ),
      phoneNumber: json['phoneNumber'] as String,
    );

Map<String, dynamic> _$PaymentRequestToJson(_PaymentRequest instance) =>
    <String, dynamic>{
      'cartSummary': instance.cartSummary.toJson(),
      'phoneNumber': instance.phoneNumber,
    };
