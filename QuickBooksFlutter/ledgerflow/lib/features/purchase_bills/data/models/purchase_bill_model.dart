// purchase_bill_model.dart

import '../../../../core/utils/json_utils.dart';

class PurchaseBillModel {
  const PurchaseBillModel({
    required this.id,
    required this.billNumber,
    required this.vendorId,
    required this.vendorName,
    required this.billDate,
    required this.dueDate,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.balanceDue,
    this.inventoryReceiptId,
    this.memo,
    required this.lines,
  });

  final String id;
  final String billNumber;
  final String vendorId;
  final String vendorName;
  final DateTime billDate;
  final DateTime dueDate;
  final int status; // 1 Draft, 2 Posted, 3 Void, 4 PartiallyPaid, 5 Paid
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final String? inventoryReceiptId;
  final String? memo;
  final List<PurchaseBillLineModel> lines;

  bool get isDraft => status == 1;
  bool get isPosted => status == 2;
  bool get isVoid => status == 3;
  bool get isPartiallyPaid => status == 4;
  bool get isPaid => status == 5 || balanceDue <= 0;
  bool get canVoid => !isVoid && amountPaid <= 0;
  bool get canPay => !isVoid && balanceDue > 0;

  factory PurchaseBillModel.fromJson(Map<String, dynamic> json) => PurchaseBillModel(
        id: JsonUtils.asString(json['id']),
        billNumber: JsonUtils.asString(json['billNumber']),
        vendorId: JsonUtils.asString(json['vendorId']),
        vendorName: JsonUtils.asString(json['vendorName']),
        billDate: _parseDate(json['billDate']),
        dueDate: _parseDate(json['dueDate']),
        status: JsonUtils.asInt(json['status']),
        subtotal: JsonUtils.asDouble(json['subtotal']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        amountPaid: JsonUtils.asDouble(json['amountPaid']),
        balanceDue: JsonUtils.asDouble(json['balanceDue']),
        inventoryReceiptId: JsonUtils.asNullableString(json['inventoryReceiptId']),
        memo: JsonUtils.asNullableString(json['memo']),
        lines: JsonUtils.asList(json['lines'], (l) => PurchaseBillLineModel.fromJson(l)),
      );

  static DateTime _parseDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? DateTime.now();
  }
}

class PurchaseBillLineModel {
  const PurchaseBillLineModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
    this.inventoryReceiptLineId,
  });

  final String id;
  final String itemId;
  final String itemName;
  final String description;
  final double quantity;
  final double unitCost;
  final double lineTotal;
  final String? inventoryReceiptLineId;

  factory PurchaseBillLineModel.fromJson(Map<String, dynamic> json) => PurchaseBillLineModel(
        id: JsonUtils.asString(json['id']),
        itemId: JsonUtils.asString(json['itemId']),
        itemName: JsonUtils.asString(json['itemName']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitCost: JsonUtils.asDouble(json['unitCost']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
        inventoryReceiptLineId: JsonUtils.asNullableString(json['inventoryReceiptLineId']),
      );
}
