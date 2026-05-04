// payment_model.dart

import '../../../../core/constants/api_enums.dart' show PaymentMethod;
import '../../../../core/utils/json_utils.dart';

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.customerId,
    required this.invoiceId,
    required this.depositAccountId,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.customerName,
    this.invoiceNumber,
    this.depositAccountName,
    this.postedTransactionId,
    this.postedAt,
    this.reversalTransactionId,
    this.voidedAt,
  });

  final String id;
  final String paymentNumber;
  final String customerId;
  final String? customerName;
  final String invoiceId;
  final String? invoiceNumber;
  final String depositAccountId;
  final String? depositAccountName;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;
  final int status;
  final String? postedTransactionId;
  final DateTime? postedAt;
  final String? reversalTransactionId;
  final DateTime? voidedAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: JsonUtils.asString(json['id']),
        paymentNumber: JsonUtils.asString(json['paymentNumber']),
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asNullableString(json['customerName']),
        invoiceId: JsonUtils.asString(json['invoiceId']),
        invoiceNumber: JsonUtils.asNullableString(json['invoiceNumber']),
        depositAccountId: JsonUtils.asString(json['depositAccountId']),
        depositAccountName: JsonUtils.asNullableString(json['depositAccountName']),
        paymentDate: _parseDate(json['paymentDate']),
        amount: JsonUtils.asDouble(json['amount']),
        paymentMethod: JsonUtils.asString(json['paymentMethod'], defaultValue: 'Cash'),
        status: JsonUtils.asInt(json['status']),
        postedTransactionId: JsonUtils.asNullableString(json['postedTransactionId']),
        postedAt: _parseNullableDate(json['postedAt']),
        reversalTransactionId: JsonUtils.asNullableString(json['reversalTransactionId']),
        voidedAt: _parseNullableDate(json['voidedAt']),
      );

  bool get isVoid => voidedAt != null;

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class CreatePaymentDto {
  const CreatePaymentDto({
    required this.invoiceId,
    required this.depositAccountId,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
  });

  final String invoiceId;
  final String depositAccountId;
  final DateTime paymentDate;
  final double amount;
  final PaymentMethod paymentMethod;

  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        'depositAccountId': depositAccountId,
        'paymentDate': _dateOnly(paymentDate),
        'amount': amount,
        'paymentMethod': paymentMethod.toApiString(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
