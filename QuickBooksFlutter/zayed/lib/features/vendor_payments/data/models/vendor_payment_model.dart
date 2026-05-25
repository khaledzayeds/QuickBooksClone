// vendor_payment_model.dart

import '../../../../core/utils/json_utils.dart';

class VendorPaymentModel {
  const VendorPaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.vendorId,
    required this.vendorName,
    required this.paymentAccountId,
    required this.paymentAccountName,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    this.memo,
    required this.status,
    required this.lines,
  });

  final String id;
  final String paymentNumber;
  final String vendorId;
  final String vendorName;
  final String paymentAccountId;
  final String paymentAccountName;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;
  final String? memo;
  final int status; // 1 Draft, 2 Posted, 3 Void
  final List<VendorPaymentLineModel> lines;

  factory VendorPaymentModel.fromJson(Map<String, dynamic> json) => VendorPaymentModel(
        id:                 JsonUtils.asString(json['id']),
        paymentNumber:      JsonUtils.asString(json['paymentNumber']),
        vendorId:           JsonUtils.asString(json['vendorId']),
        vendorName:         JsonUtils.asString(json['vendorName']),
        paymentAccountId:   JsonUtils.asString(json['paymentAccountId']),
        paymentAccountName: JsonUtils.asString(json['paymentAccountName']),
        paymentDate:        DateTime.parse(json['paymentDate']),
        amount:             JsonUtils.asDouble(json['amount']),
        paymentMethod:      JsonUtils.asString(json['paymentMethod']),
        memo:               JsonUtils.asString(json['memo']),
        status:             JsonUtils.asInt(json['status']),
        lines:              JsonUtils.asList(json['lines'], (l) => VendorPaymentLineModel.fromJson(l)),
      );
}

class VendorPaymentLineModel {
  const VendorPaymentLineModel({
    required this.id,
    required this.purchaseBillId,
    required this.billNumber,
    required this.amount,
  });

  final String id;
  final String purchaseBillId;
  final String billNumber;
  final double amount;

  factory VendorPaymentLineModel.fromJson(Map<String, dynamic> json) => VendorPaymentLineModel(
        id:             JsonUtils.asString(json['id']),
        purchaseBillId: JsonUtils.asString(json['purchaseBillId']),
        billNumber:     JsonUtils.asString(json['billNumber']),
        amount:         JsonUtils.asDouble(json['amount']),
      );
}
