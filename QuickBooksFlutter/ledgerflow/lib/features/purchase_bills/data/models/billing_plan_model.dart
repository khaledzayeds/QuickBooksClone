// billing_plan_model.dart
// Aligned with backend InventoryReceiptBillingPlanDto.

import '../../../../core/utils/json_utils.dart';

class BillingPlanModel {
  const BillingPlanModel({
    required this.inventoryReceiptId,
    required this.receiptNumber,
    required this.vendorId,
    required this.vendorName,
    required this.purchaseOrderId,
    required this.purchaseOrderNumber,
    required this.totalRemainingQuantity,
    required this.lines,
  });

  final String inventoryReceiptId;
  final String receiptNumber;
  final String vendorId;
  final String? vendorName;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final double totalRemainingQuantity;
  final List<BillingPlanLineModel> lines;

  factory BillingPlanModel.fromJson(Map<String, dynamic> json) => BillingPlanModel(
        inventoryReceiptId:     JsonUtils.asString(json['inventoryReceiptId']),
        receiptNumber:          JsonUtils.asString(json['receiptNumber']),
        vendorId:               JsonUtils.asString(json['vendorId']),
        vendorName:             JsonUtils.asString(json['vendorName']),
        purchaseOrderId:        JsonUtils.asString(json['purchaseOrderId']),
        purchaseOrderNumber:    JsonUtils.asString(json['purchaseOrderNumber']),
        totalRemainingQuantity: JsonUtils.asDouble(json['totalRemainingQuantity']),
        lines: JsonUtils.asList(json['lines'], (l) => BillingPlanLineModel.fromJson(l)),
      );
}

class BillingPlanLineModel {
  const BillingPlanLineModel({
    required this.inventoryReceiptLineId,
    required this.itemId,
    required this.purchaseOrderLineId,
    required this.description,
    required this.receivedQuantity,
    required this.billedQuantity,
    required this.remainingQuantity,
    required this.suggestedBillQuantity,
    required this.unitCost,
  });

  final String inventoryReceiptLineId;
  final String itemId;
  final String? purchaseOrderLineId;
  final String description;
  final double receivedQuantity;
  final double billedQuantity;
  final double remainingQuantity;
  final double suggestedBillQuantity;
  final double unitCost;

  factory BillingPlanLineModel.fromJson(Map<String, dynamic> json) => BillingPlanLineModel(
        inventoryReceiptLineId: JsonUtils.asString(json['inventoryReceiptLineId']),
        itemId:                 JsonUtils.asString(json['itemId']),
        purchaseOrderLineId:    JsonUtils.asString(json['purchaseOrderLineId']),
        description:            JsonUtils.asString(json['description']),
        receivedQuantity:       JsonUtils.asDouble(json['receivedQuantity']),
        billedQuantity:         JsonUtils.asDouble(json['billedQuantity']),
        remainingQuantity:      JsonUtils.asDouble(json['remainingQuantity']),
        suggestedBillQuantity:  JsonUtils.asDouble(json['suggestedBillQuantity']),
        unitCost:               JsonUtils.asDouble(json['unitCost']),
      );
}
