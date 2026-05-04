// vendor_credit_model.dart

import '../../../../core/constants/api_enums.dart' show PaymentMethod, VendorCreditAction;
import '../../../../core/utils/json_utils.dart';

class VendorCreditModel {
  const VendorCreditModel({
    required this.id,
    required this.referenceNumber,
    required this.vendorId,
    required this.activityDate,
    required this.amount,
    required this.action,
    required this.status,
    this.vendorName,
    this.purchaseBillId,
    this.billNumber,
    this.depositAccountId,
    this.depositAccountName,
    this.paymentMethod,
    this.postedTransactionId,
    this.postedAt,
  });

  final String id;
  final String referenceNumber;
  final String vendorId;
  final String? vendorName;
  final DateTime activityDate;
  final double amount;
  final VendorCreditAction action;
  final String? purchaseBillId;
  final String? billNumber;
  final String? depositAccountId;
  final String? depositAccountName;
  final PaymentMethod? paymentMethod;
  final int status;
  final String? postedTransactionId;
  final DateTime? postedAt;

  factory VendorCreditModel.fromJson(Map<String, dynamic> json) => VendorCreditModel(
        id: JsonUtils.asString(json['id']),
        referenceNumber: JsonUtils.asString(json['referenceNumber']),
        vendorId: JsonUtils.asString(json['vendorId']),
        vendorName: JsonUtils.asNullableString(json['vendorName']),
        activityDate: _parseDate(json['activityDate']),
        amount: JsonUtils.asDouble(json['amount']),
        action: VendorCreditAction.fromValue(JsonUtils.asInt(json['action'], defaultValue: 1)),
        purchaseBillId: JsonUtils.asNullableString(json['purchaseBillId']),
        billNumber: JsonUtils.asNullableString(json['billNumber']),
        depositAccountId: JsonUtils.asNullableString(json['depositAccountId']),
        depositAccountName: JsonUtils.asNullableString(json['depositAccountName']),
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

class CreateVendorCreditDto {
  const CreateVendorCreditDto({
    required this.vendorId,
    required this.activityDate,
    required this.amount,
    required this.action,
    this.purchaseBillId,
    this.depositAccountId,
    this.paymentMethod,
  });

  final String vendorId;
  final DateTime activityDate;
  final double amount;
  final VendorCreditAction action;
  final String? purchaseBillId;
  final String? depositAccountId;
  final PaymentMethod? paymentMethod;

  Map<String, dynamic> toJson() => {
        'vendorId': vendorId,
        'activityDate': _dateOnly(activityDate),
        'amount': amount,
        'action': action.value,
        if (purchaseBillId != null && purchaseBillId!.isNotEmpty) 'purchaseBillId': purchaseBillId,
        if (depositAccountId != null && depositAccountId!.isNotEmpty) 'depositAccountId': depositAccountId,
        if (paymentMethod != null) 'paymentMethod': paymentMethod!.toApiString(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
