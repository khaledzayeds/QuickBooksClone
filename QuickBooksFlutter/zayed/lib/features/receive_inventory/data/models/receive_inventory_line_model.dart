// receive_inventory_line_model.dart
// Aligned with backend InventoryReceiptLineDto.

class ReceiveInventoryLineModel {
  const ReceiveInventoryLineModel({
    required this.id,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
    this.purchaseOrderLineId,
  });

  final String  id;
  final String  itemId;
  final String  description;
  final double  quantity;
  final double  unitCost;
  final double  lineTotal;
  final String? purchaseOrderLineId;

  /// Convenience getter for display (keeps existing code working)
  String get itemName => description;
  double get quantityReceived => quantity;

  factory ReceiveInventoryLineModel.fromJson(Map<String, dynamic> json) {
    return ReceiveInventoryLineModel(
      id:                   json['id']?.toString() ?? '',
      itemId:               json['itemId']?.toString() ?? '',
      description:          json['description']?.toString() ?? '',
      quantity:             (json['quantity'] as num?)?.toDouble() ?? 0,
      unitCost:             (json['unitCost'] as num?)?.toDouble() ?? 0,
      lineTotal:            (json['lineTotal'] as num?)?.toDouble() ?? 0,
      purchaseOrderLineId:  json['purchaseOrderLineId']?.toString(),
    );
  }
}
