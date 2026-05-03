// inventory_adjustment_model.dart

import '../../../../core/utils/json_utils.dart';

class InventoryAdjustmentModel {
  const InventoryAdjustmentModel({
    required this.id,
    required this.adjustmentNumber,
    required this.itemId,
    required this.adjustmentAccountId,
    required this.adjustmentDate,
    required this.quantityChange,
    required this.unitCost,
    required this.totalCost,
    required this.status,
    this.itemName,
    this.adjustmentAccountName,
    this.reason,
    this.postedTransactionId,
    this.postedAt,
  });

  final String id;
  final String adjustmentNumber;
  final String itemId;
  final String? itemName;
  final String adjustmentAccountId;
  final String? adjustmentAccountName;
  final DateTime adjustmentDate;
  final double quantityChange;
  final double unitCost;
  final double totalCost;
  final String? reason;
  final int status;
  final String? postedTransactionId;
  final DateTime? postedAt;

  factory InventoryAdjustmentModel.fromJson(Map<String, dynamic> json) => InventoryAdjustmentModel(
        id: JsonUtils.asString(json['id']),
        adjustmentNumber: JsonUtils.asString(json['adjustmentNumber']),
        itemId: JsonUtils.asString(json['itemId']),
        itemName: JsonUtils.asNullableString(json['itemName']),
        adjustmentAccountId: JsonUtils.asString(json['adjustmentAccountId']),
        adjustmentAccountName: JsonUtils.asNullableString(json['adjustmentAccountName']),
        adjustmentDate: _parseDate(json['adjustmentDate']),
        quantityChange: JsonUtils.asDouble(json['quantityChange']),
        unitCost: JsonUtils.asDouble(json['unitCost']),
        totalCost: JsonUtils.asDouble(json['totalCost']),
        reason: JsonUtils.asNullableString(json['reason']),
        status: JsonUtils.asInt(json['status']),
        postedTransactionId: JsonUtils.asNullableString(json['postedTransactionId']),
        postedAt: _parseNullableDate(json['postedAt']),
      );

  bool get isIncrease => quantityChange > 0;

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class CreateInventoryAdjustmentDto {
  const CreateInventoryAdjustmentDto({
    required this.itemId,
    required this.adjustmentAccountId,
    required this.adjustmentDate,
    required this.quantityChange,
    this.unitCost,
    this.reason,
  });

  final String itemId;
  final String adjustmentAccountId;
  final DateTime adjustmentDate;
  final double quantityChange;
  final double? unitCost;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'adjustmentAccountId': adjustmentAccountId,
        'adjustmentDate': _dateOnly(adjustmentDate),
        'quantityChange': quantityChange,
        if (unitCost != null && unitCost! > 0) 'unitCost': unitCost,
        if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
