// purchase_return_model.dart

import '../../../../core/utils/json_utils.dart';

class PurchaseReturnModel {
  const PurchaseReturnModel({
    required this.id,
    required this.returnNumber,
    required this.purchaseBillId,
    required this.vendorId,
    required this.returnDate,
    required this.status,
    required this.totalAmount,
    required this.lines,
    this.billNumber,
    this.vendorName,
    this.postedTransactionId,
    this.postedAt,
    this.reversalTransactionId,
    this.voidedAt,
  });

  final String id;
  final String returnNumber;
  final String purchaseBillId;
  final String? billNumber;
  final String vendorId;
  final String? vendorName;
  final DateTime returnDate;
  final int status;
  final double totalAmount;
  final String? postedTransactionId;
  final DateTime? postedAt;
  final String? reversalTransactionId;
  final DateTime? voidedAt;
  final List<PurchaseReturnLineModel> lines;

  factory PurchaseReturnModel.fromJson(Map<String, dynamic> json) => PurchaseReturnModel(
        id: JsonUtils.asString(json['id']),
        returnNumber: JsonUtils.asString(json['returnNumber']),
        purchaseBillId: JsonUtils.asString(json['purchaseBillId']),
        billNumber: JsonUtils.asNullableString(json['billNumber']),
        vendorId: JsonUtils.asString(json['vendorId']),
        vendorName: JsonUtils.asNullableString(json['vendorName']),
        returnDate: _parseDate(json['returnDate']),
        status: JsonUtils.asInt(json['status']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        postedTransactionId: JsonUtils.asNullableString(json['postedTransactionId']),
        postedAt: _parseNullableDate(json['postedAt']),
        reversalTransactionId: JsonUtils.asNullableString(json['reversalTransactionId']),
        voidedAt: _parseNullableDate(json['voidedAt']),
        lines: JsonUtils.asList(json['lines'], (line) => PurchaseReturnLineModel.fromJson(line)),
      );

  bool get isVoid => voidedAt != null;

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class PurchaseReturnLineModel {
  const PurchaseReturnLineModel({
    required this.id,
    required this.purchaseBillLineId,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
  });

  final String id;
  final String purchaseBillLineId;
  final String itemId;
  final String description;
  final double quantity;
  final double unitCost;
  final double lineTotal;

  factory PurchaseReturnLineModel.fromJson(Map<String, dynamic> json) => PurchaseReturnLineModel(
        id: JsonUtils.asString(json['id']),
        purchaseBillLineId: JsonUtils.asString(json['purchaseBillLineId']),
        itemId: JsonUtils.asString(json['itemId']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitCost: JsonUtils.asDouble(json['unitCost']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
      );
}

class CreatePurchaseReturnDto {
  const CreatePurchaseReturnDto({
    required this.purchaseBillId,
    required this.returnDate,
    required this.lines,
  });

  final String purchaseBillId;
  final DateTime returnDate;
  final List<CreatePurchaseReturnLineDto> lines;

  Map<String, dynamic> toJson() => {
        'purchaseBillId': purchaseBillId,
        'returnDate': _dateOnly(returnDate),
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreatePurchaseReturnLineDto {
  const CreatePurchaseReturnLineDto({
    required this.purchaseBillLineId,
    required this.quantity,
    this.unitCost,
  });

  final String purchaseBillLineId;
  final double quantity;
  final double? unitCost;

  Map<String, dynamic> toJson() => {
        'purchaseBillLineId': purchaseBillLineId,
        'quantity': quantity,
        if (unitCost != null && unitCost! > 0) 'unitCost': unitCost,
      };
}
