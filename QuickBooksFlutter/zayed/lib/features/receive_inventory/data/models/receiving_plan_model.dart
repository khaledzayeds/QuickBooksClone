// receiving_plan_model.dart
// Aligned with backend PurchaseOrderReceivingPlanDto.

class ReceivingPlanModel {
  const ReceivingPlanModel({
    required this.purchaseOrderId,
    required this.orderNumber,
    required this.vendorId,
    required this.vendorName,
    required this.totalRemainingQuantity,
    required this.lines,
  });

  final String purchaseOrderId;
  final String orderNumber;
  final String vendorId;
  final String? vendorName;
  final double totalRemainingQuantity;
  final List<ReceivingPlanLineModel> lines;

  factory ReceivingPlanModel.fromJson(Map<String, dynamic> json) => ReceivingPlanModel(
    purchaseOrderId:        json['purchaseOrderId'] ?? '',
    orderNumber:            json['orderNumber']     ?? '',
    vendorId:               json['vendorId']        ?? '',
    vendorName:             json['vendorName'],
    totalRemainingQuantity: (json['totalRemainingQuantity'] as num?)?.toDouble() ?? 0,
    lines: (json['lines'] as List? ?? [])
        .map((l) => ReceivingPlanLineModel.fromJson(l))
        .toList(),
  );
}

class ReceivingPlanLineModel {
  const ReceivingPlanLineModel({
    required this.purchaseOrderLineId,
    required this.itemId,
    required this.description,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.remainingQuantity,
    required this.suggestedReceiveQuantity,
    required this.unitCost,
  });

  final String purchaseOrderLineId;
  final String itemId;
  final String description;
  final double orderedQuantity;
  final double receivedQuantity;
  final double remainingQuantity;
  final double suggestedReceiveQuantity;
  final double unitCost;

  factory ReceivingPlanLineModel.fromJson(Map<String, dynamic> json) => ReceivingPlanLineModel(
    purchaseOrderLineId:      json['purchaseOrderLineId']      ?? '',
    itemId:                   json['itemId']                   ?? '',
    description:              json['description']              ?? '',
    orderedQuantity:          (json['orderedQuantity']         as num?)?.toDouble() ?? 0,
    receivedQuantity:         (json['receivedQuantity']        as num?)?.toDouble() ?? 0,
    remainingQuantity:        (json['remainingQuantity']       as num?)?.toDouble() ?? 0,
    suggestedReceiveQuantity: (json['suggestedReceiveQuantity'] as num?)?.toDouble() ?? 0,
    unitCost:                 (json['unitCost']                as num?)?.toDouble() ?? 0,
  );
}
