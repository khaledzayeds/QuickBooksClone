class ReceiveInventoryLineModel {
  const ReceiveInventoryLineModel({
    required this.id,
    required this.purchaseOrderLineId,
    required this.itemId,
    required this.itemName,
    required this.quantityReceived,
    this.unitCost,
  });

  final String id;
  final String purchaseOrderLineId;
  final String itemId;
  final String itemName;
  final double quantityReceived;
  final double? unitCost;

  factory ReceiveInventoryLineModel.fromJson(Map<String, dynamic> json) {
    return ReceiveInventoryLineModel(
      id: json['id'].toString(),
      purchaseOrderLineId: json['purchaseOrderLineId'].toString(),
      itemId: json['itemId'].toString(),
      itemName: json['itemName'] as String? ?? '',
      quantityReceived: (json['quantityReceived'] as num?)?.toDouble() ?? 0,
      unitCost: (json['unitCost'] as num?)?.toDouble(),
    );
  }
}
