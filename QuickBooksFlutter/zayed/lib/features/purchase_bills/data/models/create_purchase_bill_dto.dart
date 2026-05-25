// create_purchase_bill_dto.dart

class CreatePurchaseBillDto {
  const CreatePurchaseBillDto({
    required this.vendorId,
    this.inventoryReceiptId,
    required this.billDate,
    required this.dueDate,
    this.saveMode = 2, // 1 Draft, 2 SaveAndPost
    this.memo,
    required this.lines,
  });

  final String vendorId;
  final String? inventoryReceiptId;
  final DateTime billDate;
  final DateTime dueDate;
  final int saveMode;
  final String? memo;
  final List<CreatePurchaseBillLineDto> lines;

    Map<String, dynamic> toJson() => {
        'vendorId':           vendorId,
        'inventoryReceiptId': inventoryReceiptId,
        'billDate':           billDate.toIso8601String().split('T')[0],
        'dueDate':            dueDate.toIso8601String().split('T')[0],
        'saveMode':           saveMode,
        'memo':               memo,
        'lines':              lines.map((l) => l.toJson()).toList(),
      };
}

class CreatePurchaseBillLineDto {
  const CreatePurchaseBillLineDto({
    required this.itemId,
    this.inventoryReceiptLineId,
    required this.description,
    required this.quantity,
    required this.unitCost,
  });

  final String itemId;
  final String? inventoryReceiptLineId;
  final String description;
  final double quantity;
  final double unitCost;

  Map<String, dynamic> toJson() => {
        'itemId':                 itemId,
        'inventoryReceiptLineId': inventoryReceiptLineId,
        'description':            description,
        'quantity':               quantity,
        'unitCost':               unitCost,
      };
}
