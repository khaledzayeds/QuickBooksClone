// customer_credit_model.dart

import '../../../../core/constants/api_enums.dart' show CustomerCreditAction, PaymentMethod;
import '../../../../core/utils/json_utils.dart';

class CustomerCreditModel {
  const CustomerCreditModel({
    required this.id,
    required this.referenceNumber,
    required this.customerId,
    required this.activityDate,
    required this.amount,
    required this.action,
    required this.status,
    this.customerName,
    this.invoiceId,
    this.invoiceNumber,
    this.refundAccountId,
    this.refundAccountName,
    this.paymentMethod,
    this.postedTransactionId,
    this.postedAt,
  });

  final String id;
  final String referenceNumber;
  final String customerId;
  final String? customerName;
  final DateTime activityDate;
  final double amount;
  final CustomerCreditAction action;
  final String? invoiceId;
  final String? invoiceNumber;
  final String? refundAccountId;
  final String? refundAccountName;
  final PaymentMethod? paymentMethod;
  final int status;
  final String? postedTransactionId;
  final DateTime? postedAt;

  factory CustomerCreditModel.fromJson(Map<String, dynamic> json) => CustomerCreditModel(
        id: JsonUtils.asString(json['id']),
        referenceNumber: JsonUtils.asString(json['referenceNumber']),
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asNullableString(json['customerName']),
        activityDate: _parseDate(json['activityDate']),
        amount: JsonUtils.asDouble(json['amount']),
        action: CustomerCreditAction.fromValue(JsonUtils.asInt(json['action'], fallback: 1)),
        invoiceId: JsonUtils.asNullableString(json['invoiceId']),
        invoiceNumber: JsonUtils.asNullableString(json['invoiceNumber']),
        refundAccountId: JsonUtils.asNullableString(json['refundAccountId']),
        refundAccountName: JsonUtils.asNullableString(json['refundAccountName']),
        paymentMethod: _parsePaymentMethod(json['paymentMethod']),
        status: JsonUtils.asInt(json['status']),
        postedTransactionId: JsonUtils.asNullableString(json['postedTransactionId']),
        postedAt: _parseNullableDate(json['postedAt']),
      );

  static PaymentMethod? _parsePaymentMethod(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return PaymentMethod.fromString(text);
  }

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class CreateCustomerCreditDto {
  const CreateCustomerCreditDto({
    required this.customerId,
    required this.activityDate,
    required this.amount,
    required this.action,
    this.invoiceId,
    this.refundAccountId,
    this.paymentMethod,
  });

  final String customerId;
  final DateTime activityDate;
  final double amount;
  final CustomerCreditAction action;
  final String? invoiceId;
  final String? refundAccountId;
  final PaymentMethod? paymentMethod;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'activityDate': _dateOnly(activityDate),
        'amount': amount,
        'action': action.value,
        if (invoiceId != null && invoiceId!.isNotEmpty) 'invoiceId': invoiceId,
        if (refundAccountId != null && refundAccountId!.isNotEmpty) 'refundAccountId': refundAccountId,
        if (paymentMethod != null) 'paymentMethod': paymentMethod!.toApiString(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
