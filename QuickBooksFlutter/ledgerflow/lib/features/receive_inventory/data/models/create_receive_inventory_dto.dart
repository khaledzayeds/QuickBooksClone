import 'receive_inventory_status.dart';

class CreateReceiveInventoryDto {
  const CreateReceiveInventoryDto({
    required this.purchaseOrderId,
    required this.receiptDate,
    required this.lines,
    this.notes,
    this.saveMode = ReceiveInventorySaveMode.saveAndPost,
  });

  final String purchaseOrderId;
  final DateTime receiptDate;
  final List<CreateReceiveInventoryLineDto> lines;
  final String? notes;
  final ReceiveInventorySaveMode saveMode;

  Map<String, dynamic> toJson() => {
        'purchaseOrderId': purchaseOrderId,
        'receiptDate': receiptDate.toIso8601String(),
        'saveMode': saveMode.value,
        if (notes != null) 'notes': notes,
        'lines': lines.map((line) => line.toJson()).toList(),
      };
}

class CreateReceiveInventoryLineDto {
  const CreateReceiveInventoryLineDto({
    required this.purchaseOrderLineId,
    required this.itemId,
    required this.quantityReceived,
  });

  final String purchaseOrderLineId;
  final String itemId;
  final double quantityReceived;

  Map<String, dynamic> toJson() => {
        'purchaseOrderLineId': purchaseOrderLineId,
        'itemId': itemId,
        'quantityReceived': quantityReceived,
      };
}
