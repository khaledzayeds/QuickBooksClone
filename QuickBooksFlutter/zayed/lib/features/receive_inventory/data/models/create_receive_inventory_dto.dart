// create_receive_inventory_dto.dart
// Aligned with backend CreateInventoryReceiptRequest and CreateInventoryReceiptLineRequest.

class CreateReceiveInventoryDto {
  const CreateReceiveInventoryDto({
    required this.vendorId,
    required this.receiptDate,
    required this.lines,
    this.purchaseOrderId,
    this.saveMode = 2, // Backend: 1=Draft, 2=SaveAndPost
  });

  final String  vendorId;
  final DateTime receiptDate;
  final List<CreateReceiveInventoryLineDto> lines;
  final String? purchaseOrderId;
  final int     saveMode;

  Map<String, dynamic> toJson() => {
    'vendorId':     vendorId,
    'receiptDate':  _dateOnly(receiptDate),
    'saveMode':     saveMode,
    if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreateReceiveInventoryLineDto {
  const CreateReceiveInventoryLineDto({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
    this.description,
    this.purchaseOrderLineId,
  });

  final String  itemId;
  final double  quantity;
  final double  unitCost;
  final String? description;
  final String? purchaseOrderLineId;

  Map<String, dynamic> toJson() => {
    'itemId':    itemId,
    'quantity':  quantity,
    'unitCost':  unitCost,
    if (description != null)          'description':          description,
    if (purchaseOrderLineId != null)  'purchaseOrderLineId':  purchaseOrderLineId,
  };
}
