// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transaction _$TransactionFromJson(Map<String, dynamic> json) => _Transaction(
  id: json['id'] as String,
  reference: json['reference'] as String,
  uid: json['uid'] as String,
  amount: (json['amount'] as num).toDouble(),
  status: const _PaymentStatusConverter().fromJson(json['status'] as String),
  orderId: json['orderId'] as String?,
  createdAt: const _FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const _FirestoreDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$TransactionToJson(
  _Transaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'reference': instance.reference,
  'uid': instance.uid,
  'amount': instance.amount,
  'status': const _PaymentStatusConverter().toJson(instance.status),
  'orderId': instance.orderId,
  'createdAt': const _FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const _FirestoreDateTimeConverter().toJson(instance.updatedAt),
};
