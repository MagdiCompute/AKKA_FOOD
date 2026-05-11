// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentResult _$PaymentResultFromJson(Map<String, dynamic> json) =>
    _PaymentResult(
      transactionId: json['transactionId'] as String,
      status: const _PaymentStatusConverter().fromJson(
        json['status'] as String,
      ),
      orderId: json['orderId'] as String?,
    );

Map<String, dynamic> _$PaymentResultToJson(_PaymentResult instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'status': const _PaymentStatusConverter().toJson(instance.status),
      'orderId': instance.orderId,
    };
